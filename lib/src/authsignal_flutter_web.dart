import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'authsignal_flutter_platform.dart';
import 'types.dart';

@JS('Reflect.construct')
external JSObject _jsConstruct(JSFunction target, JSArray args);

@JS('Reflect.has')
external bool _jsHas(JSObject target, JSString propertyKey);

@JS('Reflect.get')
external JSAny? _jsGet(JSObject target, JSString propertyKey);

@JS('Reflect.apply')
external JSAny? _jsApply(JSFunction target, JSObject thisArg, JSArray args);

class AuthsignalFlutterWeb extends AuthsignalFlutterPlatform {
  AuthsignalFlutterWeb();

  static void registerWith(Registrar registrar) {
    AuthsignalFlutterPlatform.instance = AuthsignalFlutterWeb();
  }

  static const String _scriptElementId = 'authsignal-browser-sdk';

  static const String _browserSdkVersion = '1.16.0';
  static const String _browserModuleUrl =
      'https://cdn.jsdelivr.net/npm/@authsignal/browser@$_browserSdkVersion/+esm';

  static const int _scriptLoadTimeoutMs = 10000;
  static const int _scriptLoadCheckIntervalMs = 100;

  static const String _deviceIdStorageKey = '@as_device_id';
  static const String _passkeyCredentialIdStorageKey =
      '@as_passkey_credential_id';

  JSObject? _client;
  String? _tenantId;
  String? _baseUrl;
  String? _customDeviceId;
  String? _pendingToken;
  String? _sessionToken;
  Future<void>? _scriptLoader;

  @override
  Future<void> initialize({
    required String tenantId,
    required String baseUrl,
    String? deviceId,
  }) async {
    if (_isInitializedFor(tenantId, baseUrl)) {
      return;
    }

    try {
      await _ensureBrowserSdkLoaded();
    } catch (e) {
      throw StateError('Failed to load Authsignal browser SDK from CDN. '
          'Please check your internet connection and that the CDN is accessible. '
          'Error: $e');
    }

    final constructor = _getWindowProperty('Authsignal');
    if (constructor == null) {
      throw StateError(
          'Authsignal browser SDK loaded but constructor is not available. '
          'This may indicate a version mismatch or CDN issue.');
    }

    final options = <String, dynamic>{
      'tenantId': tenantId,
      'baseUrl': baseUrl,
      if (deviceId != null) 'deviceId': deviceId,
    }.jsify()!;

    try {
      _client = _jsConstruct(constructor as JSFunction, [options].toJS);
      _tenantId = tenantId;
      _baseUrl = baseUrl;
      _customDeviceId = deviceId;

      final pendingToken = _pendingToken;
      if (pendingToken != null) {
        await setToken(pendingToken);
        _pendingToken = null;
      }
    } catch (e) {
      throw StateError('Failed to initialize Authsignal client. '
          'Please verify your tenant ID and base URL are correct. '
          'Error: $e');
    }
  }

  @override
  Future<void> setToken(String token) async {
    if (_client == null) {
      _pendingToken = token;
      _sessionToken = token;
      return;
    }

    try {
      _callMethod(_client!, 'setToken', [token.toJS]);
      _sessionToken = token;
    } catch (e) {
      throw StateError('Failed to set authentication token: $e');
    }
  }

  @override
  Future<AuthsignalResponse<EnrollResponse>> emailEnroll(String email) {
    if (email.trim().isEmpty) {
      return Future.value(AuthsignalResponse.withError(
        error: 'Email address is required',
        errorCode: 'invalid_input',
      ));
    }

    return _invokeEmailMethod(
      'enroll',
      [
        <String, dynamic>{'email': email}.jsify()!
      ],
      (map) => EnrollResponse.fromMap(map),
    );
  }

  @override
  Future<AuthsignalResponse<ChallengeResponse>> emailChallenge() {
    return _invokeEmailMethod(
      'challenge',
      const [],
      (map) => ChallengeResponse.fromMap(map),
    );
  }

  @override
  Future<AuthsignalResponse<VerifyResponse>> emailVerify(String code) {
    if (code.trim().isEmpty) {
      return Future.value(AuthsignalResponse.withError(
        error: 'Verification code is required',
        errorCode: 'invalid_input',
      ));
    }

    return _invokeEmailMethod(
      'verify',
      [
        <String, dynamic>{'code': code}.jsify()!
      ],
      (map) => VerifyResponse.fromMap(map),
    );
  }

  @override
  Future<AuthsignalResponse<SignUpResponse>> passkeySignUp({
    String? token,
    String? username,
    String? displayName,
    bool useAutoRegister = false,
    bool ignorePasskeyAlreadyExistsError = false,
  }) {
    final client = _client;
    if (client == null) {
      return _clientNotInitializedResponse<SignUpResponse>();
    }

    final effectiveToken = (token ?? _sessionToken)?.trim();
    if (effectiveToken == null || effectiveToken.isEmpty) {
      return Future.value(AuthsignalResponse.withError(
        error:
            'Passkey sign-up requires a token. Call Authsignal.setToken or provide a token argument.',
        errorCode: ErrorCode.tokenRequired.value,
      ));
    }

    final payload = <String, dynamic>{
      'token': effectiveToken,
      if (username != null) 'username': username,
      if (displayName != null) 'displayName': displayName,
    };
    if (useAutoRegister) {
      payload['useAutoRegister'] = true;
    }

    return _invokePasskeyMethod(
      client,
      'signUp',
      payload,
      (map) => SignUpResponse.fromMap(map),
      onData: (map) => _storePasskeyCredentialIdFromData(map, username),
      onErrorHandler: ignorePasskeyAlreadyExistsError
          ? _ignoreAlreadyExistsErrorHandler<SignUpResponse>
          : null,
    );
  }

  static AuthsignalResponse<T>? _ignoreAlreadyExistsErrorHandler<T>(
    String? errorName,
    String? errorCode,
  ) {
    if (errorName == 'InvalidStateError' ||
        errorCode == 'matched_excluded_credential' ||
        errorCode == 'InvalidStateError') {
      return AuthsignalResponse<T>(data: null);
    }
    return null;
  }

  @override
  Future<AuthsignalResponse<SignInResponse>> passkeySignIn({
    String? action,
    String? token,
    bool autofill = false,
    bool preferImmediatelyAvailableCredentials = true,
  }) {
    final client = _client;
    if (client == null) {
      return _clientNotInitializedResponse<SignInResponse>();
    }

    final payload = <String, dynamic>{
      if (action != null) 'action': action,
      if (token != null) 'token': token,
      if (autofill) 'autofill': true,
      'preferImmediatelyAvailableCredentials':
          preferImmediatelyAvailableCredentials,
    };

    return _invokePasskeyMethod(
      client,
      'signIn',
      payload,
      (map) => SignInResponse.fromMap(map),
      onData: _storeVerifiedPasskeyCredentialIdFromData,
    );
  }

  @override
  Future<void> passkeyCancel() async {
    final client = _client;
    if (client == null) {
      return;
    }

    final passkeyApi = _getProperty(client, 'passkey') as JSObject?;
    if (passkeyApi == null || !_hasProperty(passkeyApi, 'cancel')) {
      return;
    }

    try {
      _callMethod(passkeyApi, 'cancel', const []);
    } catch (_) {}
  }

  @override
  Future<String?> getDeviceId() async {
    if (_customDeviceId != null) {
      return _customDeviceId;
    }

    final client = _client;
    if (client != null && _hasProperty(client, 'getDeviceId')) {
      try {
        final jsResult = _callMethod(client, 'getDeviceId', const []);
        if (jsResult != null) {
          final result = await (jsResult as JSPromise).toDart;
          final dartResult = result?.dartify();
          if (dartResult is String && dartResult.isNotEmpty) {
            return dartResult;
          }
        }
      } catch (_) {}
    }

    final storage = web.window.localStorage;
    final existing = storage.getItem(_deviceIdStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _generateUuid();
    storage.setItem(_deviceIdStorageKey, generated);
    return generated;
  }

  String _generateUuid() {
    final crypto = _getWindowProperty('crypto') as JSObject?;
    if (crypto != null && _hasProperty(crypto, 'randomUUID')) {
      try {
        final value = _callMethod(crypto, 'randomUUID', const []);
        final dartValue = value?.dartify();
        if (dartValue is String && dartValue.isNotEmpty) {
          return dartValue;
        }
      } catch (_) {}
    }

    final rand = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return 'as-$rand-${identityHashCode(this).toRadixString(16)}';
  }

  @override
  Future<AuthsignalResponse<bool>> passkeyShouldPromptToCreatePasskey({
    String? username,
  }) async {
    final client = _client;
    if (client == null) {
      return AuthsignalResponse(data: false);
    }

    final passkeyApi = _getProperty(client, 'passkey') as JSObject?;
    if (passkeyApi != null &&
        _hasProperty(passkeyApi, 'shouldPromptToCreatePasskey')) {
      try {
        final payload = <String, dynamic>{
          if (username != null) 'username': username,
        };
        final args = payload.isEmpty ? <JSAny>[] : <JSAny>[payload.jsify()!];
        final jsResult =
            _callMethod(passkeyApi, 'shouldPromptToCreatePasskey', args);
        if (jsResult != null) {
          final result = await (jsResult as JSPromise).toDart;
          final dartResult = result?.dartify();
          if (dartResult is bool) {
            return AuthsignalResponse(data: dartResult);
          }
          if (dartResult is Map) {
            final map = _toStringKeyedMap(dartResult);
            if (map['data'] is bool) {
              return AuthsignalResponse(data: map['data'] as bool);
            }
          }
        }
      } catch (error) {
        return _responseFromJsError(error);
      }
    }

    if (!_isWebAuthnAvailable()) {
      return AuthsignalResponse(data: false);
    }

    final credentialId = _getStoredPasskeyCredentialId(username);
    if (credentialId == null) {
      return AuthsignalResponse(data: true);
    }

    if (passkeyApi == null) {
      return AuthsignalResponse(data: false);
    }

    final api = _getProperty(passkeyApi, 'api') as JSObject?;
    if (api == null || !_hasProperty(api, 'getPasskeyAuthenticator')) {
      return AuthsignalResponse(data: false);
    }

    try {
      final jsResult = _callMethod(
        api,
        'getPasskeyAuthenticator',
        [
          <String, dynamic>{
            'credentialIds': [credentialId],
          }.jsify()!,
        ],
      );
      if (jsResult == null) {
        return AuthsignalResponse(data: false);
      }

      final result = await (jsResult as JSPromise).toDart;
      final dartResult = result?.dartify();
      if (dartResult is Map) {
        final map = _toStringKeyedMap(dartResult);
        final errorCodeValue = map['errorCode'];
        final errorValue = map['errorDescription'] ?? map['error'];
        final errorCode = errorCodeValue is String ? errorCodeValue : null;
        final error = errorValue is String ? errorValue : null;

        if (errorCode == ErrorCode.invalidCredential.value) {
          _removeStoredPasskeyCredentialId(username);
          return AuthsignalResponse(data: true);
        }

        if (error != null || errorCode != null) {
          return AuthsignalResponse.withError(
            error: error,
            errorCode: errorCode,
          );
        }
      }

      return AuthsignalResponse(data: false);
    } catch (error) {
      return _responseFromJsError(error);
    }
  }

  @override
  Future<bool> passkeyIsSupported() async {
    return _isWebAuthnAvailable();
  }

  @override
  Future<AuthsignalResponse<bool>> passkeyIsAvailable() async {
    final client = _client;

    if (client == null) {
      return AuthsignalResponse(data: _isWebAuthnAvailable());
    }

    final passkeyApi = _getProperty(client, 'passkey') as JSObject?;
    if (passkeyApi != null && _hasProperty(passkeyApi, 'isAvailable')) {
      try {
        final jsPromise = _callMethod(passkeyApi, 'isAvailable', const []);
        if (jsPromise != null) {
          final result = await (jsPromise as JSPromise).toDart;
          if (result != null) {
            final dartResult = result.dartify();
            if (dartResult is bool) {
              return AuthsignalResponse(data: dartResult);
            }
          }
        }
      } catch (_) {}
    }

    return AuthsignalResponse(data: _isWebAuthnAvailable());
  }

  @override
  Future<AuthsignalResponse<EnrollResponse>> smsEnroll(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) {
      return Future.value(AuthsignalResponse.withError(
        error: 'Phone number is required',
        errorCode: 'invalid_input',
      ));
    }

    return _invokeSmsMethod(
      'enroll',
      [
        <String, dynamic>{'phoneNumber': phoneNumber}.jsify()!
      ],
      (map) => EnrollResponse.fromMap(map),
    );
  }

  @override
  Future<AuthsignalResponse<ChallengeResponse>> smsChallenge() {
    return _invokeSmsMethod(
      'challenge',
      const [],
      (map) => ChallengeResponse.fromMap(map),
    );
  }

  @override
  Future<AuthsignalResponse<VerifyResponse>> smsVerify(String code) {
    if (code.trim().isEmpty) {
      return Future.value(AuthsignalResponse.withError(
        error: 'Verification code is required',
        errorCode: 'invalid_input',
      ));
    }

    return _invokeSmsMethod(
      'verify',
      [
        <String, dynamic>{'code': code}.jsify()!
      ],
      (map) => VerifyResponse.fromMap(map),
    );
  }

  Future<AuthsignalResponse<T>> _invokeSmsMethod<T>(
    String method,
    List<JSAny> arguments,
    T Function(Map<String, dynamic> data) parser,
  ) async {
    final client = _client;
    if (client == null) {
      return _clientNotInitializedResponse<T>();
    }

    final smsApi = _getProperty(client, 'sms');
    if (smsApi == null) {
      return AuthsignalResponse.withError(
        error: 'SMS API is not available in the browser SDK. '
            'This may indicate a version incompatibility.',
        errorCode: 'api_unavailable',
      );
    }

    try {
      final jsResult = _callMethod(smsApi as JSObject, method, arguments);
      if (jsResult == null) {
        return AuthsignalResponse(data: null);
      }
      final result = await (jsResult as JSPromise).toDart;
      return _mapResponse(result, parser);
    } catch (error) {
      return _responseFromJsError(error);
    }
  }

  @override
  Future<AuthsignalResponse<EnrollTotpResponse>> totpEnroll() {
    return _invokeTotpMethod(
      'enroll',
      const [],
      (map) => EnrollTotpResponse.fromMap(map),
    );
  }

  @override
  Future<AuthsignalResponse<VerifyResponse>> totpVerify(String code) {
    if (code.trim().isEmpty) {
      return Future.value(AuthsignalResponse.withError(
        error: 'Verification code is required',
        errorCode: 'invalid_input',
      ));
    }

    return _invokeTotpMethod(
      'verify',
      [
        <String, dynamic>{'code': code}.jsify()!
      ],
      (map) => VerifyResponse.fromMap(map),
    );
  }

  Future<AuthsignalResponse<T>> _invokeTotpMethod<T>(
    String method,
    List<JSAny> arguments,
    T Function(Map<String, dynamic> data) parser,
  ) async {
    final client = _client;
    if (client == null) {
      return _clientNotInitializedResponse<T>();
    }

    final totpApi = _getProperty(client, 'totp');
    if (totpApi == null) {
      return AuthsignalResponse.withError(
        error: 'TOTP API is not available in the browser SDK. '
            'This may indicate a version incompatibility.',
        errorCode: 'api_unavailable',
      );
    }

    try {
      final jsResult = _callMethod(totpApi as JSObject, method, arguments);
      if (jsResult == null) {
        return AuthsignalResponse(data: null);
      }
      final result = await (jsResult as JSPromise).toDart;
      return _mapResponse(result, parser);
    } catch (error) {
      return _responseFromJsError(error);
    }
  }

  @override
  Future<AuthsignalResponse<ChallengeResponse>> whatsappChallenge() {
    return _invokeWhatsappMethod(
      'challenge',
      const [],
      (map) => ChallengeResponse.fromMap(map),
    );
  }

  @override
  Future<AuthsignalResponse<VerifyResponse>> whatsappVerify(String code) {
    if (code.trim().isEmpty) {
      return Future.value(AuthsignalResponse.withError(
        error: 'Verification code is required',
        errorCode: 'invalid_input',
      ));
    }

    return _invokeWhatsappMethod(
      'verify',
      [
        <String, dynamic>{'code': code}.jsify()!
      ],
      (map) => VerifyResponse.fromMap(map),
    );
  }

  Future<AuthsignalResponse<T>> _invokeWhatsappMethod<T>(
    String method,
    List<JSAny> arguments,
    T Function(Map<String, dynamic> data) parser,
  ) async {
    final client = _client;
    if (client == null) {
      return _clientNotInitializedResponse<T>();
    }

    final whatsappApi = _getProperty(client, 'whatsapp');
    if (whatsappApi == null) {
      return AuthsignalResponse.withError(
        error: 'WhatsApp API is not available in the browser SDK. '
            'This may indicate a version incompatibility.',
        errorCode: 'api_unavailable',
      );
    }

    try {
      final jsResult = _callMethod(whatsappApi as JSObject, method, arguments);
      if (jsResult == null) {
        return AuthsignalResponse(data: null);
      }
      final result = await (jsResult as JSPromise).toDart;
      return _mapResponse(result, parser);
    } catch (error) {
      return _responseFromJsError(error);
    }
  }

  bool _isInitializedFor(String tenantId, String baseUrl) {
    return _client != null && _tenantId == tenantId && _baseUrl == baseUrl;
  }

  Future<AuthsignalResponse<T>> _invokeEmailMethod<T>(
    String method,
    List<JSAny> arguments,
    T Function(Map<String, dynamic> data) parser,
  ) async {
    final client = _client;
    if (client == null) {
      return _clientNotInitializedResponse<T>();
    }

    final emailApi = _getProperty(client, 'email');
    if (emailApi == null) {
      return AuthsignalResponse.withError(
        error: 'Email API is not available in the browser SDK. '
            'This may indicate a version incompatibility.',
        errorCode: 'api_unavailable',
      );
    }

    try {
      final jsResult = _callMethod(emailApi as JSObject, method, arguments);
      if (jsResult == null) {
        return AuthsignalResponse(data: null);
      }
      final result = await (jsResult as JSPromise).toDart;
      return _mapResponse(result, parser);
    } catch (error) {
      return _responseFromJsError(error);
    }
  }

  Future<AuthsignalResponse<T>> _clientNotInitializedResponse<T>() {
    return Future.value(AuthsignalResponse.withError(
      error: 'Authsignal client not initialized. '
          'Call Authsignal.initialize() before using this method.',
      errorCode: ErrorCode.tokenNotSet.value,
    ));
  }

  Future<AuthsignalResponse<T>> _invokePasskeyMethod<T>(
    JSObject client,
    String method,
    Map<String, dynamic> payload,
    T Function(Map<String, dynamic> data) parser, {
    void Function(Map<String, dynamic> data)? onData,
    AuthsignalResponse<T>? Function(String? errorName, String? errorCode)?
        onErrorHandler,
  }) async {
    final passkeyApi = _getProperty(client, 'passkey');
    if (passkeyApi == null) {
      return AuthsignalResponse.withError(
        error: 'Passkey API is not available in the browser SDK. '
            'This may indicate a version incompatibility.',
        errorCode: 'api_unavailable',
      );
    }

    final args = payload.isEmpty ? <JSAny>[] : <JSAny>[payload.jsify()!];

    try {
      final jsResult = _callMethod(passkeyApi as JSObject, method, args);
      if (jsResult == null) {
        return AuthsignalResponse(data: null);
      }
      final result = await (jsResult as JSPromise).toDart;
      final mapped = _mapResponse(result, parser, onData: onData);
      if (onErrorHandler != null && mapped.error != null) {
        final override = onErrorHandler(null, mapped.errorCode);
        if (override != null) return override;
      }
      return mapped;
    } catch (error) {
      if (onErrorHandler != null) {
        final override =
            onErrorHandler(_jsErrorName(error), _jsErrorCode(error));
        if (override != null) return override;
      }
      return _responseFromJsError(error);
    }
  }

  String? _jsErrorName(Object error) {
    try {
      if (error is JSObject && _hasProperty(error, 'name')) {
        final value = _getProperty(error, 'name')?.dartify();
        if (value is String) return value;
      }
    } catch (_) {}
    return null;
  }

  String? _jsErrorCode(Object error) {
    try {
      if (error is JSObject && _hasProperty(error, 'code')) {
        final value = _getProperty(error, 'code')?.dartify();
        if (value is String) return value;
      }
    } catch (_) {}
    return null;
  }

  AuthsignalResponse<T> _mapResponse<T>(
    JSAny? jsResult,
    T Function(Map<String, dynamic> data) parser, {
    void Function(Map<String, dynamic> data)? onData,
  }) {
    if (jsResult == null) {
      return AuthsignalResponse(data: null);
    }

    final dartified = jsResult.dartify();
    if (dartified is! Map) {
      return AuthsignalResponse(data: null);
    }

    final response = _toStringKeyedMap(dartified);
    final String? error = response['error'] as String?;
    final String? errorCode = response['errorCode'] as String?;

    if (error != null || errorCode != null) {
      return AuthsignalResponse.withError(error: error, errorCode: errorCode);
    }

    final data = response['data'];
    if (data is Map) {
      final map = _toStringKeyedMap(data);
      onData?.call(map);
      return AuthsignalResponse(data: parser(map));
    }

    return AuthsignalResponse(data: null);
  }

  void _storeVerifiedPasskeyCredentialIdFromData(Map<String, dynamic> data) {
    if (data['isVerified'] != true) {
      return;
    }

    _storePasskeyCredentialIdFromData(data, data['username'] as String?);
  }

  void _storePasskeyCredentialIdFromData(
    Map<String, dynamic> data,
    String? username,
  ) {
    final credentialId = _passkeyCredentialIdFromData(data);
    if (credentialId == null || credentialId.isEmpty) {
      return;
    }

    final usernameFromData = _passkeyUsernameFromData(data);
    _storePasskeyCredentialId(credentialId, usernameFromData ?? username);
  }

  String? _passkeyCredentialIdFromData(Map<String, dynamic> data) {
    final registrationResponse =
        _toStringKeyedMap(data['registrationResponse']);
    final registrationRawId = registrationResponse['rawId'] as String?;
    if (registrationRawId != null && registrationRawId.isNotEmpty) {
      return registrationRawId;
    }

    final authenticationResponse =
        _toStringKeyedMap(data['authenticationResponse']);
    final authenticationRawId = authenticationResponse['rawId'] as String?;
    if (authenticationRawId != null && authenticationRawId.isNotEmpty) {
      return authenticationRawId;
    }

    final userAuthenticator = _toStringKeyedMap(data['userAuthenticator']);
    final webauthnCredential =
        _toStringKeyedMap(userAuthenticator['webauthnCredential']);
    final credentialId = webauthnCredential['credentialId'] as String?;
    if (credentialId != null && credentialId.isNotEmpty) {
      return credentialId;
    }

    return null;
  }

  String? _passkeyUsernameFromData(Map<String, dynamic> data) {
    final username = data['username'] as String?;
    if (username != null && username.isNotEmpty) {
      return username;
    }

    final userAuthenticator = _toStringKeyedMap(data['userAuthenticator']);
    final authenticatorUsername = userAuthenticator['username'] as String?;
    if (authenticatorUsername != null && authenticatorUsername.isNotEmpty) {
      return authenticatorUsername;
    }

    return null;
  }

  String? _getStoredPasskeyCredentialId(String? username) {
    final storage = web.window.localStorage;
    final key = _passkeyCredentialIdStorageKeyForUsername(username);
    final credentialId = storage.getItem(key);
    if (credentialId != null && credentialId.isNotEmpty) {
      return credentialId;
    }

    if (username != null && username.isNotEmpty) {
      final defaultCredentialId =
          storage.getItem(_passkeyCredentialIdStorageKey);
      if (defaultCredentialId != null && defaultCredentialId.isNotEmpty) {
        return defaultCredentialId;
      }
    }

    return null;
  }

  void _storePasskeyCredentialId(String credentialId, String? username) {
    final storage = web.window.localStorage;
    storage.setItem(_passkeyCredentialIdStorageKey, credentialId);

    if (username != null && username.isNotEmpty) {
      storage.setItem(
        _passkeyCredentialIdStorageKeyForUsername(username),
        credentialId,
      );
    }
  }

  void _removeStoredPasskeyCredentialId(String? username) {
    final storage = web.window.localStorage;
    storage.removeItem(_passkeyCredentialIdStorageKey);

    if (username != null && username.isNotEmpty) {
      storage.removeItem(_passkeyCredentialIdStorageKeyForUsername(username));
    }
  }

  String _passkeyCredentialIdStorageKeyForUsername(String? username) {
    if (username == null || username.isEmpty) {
      return _passkeyCredentialIdStorageKey;
    }

    return '${_passkeyCredentialIdStorageKey}_$username';
  }

  AuthsignalResponse<T> _responseFromJsError<T>(Object error) {
    String? message;
    String? code;

    try {
      if (error is JSObject) {
        if (_hasProperty(error, 'message')) {
          final value = _getProperty(error, 'message');
          if (value != null) {
            final dartValue = value.dartify();
            if (dartValue is String) {
              message = dartValue;
            }
          }
        }
        if (_hasProperty(error, 'code')) {
          final value = _getProperty(error, 'code');
          if (value != null) {
            final dartValue = value.dartify();
            if (dartValue is String) {
              code = dartValue;
            }
          }
        }
      }
    } catch (_) {}

    message ??= error.toString();

    return AuthsignalResponse.withError(error: message, errorCode: code);
  }

  Map<String, dynamic> _toStringKeyedMap(Object? value) {
    if (value is! Map) {
      return <String, dynamic>{};
    }

    final map = <String, dynamic>{};
    value.forEach((key, dynamic val) {
      map[key.toString()] = val;
    });
    return map;
  }

  Future<void> _ensureBrowserSdkLoaded() async {
    if (_hasBrowserSdk()) {
      return;
    }

    _scriptLoader ??= _injectBrowserSdkScript();
    await _scriptLoader;

    if (!_hasBrowserSdk()) {
      throw StateError('Authsignal browser SDK failed to load.');
    }
  }

  Future<void> _injectBrowserSdkScript() async {
    if (_hasBrowserSdk()) {
      return;
    }

    final existing = web.document.getElementById(_scriptElementId);
    if (existing != null) {
      await _waitForBrowserSdk(onFail: () {
        existing.remove();
      });
      return;
    }

    final script = web.document.createElement('script') as web.HTMLScriptElement
      ..id = _scriptElementId
      ..type = 'module'
      ..text = '''
        import { Authsignal } from '$_browserModuleUrl';
        window.Authsignal = Authsignal;
      ''';

    web.document.head?.append(script);
    await _waitForBrowserSdk(onFail: () {
      script.remove();
    });
  }

  Future<void> _waitForBrowserSdk({VoidCallback? onFail}) {
    final completer = Completer<void>();
    const maxAttempts = _scriptLoadTimeoutMs ~/ _scriptLoadCheckIntervalMs;
    var attempt = 0;

    Timer.periodic(const Duration(milliseconds: _scriptLoadCheckIntervalMs),
        (timer) {
      if (_hasBrowserSdk()) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
        return;
      }

      attempt++;
      if (attempt >= maxAttempts) {
        timer.cancel();
        if (!completer.isCompleted) {
          onFail?.call();
          completer.completeError(
            StateError('Authsignal browser SDK failed to load within '
                '${_scriptLoadTimeoutMs}ms. Please check your internet '
                'connection and ensure the CDN is accessible.'),
          );
        }
      }
    });

    return completer.future;
  }

  bool _hasBrowserSdk() {
    return _hasWindowProperty('Authsignal');
  }

  bool _isWebAuthnAvailable() {
    return _hasWindowProperty('PublicKeyCredential');
  }

  JSAny? _getWindowProperty(String name) {
    return _jsGet(web.window as JSObject, name.toJS);
  }

  bool _hasWindowProperty(String name) {
    return _jsHas(web.window as JSObject, name.toJS);
  }

  JSAny? _getProperty(JSObject obj, String name) {
    return _jsGet(obj, name.toJS);
  }

  bool _hasProperty(JSObject obj, String name) {
    return _jsHas(obj, name.toJS);
  }

  JSAny? _callMethod(JSObject obj, String method, List<JSAny> args) {
    final fn = _getProperty(obj, method);
    if (fn == null) return null;
    return _jsApply(fn as JSFunction, obj, args.toJS);
  }
}
