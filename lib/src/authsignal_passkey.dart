import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'types.dart';

bool _autofillRequestPending = false;

class AuthsignalPasskey {
  final AsyncCallback initCheck;

  AuthsignalPasskey({required this.initCheck});

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<SignUpResponse>> signUp(
      {String? token, String? username, String? displayName}) async {
    await initCheck();

    var arguments = <String, dynamic>{'token': token};
    arguments['username'] = username;
    arguments['displayName'] = displayName;

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
          'passkey.signUp', arguments);

      if (data != null) {
        return AuthsignalResponse(data: SignUpResponse.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<SignInResponse>> signIn(
      {String? action,
      String? token,
      bool autofill = false,
      preferImmediatelyAvailableCredentials = true}) async {
    await initCheck();

    var arguments = <String, dynamic>{};
    arguments['action'] = action;
    arguments['token'] = token;
    arguments['autofill'] = autofill;
    arguments['preferImmediatelyAvailableCredentials'] =
        preferImmediatelyAvailableCredentials;

    try {
      if (autofill) {
        if (_autofillRequestPending) {
          return Future.value(AuthsignalResponse(data: null));
        } else {
          _autofillRequestPending = true;
        }
      }

      final data = await methodChannel.invokeMapMethod<String, dynamic>(
          'passkey.signIn', arguments);

      _autofillRequestPending = false;

      if (data != null) {
        return AuthsignalResponse(data: SignInResponse.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      _autofillRequestPending = false;

      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<void> cancel() async {
    await initCheck();

    if (Platform.isIOS) {
      await methodChannel.invokeMethod('passkey.cancel');
    }
  }

  Future<AuthsignalResponse<bool>> isAvailableOnDevice() async {
    await initCheck();

    try {
      final data =
          await methodChannel.invokeMethod<bool>('passkey.isAvailableOnDevice');

      return AuthsignalResponse(data: data);
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }
}
