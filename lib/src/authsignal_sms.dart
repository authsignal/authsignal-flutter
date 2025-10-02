import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'types.dart';

class AuthsignalSms {
  final AsyncCallback initCheck;

  AuthsignalSms({required this.initCheck});

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<EnrollResponse>> enroll(String phoneNumber) async {
    await initCheck();

    var arguments = <String, dynamic>{'phoneNumber': phoneNumber};
    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
          'sms.enroll', arguments);

      if (data != null) {
        return AuthsignalResponse(data: EnrollResponse.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<ChallengeResponse>> challenge() async {
    await initCheck();

    try {
      final data =
          await methodChannel.invokeMapMethod<String, dynamic>('sms.challenge');

      if (data != null) {
        return AuthsignalResponse(data: ChallengeResponse.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<VerifyResponse>> verify(String code) async {
    await initCheck();

    var arguments = <String, dynamic>{'code': code};

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
          'sms.verify', arguments);

      if (data != null) {
        return AuthsignalResponse(data: VerifyResponse.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }
}
