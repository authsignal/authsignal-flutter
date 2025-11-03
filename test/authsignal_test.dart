import 'package:authsignal_flutter/authsignal_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('authsignal');

  Authsignal authsignal = Authsignal(tenantID: 'mock_tenant_id');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case "initialize":
            {
              return "";
            }

          case "passkey.signUp":
            {
              return <String, dynamic>{'token': 'result_token'};
            }

          case "push.getCredential":
            {
              return <String, dynamic>{
                'credentialId': 'test_push_credential_id',
                'createdAt': '2023-01-01T00:00:00Z',
                'userId': 'test_user_id',
                'lastAuthenticatedAt': '2023-01-02T00:00:00Z'
              };
            }

          case "push.addCredential":
            {
              return <String, dynamic>{
                'credentialId': 'new_push_credential_id',
                'createdAt': '2023-01-01T00:00:00Z',
                'userId': 'test_user_id',
                'lastAuthenticatedAt': null
              };
            }

          case "push.removeCredential":
            {
              return true;
            }

          case "push.getChallenge":
            {
              return <String, dynamic>{
                'challengeId': 'test_challenge_id',
                'actionCode': 'test_action',
                'idempotencyKey': 'test_key',
                'userAgent': 'test_agent',
                'deviceId': 'test_device',
                'ipAddress': '127.0.0.1'
              };
            }

          case "push.updateChallenge":
            {
              return true;
            }

          case "qr.getCredential":
            {
              return <String, dynamic>{
                'credentialId': 'test_credential_id',
                'createdAt': '2023-01-01T00:00:00Z',
                'userId': 'test_user_id',
                'lastAuthenticatedAt': '2023-01-02T00:00:00Z'
              };
            }

          case "qr.addCredential":
            {
              return <String, dynamic>{
                'credentialId': 'new_credential_id',
                'createdAt': '2023-01-01T00:00:00Z',
                'userId': 'test_user_id',
                'lastAuthenticatedAt': null
              };
            }

          case "qr.removeCredential":
            {
              return true;
            }

          case "qr.claimChallenge":
            {
              return <String, dynamic>{
                'success': true,
                'userAgent': 'test_agent',
                'ipAddress': '127.0.0.1'
              };
            }

          case "qr.updateChallenge":
            {
              return true;
            }

          case "inapp.getCredential":
            {
              return <String, dynamic>{
                'credentialId': 'test_inapp_credential_id',
                'createdAt': '2023-01-01T00:00:00Z',
                'userId': 'test_user_id',
                'lastAuthenticatedAt': '2023-01-02T00:00:00Z'
              };
            }

          case "inapp.addCredential":
            {
              return <String, dynamic>{
                'credentialId': 'new_inapp_credential_id',
                'createdAt': '2023-01-01T00:00:00Z',
                'userId': 'test_user_id',
                'lastAuthenticatedAt': null
              };
            }

          case "inapp.removeCredential":
            {
              return true;
            }

          case "inapp.verify":
            {
              return <String, dynamic>{
                'token': 'verify_token',
                'userId': 'test_user_id',
                'userAuthenticatorId': 'test_auth_id',
                'username': 'test_username'
              };
            }

          default:
            {
              throw Error();
            }
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('passkey.signUp', () async {
    final result = await authsignal.passkey
        .signUp(token: 'initial_token', username: 'bob');

    expect(result.data!.token, 'result_token');
  });

  test('push.getCredential', () async {
    final result = await authsignal.push.getCredential();

    expect(result.data!.credentialId, 'test_push_credential_id');
    expect(result.data!.userId, 'test_user_id');
    expect(result.data!.createdAt, '2023-01-01T00:00:00Z');
    expect(result.data!.lastAuthenticatedAt, '2023-01-02T00:00:00Z');
  });

  test('push.addCredential', () async {
    final result = await authsignal.push.addCredential(token: 'test_token');

    expect(result.data!.credentialId, 'new_push_credential_id');
    expect(result.data!.userId, 'test_user_id');
    expect(result.data!.createdAt, '2023-01-01T00:00:00Z');
    expect(result.data!.lastAuthenticatedAt, null);
  });

  test('push.removeCredential', () async {
    final result = await authsignal.push.removeCredential();

    expect(result.data, true);
  });

  test('push.getChallenge', () async {
    final result = await authsignal.push.getChallenge();

    expect(result.data!.challengeId, 'test_challenge_id');
    expect(result.data!.actionCode, 'test_action');
    expect(result.data!.idempotencyKey, 'test_key');
    expect(result.data!.userAgent, 'test_agent');
    expect(result.data!.deviceId, 'test_device');
    expect(result.data!.ipAddress, '127.0.0.1');
  });

  test('push.updateChallenge', () async {
    final result = await authsignal.push.updateChallenge(
      challengeId: 'test_challenge_id',
      approved: true,
    );

    expect(result.data, true);
  });

  test('qr.getCredential', () async {
    final result = await authsignal.qr.getCredential();

    expect(result.data!.credentialId, 'test_credential_id');
    expect(result.data!.userId, 'test_user_id');
    expect(result.data!.createdAt, '2023-01-01T00:00:00Z');
    expect(result.data!.lastAuthenticatedAt, '2023-01-02T00:00:00Z');
  });

  test('qr.addCredential', () async {
    final result = await authsignal.qr.addCredential(token: 'test_token');

    expect(result.data!.credentialId, 'new_credential_id');
    expect(result.data!.userId, 'test_user_id');
    expect(result.data!.createdAt, '2023-01-01T00:00:00Z');
    expect(result.data!.lastAuthenticatedAt, null);
  });

  test('qr.removeCredential', () async {
    final result = await authsignal.qr.removeCredential();

    expect(result.data, true);
  });

  test('qr.claimChallenge', () async {
    final result = await authsignal.qr.claimChallenge('test_challenge_id');

    expect(result.data!.success, true);
    expect(result.data!.userAgent, 'test_agent');
    expect(result.data!.ipAddress, '127.0.0.1');
  });

  test('qr.updateChallenge', () async {
    final result = await authsignal.qr.updateChallenge(
      challengeId: 'test_challenge_id',
      approved: true,
    );

    expect(result.data, true);
  });

  test('inapp.getCredential', () async {
    final result = await authsignal.inapp.getCredential();

    expect(result.data!.credentialId, 'test_inapp_credential_id');
    expect(result.data!.userId, 'test_user_id');
    expect(result.data!.createdAt, '2023-01-01T00:00:00Z');
    expect(result.data!.lastAuthenticatedAt, '2023-01-02T00:00:00Z');
  });

  test('inapp.addCredential', () async {
    final result = await authsignal.inapp.addCredential(token: 'test_token');

    expect(result.data!.credentialId, 'new_inapp_credential_id');
    expect(result.data!.userId, 'test_user_id');
    expect(result.data!.createdAt, '2023-01-01T00:00:00Z');
    expect(result.data!.lastAuthenticatedAt, null);
  });

  test('inapp.removeCredential', () async {
    final result = await authsignal.inapp.removeCredential();

    expect(result.data, true);
  });

  test('inapp.verify', () async {
    final result = await authsignal.inapp.verify();

    expect(result.data!.token, 'verify_token');
    expect(result.data!.userId, 'test_user_id');
    expect(result.data!.userAuthenticatorId, 'test_auth_id');
    expect(result.data!.username, 'test_username');
  });
}
