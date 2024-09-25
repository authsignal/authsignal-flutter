import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'types.dart';

class AuthsignalPush {
  final String tenantID;
  final String baseURL;

  bool _initialized = false;

  AuthsignalPush({required this.tenantID, String? baseURL}) : baseURL = baseURL ?? "https://api.authsignal.com/v1";

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<PushCredential?>> getCredential() async {
    await _ensureModuleIsInitialized();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>('push.getCredential');

      if (data != null) {
        return AuthsignalResponse(data: PushCredential.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<bool>> addCredential({String? token}) async {
    await _ensureModuleIsInitialized();

    var arguments = <String, dynamic>{'token': token};

    try {
      final data = await methodChannel.invokeMethod<bool>('push.addCredential', arguments);

      if (data != null) {
        return AuthsignalResponse(data: data);
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<bool>> removeCredential() async {
    await _ensureModuleIsInitialized();

    try {
      final data = await methodChannel.invokeMethod<bool>('push.removeCredential');

      if (data != null) {
        return AuthsignalResponse(data: data);
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<PushChallenge?>> getChallenge() async {
    await _ensureModuleIsInitialized();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>('push.getChallenge');

      if (data != null) {
        return AuthsignalResponse(data: PushChallenge.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<bool>> updateChallenge(
      {required String challengeId, required bool approved, String? verificationCode}) async {
    await _ensureModuleIsInitialized();

    var arguments = <String, dynamic>{'challengeId': challengeId, 'approved': approved};

    arguments['verificationCode'] = verificationCode;

    try {
      final data = await methodChannel.invokeMethod<bool>('push.updateChallenge', arguments);

      if (data != null) {
        return AuthsignalResponse(data: data);
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<void> _ensureModuleIsInitialized() async {
    if (!_initialized) {
      var arguments = <String, String>{'tenantID': tenantID, 'baseURL': baseURL};

      await methodChannel.invokeMethod<String>('push.initialize', arguments);

      _initialized = true;
    }
  }
}
