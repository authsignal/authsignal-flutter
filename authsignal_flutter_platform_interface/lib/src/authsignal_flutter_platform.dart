import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'types.dart';

abstract class AuthsignalFlutterPlatform extends PlatformInterface {
  AuthsignalFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static AuthsignalFlutterPlatform _instance =
      _TokenAuthsignalFlutterPlatform();

  static AuthsignalFlutterPlatform get instance => _instance;

  static bool get isDefaultInstance =>
      _instance is _TokenAuthsignalFlutterPlatform;

  static set instance(AuthsignalFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initialize({required String tenantId, required String baseUrl}) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> setToken(String token) {
    throw UnimplementedError('setToken() has not been implemented.');
  }

  Future<AuthsignalResponse<EnrollResponse>> emailEnroll(String email) {
    throw UnimplementedError('emailEnroll() has not been implemented.');
  }

  Future<AuthsignalResponse<ChallengeResponse>> emailChallenge() {
    throw UnimplementedError('emailChallenge() has not been implemented.');
  }

  Future<AuthsignalResponse<VerifyResponse>> emailVerify(String code) {
    throw UnimplementedError('emailVerify() has not been implemented.');
  }

  Future<AuthsignalResponse<SignUpResponse>> passkeySignUp({
    String? token,
    String? username,
    String? displayName,
    bool useAutoRegister = false,
  }) {
    throw UnimplementedError('passkeySignUp() has not been implemented.');
  }

  Future<AuthsignalResponse<SignInResponse>> passkeySignIn({
    String? action,
    String? token,
    bool autofill = false,
    bool preferImmediatelyAvailableCredentials = true,
  }) {
    throw UnimplementedError('passkeySignIn() has not been implemented.');
  }

  Future<void> passkeyCancel() {
    throw UnimplementedError('passkeyCancel() has not been implemented.');
  }

  Future<AuthsignalResponse<bool>> passkeyIsAvailable() {
    throw UnimplementedError('passkeyIsAvailable() has not been implemented.');
  }
}

class _TokenAuthsignalFlutterPlatform extends AuthsignalFlutterPlatform {}
