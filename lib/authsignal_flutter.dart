import 'src/authsignal_passkey.dart';
import 'src/authsignal_push.dart';

export 'src/types.dart' show AuthsignalResponse, TokenPayload, ErrorCode;

class Authsignal {
  AuthsignalPasskey passkey;
  AuthsignalPush push;

  Authsignal(tenantID, {String? baseURL})
      : passkey = AuthsignalPasskey(tenantID, baseURL: baseURL),
        push = AuthsignalPush(tenantID, baseURL: baseURL);
}
