import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'authsignal_flutter_platform.dart';
import 'types.dart';

class MethodChannelAuthsignalFlutter extends AuthsignalFlutterPlatform {
  MethodChannelAuthsignalFlutter();

  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('authsignal');

  @override
  Future<void> initialize({
    required String tenantId,
    required String baseUrl,
  }) async {
    await methodChannel.invokeMethod<void>('initialize', {
      'tenantID': tenantId,
      'baseURL': baseUrl,
    });
  }

  @override
  Future<void> setToken(String token) async {
    await methodChannel.invokeMethod<void>('setToken', {'token': token});
  }

  @override
  Future<AuthsignalResponse<EnrollResponse>> emailEnroll(String email) async {
    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
        'email.enroll',
        {'email': email},
      );

      if (data != null) {
        return AuthsignalResponse(data: EnrollResponse.fromMap(data));
      }

      return AuthsignalResponse(data: null);
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  @override
  Future<AuthsignalResponse<ChallengeResponse>> emailChallenge() async {
    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
        'email.challenge',
      );

      if (data != null) {
        return AuthsignalResponse(data: ChallengeResponse.fromMap(data));
      }

      return AuthsignalResponse(data: null);
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  @override
  Future<AuthsignalResponse<VerifyResponse>> emailVerify(String code) async {
    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
        'email.verify',
        {'code': code},
      );

      if (data != null) {
        return AuthsignalResponse(data: VerifyResponse.fromMap(data));
      }

      return AuthsignalResponse(data: null);
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  @override
  Future<AuthsignalResponse<SignUpResponse>> passkeySignUp({
    String? token,
    String? username,
    String? displayName,
    bool useAutoRegister = false,
  }) async {
    final arguments = <String, dynamic>{
      'token': token,
      'username': username,
      'displayName': displayName,
    };
    if (useAutoRegister) {
      arguments['useAutoRegister'] = useAutoRegister;
    }

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
        'passkey.signUp',
        arguments,
      );

      if (data != null) {
        return AuthsignalResponse(data: SignUpResponse.fromMap(data));
      }

      return AuthsignalResponse(data: null);
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  @override
  Future<AuthsignalResponse<SignInResponse>> passkeySignIn({
    String? action,
    String? token,
    bool autofill = false,
    bool preferImmediatelyAvailableCredentials = true,
  }) async {
    final arguments = <String, dynamic>{
      'action': action,
      'token': token,
      'autofill': autofill,
      'preferImmediatelyAvailableCredentials':
          preferImmediatelyAvailableCredentials,
    };

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
        'passkey.signIn',
        arguments,
      );

      if (data != null) {
        return AuthsignalResponse(data: SignInResponse.fromMap(data));
      }

      return AuthsignalResponse(data: null);
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  @override
  Future<void> passkeyCancel() async {
    try {
      await methodChannel.invokeMethod<void>('passkey.cancel');
    } on PlatformException catch (_) {
    }
  }

  @override
  Future<AuthsignalResponse<bool>> passkeyIsAvailable() async {
    try {
      final isAvailable =
          await methodChannel.invokeMethod<bool>('passkey.isAvailableOnDevice');
      return AuthsignalResponse(data: isAvailable);
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }
}
