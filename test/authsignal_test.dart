import 'package:authsignal_flutter/authsignal_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('authsignal');

  Authsignal authsignal = Authsignal(tenantID: 'mock_tenant_id');
  late List<MethodCall> methodCalls;

  setUp(() {
    methodCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        methodCalls.add(methodCall);

        switch (methodCall.method) {
          case "initialize":
            {
              return "";
            }

          case "passkey.signUp":
            {
              return <String, dynamic>{'token': 'result_token'};
            }

          case "passkey.signIn":
            {
              return <String, dynamic>{
                'isVerified': true,
                'token': 'sign_in_token',
                'userId': 'test_user_id',
                'userAuthenticatorId': 'test_authenticator_id',
                'username': 'test_username',
                'displayName': 'Test User',
              };
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

          case "inapp.createPin":
            {
              return <String, dynamic>{
                'credentialId': 'pin_credential_id',
                'createdAt': '2023-01-01T00:00:00Z',
                'userId': 'test_user_id',
                'lastAuthenticatedAt': null
              };
            }

          case "inapp.verifyPin":
            {
              return <String, dynamic>{
                'isVerified': true,
                'token': 'pin_verify_token',
                'userId': 'test_user_id',
              };
            }

          case "inapp.deletePin":
            {
              return true;
            }

          case "inapp.getAllPinUsernames":
            {
              return <String>['alice', 'bob'];
            }

          case "getDeviceId":
            {
              return 'mock-device-id';
            }

          case "passkey.shouldPromptToCreatePasskey":
            {
              return true;
            }

          case "passkey.isSupported":
            {
              return true;
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

  test('passkey.signUp forwards syncCredentials', () async {
    await authsignal.passkey.signUp(
      token: 'initial_token',
      username: 'bob',
      syncCredentials: false,
    );

    final call =
        methodCalls.lastWhere((call) => call.method == 'passkey.signUp');
    final arguments = call.arguments as Map<Object?, Object?>;

    expect(arguments['syncCredentials'], false);
  });

  test('passkey.signIn forwards syncCredentials', () async {
    await authsignal.passkey.signIn(
      token: 'initial_token',
      syncCredentials: false,
    );

    final call =
        methodCalls.lastWhere((call) => call.method == 'passkey.signIn');
    final arguments = call.arguments as Map<Object?, Object?>;

    expect(arguments['syncCredentials'], false);
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

  test('inapp.createPin', () async {
    final result = await authsignal.inapp.createPin(
      pin: '1234',
      username: 'alice',
      token: 'tok',
    );

    expect(result.data!.credentialId, 'pin_credential_id');
    expect(result.data!.userId, 'test_user_id');
  });

  test('inapp.verifyPin', () async {
    final result = await authsignal.inapp.verifyPin(
      pin: '1234',
      username: 'alice',
    );

    expect(result.data!.isVerified, true);
    expect(result.data!.token, 'pin_verify_token');
    expect(result.data!.userId, 'test_user_id');
  });

  test('inapp.deletePin', () async {
    final result = await authsignal.inapp.deletePin(username: 'alice');

    expect(result.data, true);
  });

  test('inapp.getAllPinUsernames', () async {
    final result = await authsignal.inapp.getAllPinUsernames();

    expect(result.data, <String>['alice', 'bob']);
  });

  test('getDeviceId', () async {
    final deviceId = await authsignal.getDeviceId();

    expect(deviceId, 'mock-device-id');
  });

  test('passkey.shouldPromptToCreatePasskey', () async {
    final result = await authsignal.passkey.shouldPromptToCreatePasskey(
      username: 'alice',
    );

    expect(result.data, true);
  });

  test('passkey.isSupported', () async {
    final result = await authsignal.passkey.isSupported();

    expect(result, true);
  });
}
