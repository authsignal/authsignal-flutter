import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:authsignal_flutter_platform_interface/authsignal_flutter_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

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

  Object? _client;
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

    final constructor = js_util.getProperty(html.window, 'Authsignal');
    if (constructor == null) {
      throw StateError(
          'Authsignal browser SDK loaded but constructor is not available. '
          'This may indicate a version mismatch or CDN issue.');
    }

    final options = js_util.jsify({
      'tenantId': tenantId,
      'baseUrl': baseUrl,
    });

    try {
      _client = js_util.callConstructor(constructor, [options]);
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
      js_util.callMethod<void>(_client!, 'setToken', [token]);
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
        js_util.jsify({'email': email})
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
        js_util.jsify({'code': code})
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

    final passkeyApi = js_util.getProperty(client, 'passkey');
    if (passkeyApi == null || !js_util.hasProperty(passkeyApi, 'cancel')) {
      return;
    }

    try {
      js_util.callMethod<void>(passkeyApi, 'cancel', const []);
    } catch (_) {
    }
  }

  @override
  Future<AuthsignalResponse<bool>> passkeyIsAvailable() async {
    final client = _client;

    if (client == null) {
      return AuthsignalResponse(data: _isWebAuthnAvailable());
    }

    final passkeyApi = js_util.getProperty(client, 'passkey');
    if (passkeyApi != null && js_util.hasProperty(passkeyApi, 'isAvailable')) {
      try {
        final result = await js_util.promiseToFuture<Object?>(
          js_util.callMethod(passkeyApi, 'isAvailable', const []),
        );
        if (result is bool) {
          return AuthsignalResponse(data: result);
        }
      } catch (_) {
      }
    }

    return AuthsignalResponse(data: _isWebAuthnAvailable());
  }

  bool _isInitializedFor(String tenantId, String baseUrl) {
    return _client != null && _tenantId == tenantId && _baseUrl == baseUrl;
  }

  Future<AuthsignalResponse<T>> _invokeEmailMethod<T>(
    String method,
    List<Object?> arguments,
    T Function(Map<String, dynamic> data) parser,
  ) async {
    final client = _client;
    if (client == null) {
      return _clientNotInitializedResponse<T>();
    }

    final emailApi = js_util.getProperty(client, 'email');
    if (emailApi == null) {
      return AuthsignalResponse.withError(
        error: 'Email API is not available in the browser SDK. '
            'This may indicate a version incompatibility.',
        errorCode: 'api_unavailable',
      );
    }

    try {
      final jsResult = await js_util.promiseToFuture<Object?>(
        js_util.callMethod(emailApi, method, arguments),
      );
      return _mapResponse(jsResult, parser);
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
    Object client,
    String method,
    Map<String, dynamic> payload,
    T Function(Map<String, dynamic> data) parser,
  ) async {
    final passkeyApi = js_util.getProperty(client, 'passkey');
    if (passkeyApi == null) {
      return AuthsignalResponse.withError(
        error: 'Passkey API is not available in the browser SDK. '
            'This may indicate a version incompatibility.',
        errorCode: 'api_unavailable',
      );
    }

    final args = payload.isEmpty ? const [] : <Object?>[js_util.jsify(payload)];

    try {
      final jsResult = await js_util.promiseToFuture<Object?>(
        js_util.callMethod(passkeyApi, method, args),
      );
      return _mapResponse(jsResult, parser);
    } catch (error) {
      return _responseFromJsError(error);
    }
  }

  AuthsignalResponse<T> _mapResponse<T>(
    Object? jsResult,
    T Function(Map<String, dynamic> data) parser,
  ) {
    if (jsResult == null) {
      return AuthsignalResponse(data: null);
    }

    final dartified = js_util.dartify(jsResult);
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
      if (js_util.hasProperty(error, 'message')) {
        final value = js_util.getProperty(error, 'message');
        message = value?.toString();
      }
    } catch (_) {
    }

    try {
      if (js_util.hasProperty(error, 'code')) {
        final value = js_util.getProperty(error, 'code');
        code = value?.toString();
      }
    } catch (_) {
    }

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

    final existing = html.document.getElementById(_scriptElementId);
    if (existing is html.ScriptElement) {
      await _waitForBrowserSdk(onFail: () {
        existing.remove();
      });
      return;
    }

    final script = html.ScriptElement()
      ..id = _scriptElementId
      ..type = 'module'
      ..text = '''
        import { Authsignal } from '$_browserModuleUrl';
        window.Authsignal = Authsignal;
      '''
      ..onError.listen((event) {
        _scriptLoader = null;
      });

    html.document.head?.append(script);
    await _waitForBrowserSdk(onFail: () {
      script.remove();
    });
  }

  Future<void> _waitForBrowserSdk({VoidCallback? onFail}) {
    final completer = Completer<void>();
    const maxAttempts = _scriptLoadTimeoutMs ~/ _scriptLoadCheckIntervalMs;
    var attempt = 0;

    Timer.periodic(const Duration(milliseconds: _scriptLoadCheckIntervalMs), (timer) {
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
    return js_util.hasProperty(html.window, 'Authsignal');
  }

  bool _isWebAuthnAvailable() {
    return js_util.hasProperty(html.window, 'PublicKeyCredential');
  }
}
