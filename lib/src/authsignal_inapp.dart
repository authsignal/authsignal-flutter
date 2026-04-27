import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'types.dart';

class AuthsignalInApp {
  final AsyncCallback initCheck;

  AuthsignalInApp({required this.initCheck});

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<AuthsignalResponse<AppCredential?>> getCredential({
    String? username,
  }) async {
    await initCheck();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
        'inapp.getCredential',
        {'username': username},
      );

      if (data != null) {
        return AuthsignalResponse(data: AppCredential.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<AppCredential>> addCredential({
    String? token,
    bool requireUserAuthentication = false,
    KeychainAccess? keychainAccess,
    String? username,
    bool performAttestation = false,
  }) async {
    await initCheck();

    final arguments = <String, dynamic>{
      'token': token,
      'requireUserAuthentication': requireUserAuthentication,
      'keychainAccess': keychainAccess?.value,
      'username': username,
      'performAttestation': performAttestation,
    };

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

  Future<AuthsignalResponse<bool>> removeCredential({String? username}) async {
    await initCheck();

    try {
      final data = await methodChannel.invokeMethod<bool>(
        'inapp.removeCredential',
        {'username': username},
      );

      if (data != null) {
        return AuthsignalResponse(data: data);
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<InAppVerifyResponse>> verify({
    String? action,
    String? username,
  }) async {
    await initCheck();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
        'inapp.verify',
        {'action': action, 'username': username},
      );

      if (data != null) {
        return AuthsignalResponse(data: InAppVerifyResponse.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<AppCredential>> createPin({
    required String pin,
    required String username,
    String? token,
  }) async {
    await initCheck();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
        'inapp.createPin',
        {'pin': pin, 'username': username, 'token': token},
      );

      if (data != null) {
        return AuthsignalResponse(data: AppCredential.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<VerifyPinResponse>> verifyPin({
    required String pin,
    required String username,
    String? action,
  }) async {
    await initCheck();

    try {
      final data = await methodChannel.invokeMapMethod<String, dynamic>(
        'inapp.verifyPin',
        {'pin': pin, 'username': username, 'action': action},
      );

      if (data != null) {
        return AuthsignalResponse(data: VerifyPinResponse.fromMap(data));
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<bool>> deletePin({required String username}) async {
    await initCheck();

    try {
      final data = await methodChannel.invokeMethod<bool>(
        'inapp.deletePin',
        {'username': username},
      );

      if (data != null) {
        return AuthsignalResponse(data: data);
      } else {
        return AuthsignalResponse(data: null);
      }
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }

  Future<AuthsignalResponse<List<String>>> getAllPinUsernames() async {
    await initCheck();

    try {
      final data = await methodChannel
          .invokeListMethod<String>('inapp.getAllPinUsernames');

      return AuthsignalResponse(data: data ?? <String>[]);
    } on PlatformException catch (ex) {
      return AuthsignalResponse.fromError(ex);
    }
  }
}
