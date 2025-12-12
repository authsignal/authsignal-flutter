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

  static const String _browserSdkVersion = 'latest';
  static const String _browserModuleUrl =
      'https://cdn.jsdelivr.net/npm/@authsignal/browser@$_browserSdkVersion/+esm';

  static const int _scriptLoadTimeoutMs = 10000;
  static const int _scriptLoadCheckIntervalMs = 100;

  JSObject? _client;
  String? _tenantId;
  String? _baseUrl;
  String? _pendingToken;
  String? _sessionToken;
  Future<void>? _scriptLoader;

  @override
  Future<void> initialize(
      {required String tenantId, required String baseUrl}) async {
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
    }.jsify()!;

    try {
      _client = _jsConstruct(constructor as JSFunction, [options].toJS);
      _tenantId = tenantId;
      _baseUrl = baseUrl;

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
      [<String, dynamic>{'email': email}.jsify()!],
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
      [<String, dynamic>{'code': code}.jsify()!],
      (map) => VerifyResponse.fromMap(map),
    );
  }

  @override
  Future<AuthsignalResponse<SignUpResponse>> passkeySignUp({
    String? token,
    String? username,
    String? displayName,
    bool useAutoRegister = false,
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
    );
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
      [<String, dynamic>{'phoneNumber': phoneNumber}.jsify()!],
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
      [<String, dynamic>{'code': code}.jsify()!],
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
      [<String, dynamic>{'code': code}.jsify()!],
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
      [<String, dynamic>{'code': code}.jsify()!],
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
    T Function(Map<String, dynamic> data) parser,
  ) async {
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
      return _mapResponse(result, parser);
    } catch (error) {
      return _responseFromJsError(error);
    }
  }

  AuthsignalResponse<T> _mapResponse<T>(
    JSAny? jsResult,
    T Function(Map<String, dynamic> data) parser,
  ) {
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
      return AuthsignalResponse(data: parser(_toStringKeyedMap(data)));
    }

    return AuthsignalResponse(data: null);
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

    Timer.periodic(
        const Duration(milliseconds: _scriptLoadCheckIntervalMs), (timer) {
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
