import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'types.dart';

class AuthsignalSms {
  final String tenantID;
  final String baseURL;

  bool _initialized = false;

  AuthsignalSms(this.tenantID, {String? baseURL}) : baseURL = baseURL ?? "https://api.authsignal.com/v1";

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<EnrollResponse>> enroll(String phoneNumber) async {
    await _ensureModuleIsInitialized();

    var arguments = <String, dynamic>{'phoneNumber': phoneNumber};

    var response = AuthsignalResponse<EnrollResponse>();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>('sms.enroll', arguments);

      if (data != null) {
        response.data = EnrollResponse.fromMap(data);
      }
    } catch (ex) {
      response.error = ex.toString();
    }

    return response;
  }

  Future<AuthsignalResponse<ChallengeResponse>> challenge() async {
    await _ensureModuleIsInitialized();

    var response = AuthsignalResponse<ChallengeResponse>();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>('sms.challenge');

      if (data != null) {
        response.data = ChallengeResponse.fromMap(data);
      }
    } catch (ex) {
      response.error = ex.toString();
    }

    return response;
  }

  Future<AuthsignalResponse<VerifyResponse>> verify(String code) async {
    await _ensureModuleIsInitialized();

    var arguments = <String, dynamic>{'code': code};

    var response = AuthsignalResponse<VerifyResponse>();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>('sms.verify', arguments);

      if (data != null) {
        response.data = VerifyResponse.fromMap(data);
      }
    } catch (ex) {
      response.error = ex.toString();
    }

    return response;
  }

  Future<void> _ensureModuleIsInitialized() async {
    if (!_initialized) {
      var arguments = <String, String>{'tenantID': tenantID, 'baseURL': baseURL};

      await methodChannel.invokeMethod<String>('sms.initialize', arguments);

      _initialized = true;
    }
  }
}
