import 'package:flutter/foundation.dart';

import 'authsignal_flutter_platform.dart';
import 'types.dart';

bool _autofillRequestPending = false;

class AuthsignalPasskey {
  final AsyncCallback initCheck;

  AuthsignalPasskey({required this.initCheck});

  Future<AuthsignalResponse<SignUpResponse>> signUp({
    String? token,
    String? username,
    String? displayName,
    bool useAutoRegister = false,
  }) async {
    await initCheck();

    return AuthsignalFlutterPlatform.instance.passkeySignUp(
      token: token,
      username: username,
      displayName: displayName,
      useAutoRegister: useAutoRegister,
    );
  }

  Future<AuthsignalResponse<SignInResponse>> signIn({
    String? action,
    String? token,
    bool autofill = false,
    bool preferImmediatelyAvailableCredentials = true,
  }) async {
    await initCheck();

    if (autofill) {
      if (_autofillRequestPending) {
        return Future.value(AuthsignalResponse(data: null));
      } else {
        _autofillRequestPending = true;
      }
    }

    try {
      final response = await AuthsignalFlutterPlatform.instance.passkeySignIn(
        action: action,
        token: token,
        autofill: autofill,
        preferImmediatelyAvailableCredentials:
            preferImmediatelyAvailableCredentials,
      );
      return response;
    } finally {
      _autofillRequestPending = false;
    }
  }

  Future<void> cancel() async {
    await initCheck();
    await AuthsignalFlutterPlatform.instance.passkeyCancel();
  }

  Future<AuthsignalResponse<bool>> isAvailableOnDevice() async {
    await initCheck();
    return AuthsignalFlutterPlatform.instance.passkeyIsAvailable();
  }
}
