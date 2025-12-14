import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'authsignal_flutter_platform.dart';
import 'types.dart';

class AuthsignalWhatsApp {
  final AsyncCallback initCheck;

  AuthsignalWhatsApp({required this.initCheck});

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<ChallengeResponse>> challenge() async {
    await initCheck();

    if (kIsWeb) {
      return AuthsignalFlutterPlatform.instance.whatsappChallenge();
    }

    try {
      final data = await methodChannel
          .invokeMapMethod<String, dynamic>('whatsapp.challenge');

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

    if (kIsWeb) {
      return AuthsignalFlutterPlatform.instance.whatsappVerify(code);
    }

    var arguments = <String, dynamic>{'code': code};

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
          'whatsapp.verify', arguments);

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
