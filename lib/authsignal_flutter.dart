import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/authsignal_passkey.dart';
import 'src/authsignal_push.dart';
import 'src/authsignal_email.dart';
import 'src/authsignal_sms.dart';
import 'src/authsignal_totp.dart';

export 'src/types.dart' show AuthsignalResponse, TokenPayload, ErrorCode;

class Authsignal {
  AuthsignalPasskey passkey;
  AuthsignalPush push;
  AuthsignalEmail email;
  AuthsignalSms sms;
  AuthsignalTotp totp;

  Authsignal({required String tenantID, String? baseURL})
      : passkey = AuthsignalPasskey(tenantID: tenantID, baseURL: baseURL),
        push = AuthsignalPush(tenantID: tenantID, baseURL: baseURL),
        email = AuthsignalEmail(tenantID: tenantID, baseURL: baseURL),
        sms = AuthsignalSms(tenantID: tenantID, baseURL: baseURL),
        totp = AuthsignalTotp(tenantID: tenantID, baseURL: baseURL);

  @visibleForTesting
  final methodChannel = const MethodChannel('authsignal');

  Future<void> setToken(String token) async {
    var arguments = <String, dynamic>{'token': token};

    await methodChannel.invokeMethod('setToken', arguments);
  }
}
