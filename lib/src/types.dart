class AuthsignalResponse<T> {
  T? data;
  String? error;
  String? errorCode;
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

class SignUpResponse {
  final String? token;

  SignUpResponse({required this.token});

  factory SignUpResponse.fromMap(Map<String, dynamic> map) {
    return SignUpResponse(token: map['token']);
  }
}

class SignInResponse {
  final bool isVerified;
  final String? token;
  final String? userId;
  final String? userAuthenticatorId;
  final String? username;
  final String? displayName;

  SignInResponse({
    required this.isVerified,
    required this.token,
    required this.userId,
    required this.userAuthenticatorId,
    required this.username,
    required this.displayName,
  });

  factory SignInResponse.fromMap(Map<String, dynamic> map) {
    return SignInResponse(
      isVerified: map['isVerified'],
      token: map['token'],
      userId: map['userId'],
      userAuthenticatorId: map['userAuthenticatorId'],
      username: map['username'],
      displayName: map['displayName'],
    );
  }
}

class PushCredential {
  final String credentialId;
  String createdAt;
  String? lastAuthenticatedAt;

  PushCredential({
    required this.credentialId,
    required this.createdAt,
    required this.lastAuthenticatedAt,
  });

  factory PushCredential.fromMap(Map<String, dynamic> map) {
    return PushCredential(
      credentialId: map['credentialId'],
      createdAt: map['createdAt'],
      lastAuthenticatedAt: map['lastAuthenticatedAt'],
    );
  }
}

class PushChallenge {
  final String challengeId;
  final String? actionCode;
  final String? idempotencyKey;
  final String? userAgent;
  final String? deviceId;
  final String? ipAddress;

  PushChallenge({
    required this.challengeId,
    required this.actionCode,
    required this.idempotencyKey,
    required this.userAgent,
    required this.deviceId,
    required this.ipAddress,
  });

  factory PushChallenge.fromMap(Map<String, dynamic> map) {
    return PushChallenge(
      challengeId: map['challengeId'],
      actionCode: map['actionCode'],
      idempotencyKey: map['idempotencyKey'],
      userAgent: map['userAgent'],
      deviceId: map['deviceId'],
      ipAddress: map['ipAddress'],
    );
  }
}
