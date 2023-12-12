import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'types.dart';

bool _initialized = false;
bool _autofillRequestPending = false;

class AuthsignalPasskey {
  final String tenantID;
  final String baseURL;

  AuthsignalPasskey(this.tenantID, {String? baseURL})
      : baseURL = baseURL ?? "https://api.authsignal.com/v1";

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<String>> signUp(String token,
      {String? userName}) async {
    await _ensureModuleIsInitialized();

    var arguments = <String, dynamic>{'token': token};
    arguments['userName'] = userName;

    var response = AuthsignalResponse<String>();

    try {
      final data =
          await methodChannel.invokeMethod<String>('passkey.signUp', arguments);

      response.data = data;
    } catch (ex) {
      response.error = ex.toString();
    }

    return response;
  }

  Future<AuthsignalResponse<String>> signIn(
      {String? token, bool autofill = false}) async {
    await _ensureModuleIsInitialized();

    var arguments = <String, dynamic>{};
    arguments['token'] = token;
    arguments['autofill'] = autofill;

    var response = AuthsignalResponse<String>();

    try {
      if (autofill) {
        if (_autofillRequestPending) {
          return Future.value(response);
        } else {
          _autofillRequestPending = true;
        }
      }

      final data =
          await methodChannel.invokeMethod<String>('passkey.signIn', arguments);

      _autofillRequestPending = false;

      response.data = data;
    } catch (ex) {
      _autofillRequestPending = false;

      response.error = ex.toString();
    }

    return response;
  }

  Future<void> cancel() async {
    await _ensureModuleIsInitialized();

    if (Platform.isIOS) {
      await methodChannel.invokeMethod('passkey.cancel');
    }
  }

  Future<void> _ensureModuleIsInitialized() async {
    if (!_initialized) {
      var arguments = <String, String>{
        'tenantID': tenantID,
        'baseURL': baseURL
      };

      await methodChannel.invokeMethod<String>('passkey.initialize', arguments);

      _initialized = true;
    }
  }
}
