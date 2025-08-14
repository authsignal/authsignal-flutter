import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'types.dart';

class AuthsignalWhatsapp {
  final AsyncCallback initCheck;

  AuthsignalWhatsapp({required this.initCheck});

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<ChallengeResponse>> challenge() async {
    await initCheck();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>('whatsapp.challenge');

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
      final data = await methodChannel.invokeMapMethod<String, dynamic>('whatsapp.verify', arguments);

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
