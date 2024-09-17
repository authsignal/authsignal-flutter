import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'types.dart';

class AuthsignalPush {
  final String tenantID;
  final String baseURL;

  bool _initialized = false;

  AuthsignalPush(this.tenantID, {String? baseURL}) : baseURL = baseURL ?? "https://api.authsignal.com/v1";

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<PushCredential?>> getCredential() async {
    await _ensureModuleIsInitialized();

    var response = AuthsignalResponse<PushCredential?>();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>('push.getCredential');

      if (data != null) {
        response.data = PushCredential.fromMap(data);
      }
    } catch (ex) {
      response.error = ex.toString();
    }

    return response;
  }

  Future<AuthsignalResponse<bool>> addCredential({String? token}) async {
    await _ensureModuleIsInitialized();

    var arguments = <String, dynamic>{'token': token};

    var response = AuthsignalResponse<bool>();

    try {
      final data = await methodChannel.invokeMethod<bool>('push.addCredential', arguments);

      response.data = data;
    } catch (ex) {
      response.error = ex.toString();
    }

    return response;
  }

  Future<AuthsignalResponse<bool>> removeCredential() async {
    await _ensureModuleIsInitialized();

    var response = AuthsignalResponse<bool>();

    try {
      final data = await methodChannel.invokeMethod<bool>('push.removeCredential');

      response.data = data;
    } catch (ex) {
      response.error = ex.toString();
    }

    return response;
  }

  Future<AuthsignalResponse<PushChallenge?>> getChallenge() async {
    await _ensureModuleIsInitialized();

    var response = AuthsignalResponse<PushChallenge?>();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>('push.getChallenge');

      if (data != null) {
        response.data = PushChallenge.fromMap(data);
      }
    } catch (ex) {
      response.error = ex.toString();
    }

    return response;
  }

  Future<AuthsignalResponse<bool>> updateChallenge(String challengeId, bool approved,
      {String? verificationCode}) async {
    await _ensureModuleIsInitialized();

    var arguments = <String, dynamic>{'challengeId': challengeId, 'approved': approved};

    arguments['verificationCode'] = verificationCode;

    var response = AuthsignalResponse<bool>();

    try {
      final data = await methodChannel.invokeMethod<bool>('push.updateChallenge', arguments);

      response.data = data;
    } catch (ex) {
      response.error = ex.toString();
    }

    return response;
  }

  Future<void> _ensureModuleIsInitialized() async {
    if (!_initialized) {
      var arguments = <String, String>{'tenantID': tenantID, 'baseURL': baseURL};

      await methodChannel.invokeMethod<String>('push.initialize', arguments);

      _initialized = true;
    }
  }
}
