import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:authsignal_flutter_platform_interface/authsignal_flutter_platform_interface.dart';

class AuthsignalInApp {
  final AsyncCallback initCheck;

  AuthsignalInApp({required this.initCheck});

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<AppCredential?>> getCredential() async {
    await initCheck();

    try {
      final data = await methodChannel
          .invokeMapMethod<String, dynamic>('inapp.getCredential');

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
          .invokeMapMethod<String, dynamic>('inapp.addCredential', arguments);

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
          await methodChannel.invokeMethod<bool>('inapp.removeCredential');

      if (data != null) {
        return AuthsignalResponse(data: data);
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<InAppVerifyResponse>> verify() async {
    await initCheck();

    try {
      final data = await methodChannel
          .invokeMapMethod<String, dynamic>('inapp.verify');

      if (data != null) {
        return AuthsignalResponse(data: InAppVerifyResponse.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }
}

