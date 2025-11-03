import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'types.dart';

class AuthsignalQr {
  final AsyncCallback initCheck;

  AuthsignalQr({required this.initCheck});

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<AppCredential?>> getCredential() async {
    await initCheck();

    try {
      final data = await methodChannel
          .invokeMapMethod<String, dynamic>('qr.getCredential');

      if (data != null) {
        return AuthsignalResponse(data: AppCredential.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<AppCredential>> addCredential({String? token}) async {
    await initCheck();

    var arguments = <String, dynamic>{'token': token};

    try {
      final data = await methodChannel
          .invokeMapMethod<String, dynamic>('qr.addCredential', arguments);

      if (data != null) {
        return AuthsignalResponse(data: AppCredential.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<bool>> removeCredential() async {
    await initCheck();

    try {
      final data =
          await methodChannel.invokeMethod<bool>('qr.removeCredential');

      if (data != null) {
        return AuthsignalResponse(data: data);
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<ClaimChallengeResponse>> claimChallenge(
      String challengeId) async {
    await initCheck();

    var arguments = <String, dynamic>{'challengeId': challengeId};

    try {
      final data = await methodChannel
          .invokeMapMethod<String, dynamic>('qr.claimChallenge', arguments);

      if (data != null) {
        return AuthsignalResponse(data: ClaimChallengeResponse.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<bool>> updateChallenge({
    required String challengeId,
    required bool approved,
    String? verificationCode,
  }) async {
    await initCheck();

    var arguments = <String, dynamic>{
      'challengeId': challengeId,
      'approved': approved
    };

    arguments['verificationCode'] = verificationCode;

    try {
      final data = await methodChannel.invokeMethod<bool>(
          'qr.updateChallenge', arguments);

      if (data != null) {
        return AuthsignalResponse(data: data);
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }
}

