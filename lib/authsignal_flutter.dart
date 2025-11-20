import 'package:flutter/foundation.dart';

import 'package:authsignal_flutter_platform_interface/authsignal_flutter_platform_interface.dart';

import 'src/authsignal_passkey.dart';
import 'src/authsignal_push.dart';
import 'src/authsignal_email.dart';
import 'src/authsignal_sms.dart';
import 'src/authsignal_totp.dart';
import 'src/authsignal_whatsapp.dart';
import 'src/authsignal_qr.dart';
import 'src/authsignal_inapp.dart';
import 'src/method_channel_authsignal_flutter.dart';

export 'package:authsignal_flutter_platform_interface/authsignal_flutter_platform_interface.dart'
    show
        AuthsignalResponse,
        TokenPayload,
        ErrorCode,
        AppCredential,
        AppChallenge,
        ClaimChallengeResponse,
        InAppVerifyResponse;

void _ensureMethodChannelImplementation() {
  if (!kIsWeb && AuthsignalFlutterPlatform.isDefaultInstance) {
    AuthsignalFlutterPlatform.instance = MethodChannelAuthsignalFlutter();
  }
}

class Authsignal {
  String tenantID;
  String baseURL;

  late AuthsignalPasskey passkey;
  late AuthsignalPush push;
  late AuthsignalEmail email;
  late AuthsignalSms sms;
  late AuthsignalTotp totp;
  late AuthsignalWhatsApp whatsapp;
  late AuthsignalQr qr;
  late AuthsignalInApp inapp;

  bool _initialized = false;

  Authsignal(
      {required this.tenantID,
      this.baseURL = "https://api.authsignal.com/v1"}) {
    _ensureMethodChannelImplementation();

    passkey = AuthsignalPasskey(initCheck: initCheck);
    push = AuthsignalPush(initCheck: initCheck);
    email = AuthsignalEmail(initCheck: initCheck);
    sms = AuthsignalSms(initCheck: initCheck);
    totp = AuthsignalTotp(initCheck: initCheck);
    whatsapp = AuthsignalWhatsApp(initCheck: initCheck);
    qr = AuthsignalQr(initCheck: initCheck);
    inapp = AuthsignalInApp(initCheck: initCheck);
  }

  Future<void> initCheck() async {
    if (!_initialized) {
      await AuthsignalFlutterPlatform.instance
          .initialize(tenantId: tenantID, baseUrl: baseURL);

      _initialized = true;
    }
  }

  Future<void> setToken(String token) async {
    await initCheck();
    await AuthsignalFlutterPlatform.instance.setToken(token);
  }
}
