import 'package:flutter/services.dart';

import 'types.dart';

class AuthsignalDevice {
  final Future<void> Function() initCheck;
  late MethodChannel _channel;

  AuthsignalDevice({required this.initCheck}) {
    _channel = const MethodChannel('authsignal');
  }

  /// Get the device credential for the current device
  Future<AuthsignalResponse<DeviceCredential?>> getCredential() async {
    try {
      await initCheck();

      final result = await _channel.invokeMethod('device.getCredential');

      if (result == null) {
        return AuthsignalResponse(data: null);
      }

      final credential = DeviceCredential.fromMap(Map<String, dynamic>.from(result));
      return AuthsignalResponse(data: credential);
    } on PlatformException catch (e) {
      return AuthsignalResponse.fromError(e);
    }
  }

  /// Add a device credential for the current device
  Future<AuthsignalResponse<DeviceCredential>> addCredential({
    String? token,
    String? deviceName,
    bool userAuthenticationRequired = false,
    int timeout = 0,
    int authorizationType = 0,
  }) async {
    try {
      await initCheck();

      var arguments = <String, dynamic>{
        'token': token,
        'deviceName': deviceName,
        'userAuthenticationRequired': userAuthenticationRequired,
        'timeout': timeout,
        'authorizationType': authorizationType,
      };

      final result = await _channel.invokeMethod('device.addCredential', arguments);
      final credential = DeviceCredential.fromMap(Map<String, dynamic>.from(result));
      return AuthsignalResponse(data: credential);
    } on PlatformException catch (e) {
      return AuthsignalResponse.fromError(e);
    }
  }

  /// Remove the device credential for the current device
  Future<AuthsignalResponse<bool>> removeCredential() async {
    try {
      await initCheck();

      final result = await _channel.invokeMethod('device.removeCredential');
      return AuthsignalResponse(data: result as bool);
    } on PlatformException catch (e) {
      return AuthsignalResponse.fromError(e);
    }
  }

  /// Get a pending device challenge
  Future<AuthsignalResponse<DeviceChallenge?>> getChallenge() async {
    try {
      await initCheck();

      final result = await _channel.invokeMethod('device.getChallenge');

      if (result == null) {
        return AuthsignalResponse(data: null);
      }

      final challenge = DeviceChallenge.fromMap(Map<String, dynamic>.from(result));
      return AuthsignalResponse(data: challenge);
    } on PlatformException catch (e) {
      return AuthsignalResponse.fromError(e);
    }
  }

  /// Claim a device challenge
  Future<AuthsignalResponse<ClaimChallengeResponse>> claimChallenge(
    String challengeId,
  ) async {
    try {
      await initCheck();

      var arguments = <String, dynamic>{
        'challengeId': challengeId,
      };

      final result = await _channel.invokeMethod('device.claimChallenge', arguments);
      final response = ClaimChallengeResponse.fromMap(Map<String, dynamic>.from(result));
      return AuthsignalResponse(data: response);
    } on PlatformException catch (e) {
      return AuthsignalResponse.fromError(e);
    }
  }

  /// Update a device challenge (approve or deny)
  Future<AuthsignalResponse<bool>> updateChallenge(
    String challengeId,
    bool approved, {
    String? verificationCode,
  }) async {
    try {
      await initCheck();

      var arguments = <String, dynamic>{
        'challengeId': challengeId,
        'approved': approved,
        'verificationCode': verificationCode,
      };

      final result = await _channel.invokeMethod('device.updateChallenge', arguments);
      return AuthsignalResponse(data: result as bool);
    } on PlatformException catch (e) {
      return AuthsignalResponse.fromError(e);
    }
  }

  /// Verify the device for authentication
  Future<AuthsignalResponse<VerifyDeviceResponse>> verify() async {
    try {
      await initCheck();

      final result = await _channel.invokeMethod('device.verify');
      final response = VerifyDeviceResponse.fromMap(Map<String, dynamic>.from(result));
      return AuthsignalResponse(data: response);
    } on PlatformException catch (e) {
      return AuthsignalResponse.fromError(e);
    }
  }
}
