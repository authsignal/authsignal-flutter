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
    bool ignorePasskeyAlreadyExistsError = false,
    bool syncCredentials = true,
  }) async {
    await initCheck();

    return AuthsignalFlutterPlatform.instance.passkeySignUp(
      token: token,
      username: username,
      displayName: displayName,
      useAutoRegister: useAutoRegister,
      ignorePasskeyAlreadyExistsError: ignorePasskeyAlreadyExistsError,
      syncCredentials: syncCredentials,
    );
  }

  Future<AuthsignalResponse<SignInResponse>> signIn({
    String? action,
    String? token,
    bool autofill = false,
    bool preferImmediatelyAvailableCredentials = true,
    bool syncCredentials = true,
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
        syncCredentials: syncCredentials,
      );
      return response;
    } finally {
      _autofillRequestPending = false;
    }
  }

  Future<void> cancel() async {
    await initCheck();
    _autofillRequestPending = false;
    await AuthsignalFlutterPlatform.instance.passkeyCancel();
  }

  Future<bool> isSupported() async {
    await initCheck();
    return AuthsignalFlutterPlatform.instance.passkeyIsSupported();
  }

  Future<AuthsignalResponse<bool>> shouldPromptToCreatePasskey({
    String? username,
  }) async {
    await initCheck();
    return AuthsignalFlutterPlatform.instance
        .passkeyShouldPromptToCreatePasskey(username: username);
  }

  @Deprecated(
      "Use 'preferImmediatelyAvailableCredentials' to control what happens when a passkey isn't available, or use 'shouldPromptToCreatePasskey' to check if you should prompt the user to create a passkey.")
  Future<AuthsignalResponse<bool>> isAvailableOnDevice() async {
    await initCheck();
    return AuthsignalFlutterPlatform.instance.passkeyIsAvailable();
  }
}
