import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'types.dart';

class AuthsignalTotp {
  final String tenantID;
  final String baseURL;

  bool _initialized = false;

  AuthsignalTotp(this.tenantID, {String? baseURL}) : baseURL = baseURL ?? "https://api.authsignal.com/v1";

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<EnrollTotpResponse>> enroll() async {
    await _ensureModuleIsInitialized();

    var response = AuthsignalResponse<EnrollTotpResponse>();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>('totp.enroll');

      if (data != null) {
        response.data = EnrollTotpResponse.fromMap(data);
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
      final data = await methodChannel.invokeMapMethod<String, dynamic>('totp.verify', arguments);

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

      await methodChannel.invokeMethod<String>('totp.initialize', arguments);

      _initialized = true;
    }
  }
}
