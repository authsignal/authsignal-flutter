import 'package:flutter/foundation.dart';

import 'authsignal_flutter_platform.dart';
import 'types.dart';

class AuthsignalEmail {
  final AsyncCallback initCheck;

  AuthsignalEmail({required this.initCheck});

  Future<AuthsignalResponse<EnrollResponse>> enroll(String email) async {
    await initCheck();

    return AuthsignalFlutterPlatform.instance.emailEnroll(email);
  }

  Future<AuthsignalResponse<ChallengeResponse>> challenge() async {
    await initCheck();

    return AuthsignalFlutterPlatform.instance.emailChallenge();
  }

  Future<AuthsignalResponse<VerifyResponse>> verify(String code) async {
    await initCheck();

    return AuthsignalFlutterPlatform.instance.emailVerify(code);
  }
}
