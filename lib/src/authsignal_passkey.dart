import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'types.dart';

bool _initialized = false;
bool _autofillRequestPending = false;

class AuthsignalPasskey {
  final String tenantID;
  final String baseURL;

  AuthsignalPasskey(this.tenantID, {String? baseURL}) : baseURL = baseURL ?? "https://api.authsignal.com/v1";

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<SignUpResponse>> signUp(String token, {String? username, String? displayName}) async {
    await _ensureModuleIsInitialized();

    var arguments = <String, dynamic>{'token': token};
    arguments['username'] = username;
    arguments['displayName'] = displayName;

    var response = AuthsignalResponse<SignUpResponse>();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>('passkey.signUp', arguments);

      if (data != null) {
        response.data = SignUpResponse.fromMap(data);
      }
    } catch (ex) {
      response.error = ex.toString();
    }

    return response;
  }

  Future<AuthsignalResponse<SignInResponse>> signIn(
      {String? action, String? token, bool autofill = false, preferImmediatelyAvailableCredentials = true}) async {
    await _ensureModuleIsInitialized();

    var arguments = <String, dynamic>{};
    arguments['action'] = action;
    arguments['token'] = token;
    arguments['autofill'] = autofill;
    arguments['preferImmediatelyAvailableCredentials'] = preferImmediatelyAvailableCredentials;

    var response = AuthsignalResponse<SignInResponse>();

    try {
      if (autofill) {
        if (_autofillRequestPending) {
          return Future.value(response);
        } else {
          _autofillRequestPending = true;
        }
      }

      final data = await methodChannel.invokeMapMethod<String, dynamic>('passkey.signIn', arguments);

      _autofillRequestPending = false;

      if (data != null) {
        response.data = SignInResponse.fromMap(data);
      }
    } on PlatformException catch (ex) {
      _autofillRequestPending = false;

      switch (ex.message) {
        case 'SIGN_IN_CANCELED':
          {
            response.errorCode = 'passkeySignInCanceled';
            response.error = 'Passkey sign-in canceled';
          }

        case 'SIGN_IN_NO_CREDENTIAL':
          {
            response.errorCode = 'noPasskeyCredentialAvailable';
            response.error = 'No passkey credential available';
          }

        default:
          {
            response.error = ex.message;
          }
      }
    }

    return response;
  }

  Future<void> cancel() async {
    await _ensureModuleIsInitialized();

    if (Platform.isIOS) {
      await methodChannel.invokeMethod('passkey.cancel');
    }
  }

  Future<AuthsignalResponse<bool>> isAvailableOnDevice() async {
    await _ensureModuleIsInitialized();

    var response = AuthsignalResponse<bool>();

    try {
      final data = await methodChannel.invokeMethod<bool>('passkey.isAvailableOnDevice');

      response.data = data;
    } catch (ex) {
      response.error = ex.toString();
    }

    return response;
  }

  Future<void> _ensureModuleIsInitialized() async {
    if (!_initialized) {
      var arguments = <String, String>{'tenantID': tenantID, 'baseURL': baseURL};

      await methodChannel.invokeMethod<String>('passkey.initialize', arguments);

      _initialized = true;
    }
  }
}
