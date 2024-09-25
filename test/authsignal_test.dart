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
          case "passkey.initialize":
            {
              return "";
            }

          case "passkey.signUp":
            {
              return <String, dynamic>{'token': 'result_token'};
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
}
