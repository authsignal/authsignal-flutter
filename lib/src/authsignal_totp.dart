import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'authsignal_flutter_platform.dart';
import 'types.dart';

class AuthsignalTotp {
  final AsyncCallback initCheck;

  AuthsignalTotp({required this.initCheck});

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<EnrollTotpResponse>> enroll() async {
    await initCheck();

    if (kIsWeb) {
      return AuthsignalFlutterPlatform.instance.totpEnroll();
    }

    try {
      final data =
          await methodChannel.invokeMapMethod<String, dynamic>('totp.enroll');

      if (data != null) {
        return AuthsignalResponse(data: EnrollTotpResponse.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<VerifyResponse>> verify(String code) async {
    await initCheck();

    if (kIsWeb) {
      return AuthsignalFlutterPlatform.instance.totpVerify(code);
    }

    var arguments = <String, dynamic>{'code': code};

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
          'totp.verify', arguments);

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
