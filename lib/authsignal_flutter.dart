import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/authsignal_passkey.dart';
import 'src/authsignal_push.dart';
import 'src/authsignal_email.dart';
import 'src/authsignal_sms.dart';
import 'src/authsignal_totp.dart';
import 'src/authsignal_device.dart';

export 'src/types.dart' show AuthsignalResponse, TokenPayload, ErrorCode, DeviceCredential, DeviceChallenge, ClaimChallengeResponse, VerifyDeviceResponse;

class Authsignal {
  String tenantID;
  String baseURL;

  late AuthsignalPasskey passkey;
  late AuthsignalPush push;
  late AuthsignalEmail email;
  late AuthsignalSms sms;
  late AuthsignalTotp totp;
  late AuthsignalDevice device;

  bool _initialized = false;

  Authsignal({required this.tenantID, this.baseURL = "https://api.authsignal.com/v1"}) {
    passkey = AuthsignalPasskey(initCheck: initCheck);
    push = AuthsignalPush(initCheck: initCheck);
    email = AuthsignalEmail(initCheck: initCheck);
    sms = AuthsignalSms(initCheck: initCheck);
    totp = AuthsignalTotp(initCheck: initCheck);
    device = AuthsignalDevice(initCheck: initCheck);
  }

  Future<void> initCheck() async {
    if (!_initialized) {
      var arguments = <String, String>{'tenantID': tenantID, 'baseURL': baseURL};

      await methodChannel.invokeMethod<String>('initialize', arguments);

      _initialized = true;
    }
  }

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<void> setToken(String token) async {
    var arguments = <String, dynamic>{'token': token};

    await methodChannel.invokeMethod('setToken', arguments);
  }
}
