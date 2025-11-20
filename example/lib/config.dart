/// Authsignal configuration
/// Get your credentials from: https://portal.authsignal.com
class AuthsignalConfig {
  static const String tenantId = '87902a54-1902-47a6-b492-43acb0dca6d2';
  static const String baseUrl = 'https://api.authsignal.com/v1';

  static const String backendUrl = 'http://localhost:3000';

  static bool get isConfigured =>
      tenantId.isNotEmpty && tenantId != 'YOUR_TENANT_ID';
}
