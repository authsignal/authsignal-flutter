class AuthsignalResponse<T> {
  T? data;
  String? error;
}

class TokenPayload {
  String? aud;
  String? sub;
  int? exp;
  int? iat;
  String? scope;
  TokenPayloadOther? other;
}

class TokenPayloadOther {
  String? actionCode;
  String? idempotencyKey;
  String? publishableKey;
  String? tenantId;
  String? userId;
  String? username;
}
