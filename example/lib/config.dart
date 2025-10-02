/// Authsignal configuration
/// Get your credentials from: https://portal.authsignal.com
class AuthsignalConfig {
  static const String tenantId = 'YOUR_AUTHSIGNAL_TENANT_ID';
  static const String baseUrl = 'https://api.authsignal.com/v1';
  
  static const String backendUrl = 'http://localhost:3000';

  static bool get isConfigured => tenantId != 'YOUR_AUTHSIGNAL_TENANT_ID';
}

