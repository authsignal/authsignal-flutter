import 'package:authsignal_flutter/authsignal_flutter.dart';
import 'package:authsignal_flutter_platform_interface/authsignal_flutter_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAuthsignalPlatform extends AuthsignalFlutterPlatform {
  bool initializeCalled = false;
  String? lastTenantId;
  String? lastBaseUrl;
  String? lastToken;
  bool enrollCalled = false;
  bool challengeCalled = false;
  bool verifyCalled = false;

  @override
  Future<void> initialize(
      {required String tenantId, required String baseUrl}) async {
    initializeCalled = true;
    lastTenantId = tenantId;
    lastBaseUrl = baseUrl;
  }

  @override
  Future<void> setToken(String token) async {
    lastToken = token;
  }

  @override
  Future<AuthsignalResponse<EnrollResponse>> emailEnroll(String email) async {
    enrollCalled = true;
    return AuthsignalResponse(
      data:
          EnrollResponse.fromMap({'userAuthenticatorId': 'mock-authenticator'}),
    );
  }

  @override
  Future<AuthsignalResponse<ChallengeResponse>> emailChallenge() async {
    challengeCalled = true;
    return AuthsignalResponse(
      data: ChallengeResponse.fromMap({'challengeId': 'mock-challenge'}),
    );
  }

  @override
  Future<AuthsignalResponse<VerifyResponse>> emailVerify(String code) async {
    verifyCalled = true;
    return AuthsignalResponse(
      data: VerifyResponse.fromMap({
        'isVerified': true,
        'token': 'mock-token',
        'failureReason': null,
      }),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Authsignal delegates email methods through the platform interface',
      () async {
    final mockPlatform = _MockAuthsignalPlatform();
    AuthsignalFlutterPlatform.instance = mockPlatform;

    final authsignal =
        Authsignal(tenantID: 'tenant', baseURL: 'https://example');

    final enroll = await authsignal.email.enroll('test@example.com');
    final challenge = await authsignal.email.challenge();
    final verify = await authsignal.email.verify('123456');

    expect(mockPlatform.initializeCalled, isTrue);
    expect(mockPlatform.lastTenantId, 'tenant');
    expect(mockPlatform.lastBaseUrl, 'https://example');
    expect(mockPlatform.enrollCalled, isTrue);
    expect(mockPlatform.challengeCalled, isTrue);
    expect(mockPlatform.verifyCalled, isTrue);
    expect(enroll.data!.userAuthenticatorId, 'mock-authenticator');
    expect(challenge.data!.challengeId, 'mock-challenge');
    expect(verify.data!.isVerified, isTrue);
  });

  test('setToken awaits init before delegating to platform interface',
      () async {
    final mockPlatform = _MockAuthsignalPlatform();
    AuthsignalFlutterPlatform.instance = mockPlatform;

    final authsignal =
        Authsignal(tenantID: 'tenant', baseURL: 'https://example');
    await authsignal.setToken('test-token');

    expect(mockPlatform.initializeCalled, isTrue);
    expect(mockPlatform.lastToken, 'test-token');
  });
}
