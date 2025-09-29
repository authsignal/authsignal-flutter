import 'package:authsignal_flutter/authsignal_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('authsignal');

  Authsignal authsignal = Authsignal(tenantID: 'mock_tenant_id');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
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

          case "device.getCredential":
            {
              return <String, dynamic>{
                'credentialId': 'test_credential_id',
                'createdAt': '2023-01-01T00:00:00Z',
                'userId': 'test_user_id',
                'lastAuthenticatedAt': '2023-01-02T00:00:00Z'
              };
            }

          case "device.addCredential":
            {
              return <String, dynamic>{
                'credentialId': 'new_credential_id',
                'createdAt': '2023-01-01T00:00:00Z',
                'userId': 'test_user_id',
                'lastAuthenticatedAt': null
              };
            }

          case "device.removeCredential":
            {
              return true;
            }

          case "device.getChallenge":
            {
              return <String, dynamic>{
                'challengeId': 'test_challenge_id',
                'userId': 'test_user_id',
                'actionCode': 'test_action',
                'idempotencyKey': 'test_key',
                'deviceId': 'test_device_id',
                'userAgent': 'test_agent',
                'ipAddress': '127.0.0.1'
              };
            }

          case "device.claimChallenge":
            {
              return <String, dynamic>{
                'success': true,
                'userAgent': 'test_agent',
                'ipAddress': '127.0.0.1'
              };
            }

          case "device.updateChallenge":
            {
              return true;
            }

          case "device.verify":
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('passkey.signUp', () async {
    final result = await authsignal.passkey.signUp(token: 'initial_token', username: 'bob');

    expect(result.data!.token, 'result_token');
  });

  test('device.getCredential', () async {
    final result = await authsignal.device.getCredential();

    expect(result.data!.credentialId, 'test_credential_id');
    expect(result.data!.userId, 'test_user_id');
    expect(result.data!.createdAt, '2023-01-01T00:00:00Z');
    expect(result.data!.lastAuthenticatedAt, '2023-01-02T00:00:00Z');
  });

  test('device.addCredential', () async {
    final result = await authsignal.device.addCredential(token: 'test_token');

    expect(result.data!.credentialId, 'new_credential_id');
    expect(result.data!.userId, 'test_user_id');
    expect(result.data!.createdAt, '2023-01-01T00:00:00Z');
    expect(result.data!.lastAuthenticatedAt, null);
  });

  test('device.removeCredential', () async {
    final result = await authsignal.device.removeCredential();

    expect(result.data, true);
  });

  test('device.getChallenge', () async {
    final result = await authsignal.device.getChallenge();

    expect(result.data!.challengeId, 'test_challenge_id');
    expect(result.data!.userId, 'test_user_id');
    expect(result.data!.actionCode, 'test_action');
    expect(result.data!.idempotencyKey, 'test_key');
    expect(result.data!.deviceId, 'test_device_id');
    expect(result.data!.userAgent, 'test_agent');
    expect(result.data!.ipAddress, '127.0.0.1');
  });

  test('device.claimChallenge', () async {
    final result = await authsignal.device.claimChallenge('test_challenge_id');

    expect(result.data!.success, true);
    expect(result.data!.userAgent, 'test_agent');
    expect(result.data!.ipAddress, '127.0.0.1');
  });

  test('device.updateChallenge', () async {
    final result = await authsignal.device.updateChallenge(
      'test_challenge_id',
      true,
    );

    expect(result.data, true);
  });

  test('device.verify', () async {
    final result = await authsignal.device.verify();

    expect(result.data!.token, 'verify_token');
    expect(result.data!.userId, 'test_user_id');
    expect(result.data!.userAuthenticatorId, 'test_auth_id');
    expect(result.data!.username, 'test_username');
  });
}
