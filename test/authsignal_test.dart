import 'package:authsignal_flutter/authsignal_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('authsignal');

  Authsignal authsignal = Authsignal('mock_tenant_id');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return 'mock_result';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('passkey.signUp', () async {
    final result =
        await authsignal.passkey.signUp('initial_token', userName: 'bob');

    expect(result.data, 'mock_result');
  });

  test('push.getCredential', () async {
    final result = await authsignal.push.getCredential();

    expect(result.data, 'mock_result');
  });
}
