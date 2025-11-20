import 'package:flutter/material.dart';
import 'package:authsignal_flutter/authsignal_flutter.dart';
import '../config.dart';
import '../services/backend_service.dart';
import '../widgets/output_console.dart';
import '../widgets/config_card.dart';
import '../widgets/feature_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Authsignal authsignal;
  late BackendService backendService;

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailCodeController = TextEditingController();

  final List<String> _outputLog = [];
  bool _isInitialized = false;
  bool _backendHealthy = false;

  @override
  void initState() {
    super.initState();
    _userIdController.text = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _emailController.text = '${_userIdController.text}@example.com';
    _phoneController.text = '+1234567890';
    backendService = BackendService();
    _checkBackendHealth();
    _addOutput('App started. Please configure and initialize.');
  }

  // Passkey Methods

  Future<void> _registerPasskey() async {
    final email = _emailController.text.trim();
    final userId = _userIdController.text.trim();

    try {
      _addOutput('🔑 Requesting registration token for passkey...');
      final tokenResponse = await backendService.getRegistrationToken(userId);

      if (tokenResponse == null) {
        _addOutput('❌ Failed to get registration token');
        return;
      }

      _addOutput('✅ Token received (${tokenResponse.state ?? 'ALLOW'})');
      await authsignal.setToken(tokenResponse.token);

      final response = await authsignal.passkey.signUp(
        token: tokenResponse.token,
        username: email.isEmpty ? null : email,
        displayName: userId.isEmpty ? null : userId,
      );

      if (response.error != null) {
        _addOutput('❌ Passkey registration failed: ${response.error}');
        return;
      }

      _addOutput('✅ Passkey registered successfully!');
      if (response.data?.token != null) {
        _addOutput('   Token: ${response.data!.token!.substring(0, 20)}...');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _signInWithPasskey() async {
    try {
      _addOutput('🔐 Launching passkey sign-in prompt...');
      final response = await authsignal.passkey.signIn(
        action: 'signInWithPasskey',
      );

      if (response.error != null) {
        _addOutput('❌ Passkey sign-in failed: ${response.error}');
        return;
      }

      if (response.data?.isVerified == true) {
        _addOutput('✅ Passkey authentication successful!');

        final token = response.data?.token;
        if (token != null) {
          _addOutput('   Token: ${token.substring(0, 20)}...');
          final validation = await backendService.validateToken(token);
          if (validation?.isValid == true) {
            _addOutput('   Server validation: ✅ ${validation!.state}');
          } else {
            _addOutput('   Server validation failed or unavailable.');
          }
        }
      } else {
        _addOutput('⚠️ Passkey response received but not verified.');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  // Email OTP Methods

  Future<void> _sendEmailEnroll() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _addOutput('⚠️ Enter an email address to enroll.');
      return;
    }

    try {
      _addOutput('📝 Requesting registration token from backend...');
      final tokenResponse = await backendService.getRegistrationToken(
        _userIdController.text,
      );

      if (tokenResponse == null) {
        _addOutput('❌ Failed to get registration token');
        _addOutput('   Check backend connection');
        return;
      }

      _addOutput('✅ Token received (${tokenResponse.state})');
      await authsignal.setToken(tokenResponse.token);

      _addOutput('✉️ Requesting enrollment OTP for $email...');
      final response = await authsignal.email.enroll(email);

      if (response.error != null) {
        _addOutput('❌ Failed to enroll email: ${response.error}');
        return;
      }

      final authId = response.data?.userAuthenticatorId;
      _addOutput('✅ Enrollment email sent to $email');
      if (authId != null) {
        _addOutput('   Authenticator ID: $authId');
      }
      _addOutput('   Enter the received code and tap "Verify Code".');
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _sendEmailChallenge() async {
    try {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _addOutput('⚠️ Enter an email address.');
        return;
      }

      _addOutput('📝 Getting challenge token from backend...');
      final tokenResponse = await backendService.getChallengeToken(
        userId: _userIdController.text,
        email: email,
      );

      if (tokenResponse == null) {
        _addOutput('❌ Failed to get challenge token');
        return;
      }

      _addOutput('✅ Challenge token received (${tokenResponse.state})');
      await authsignal.setToken(tokenResponse.token);

      _addOutput('✉️ Sending challenge email to $email...');
      final response = await authsignal.email.challenge();

      if (response.error != null) {
        _addOutput('❌ Failed to send challenge email: ${response.error}');
        return;
      }

      final challengeId = response.data?.challengeId;
      if (challengeId != null) {
        _addOutput('✅ Challenge created (ID: $challengeId). Check your inbox.');
      } else {
        _addOutput('✅ Challenge initiated. Check your inbox for the code.');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _verifyEmailOtp() async {
    final code = _emailCodeController.text.trim();
    if (code.isEmpty) {
      _addOutput('⚠️ Enter the email OTP code before verifying.');
      return;
    }

    try {
      _addOutput('🔍 Verifying email OTP...');
      final response = await authsignal.email.verify(code);

      if (response.error != null) {
        _addOutput('❌ Verification failed: ${response.error}');
        return;
      }

      if (response.data?.isVerified == true) {
        _addOutput('✅ Email OTP verified successfully!');
        if (response.data?.token != null) {
          _addOutput('   Token: ${response.data!.token!.substring(0, 20)}...');
        }
      } else {
        _addOutput(
            '⚠️ Verification response received but not marked verified.');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _checkBackendHealth() async {
    final isHealthy = await backendService.checkHealth();
    setState(() {
      _backendHealthy = isHealthy;
    });
    if (!isHealthy) {
      _addOutput('⚠️ Backend not reachable at ${AuthsignalConfig.backendUrl}');
      _addOutput('Start the backend server to enable full functionality');
    }
  }

  void _initializeAuthsignal() {
    if (!AuthsignalConfig.isConfigured) {
      _showConfigurationDialog();
      return;
    }

    try {
      authsignal = Authsignal(
        tenantID: AuthsignalConfig.tenantId,
        baseURL: AuthsignalConfig.baseUrl,
      );
      setState(() {
        _isInitialized = true;
      });
      _addOutput('✅ Authsignal SDK initialized successfully!');
    } catch (e) {
      _addOutput('❌ Error initializing SDK: $e');
    }
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration Required'),
        content: const Text(
          'Please update lib/config.dart with your Authsignal credentials.\n\n'
          'You can find your Tenant ID in the Authsignal Portal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addOutput(String message) {
    setState(() {
      _outputLog.add(
          '${DateTime.now().toIso8601String().substring(11, 19)}: $message');
    });
  }

  void _clearOutput() {
    setState(() {
      _outputLog.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Authsignal Flutter Example'),
        actions: [
          IconButton(
            onPressed: _clearOutput,
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Output',
          ),
          IconButton(
            onPressed: _checkBackendHealth,
            icon: Icon(
              Icons.sync,
              color: _backendHealthy ? Colors.green : Colors.red,
            ),
            tooltip: 'Check Backend Status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConfigCard(
              isInitialized: _isInitialized,
              isConfigured: AuthsignalConfig.isConfigured,
              backendHealthy: _backendHealthy,
              userIdController: _userIdController,
              emailController: _emailController,
              phoneController: _phoneController,
              onInitialize: _initializeAuthsignal,
            ),
            const SizedBox(height: 16),
            _buildInAppAuthCard(),
            const SizedBox(height: 16),
            _buildPasskeySection(),
            const SizedBox(height: 16),
            _buildEmailOtpSection(),
            const SizedBox(height: 16),
            _buildWhatsAppSection(),
            const SizedBox(height: 16),
            _buildOtherFeaturesCard(),
            const SizedBox(height: 16),
            OutputConsole(output: _outputLog.join('\n')),
          ],
        ),
      ),
    );
  }

  Widget _buildInAppAuthCard() {
    return FeatureCard(
      title: '🔐 In-App Verification (mobile)',
      description:
          'Secure device-based authentication using cryptographic keys stored on this device',
      actions: [
        ElevatedButton.icon(
          onPressed: _isInitialized ? _getInAppCredential : null,
          icon: const Icon(Icons.info, size: 18),
          label: const Text('Get Credential'),
        ),
        ElevatedButton.icon(
          onPressed: _isInitialized ? _addInAppCredential : null,
          icon: const Icon(Icons.add_circle, size: 18),
          label: const Text('Add Credential'),
        ),
        ElevatedButton.icon(
          onPressed: _isInitialized ? _verifyInApp : null,
          icon: const Icon(Icons.verified_user, size: 18),
          label: const Text('Verify Device'),
        ),
        ElevatedButton.icon(
          onPressed: _isInitialized ? _removeInAppCredential : null,
          icon: const Icon(Icons.remove_circle, size: 18),
          label: const Text('Remove'),
        ),
      ],
    );
  }

  Widget _buildPasskeySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔑 Passkeys (web + mobile)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Demonstrates Authsignal passkey enrollment and sign-in using the Browser SDK.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isInitialized ? _registerPasskey : null,
                  icon: const Icon(Icons.add_moderator, size: 18),
                  label: const Text('Register Passkey'),
                ),
                ElevatedButton.icon(
                  onPressed: _isInitialized ? _signInWithPasskey : null,
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Sign In with Passkey'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Requires a short-lived token from the backend (/api/registration-token) '
              'and can be used on both mobile and Flutter web.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailOtpSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✉️ Email OTP (web + mobile)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Demonstrates the new federated web implementation (enroll, challenge, verify).',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCodeController,
              decoration: const InputDecoration(
                labelText: 'Email OTP Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.password),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isInitialized ? _sendEmailEnroll : null,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Enroll Email'),
                ),
                ElevatedButton.icon(
                  onPressed: _isInitialized ? _sendEmailChallenge : null,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Challenge Email'),
                ),
                ElevatedButton.icon(
                  onPressed: _isInitialized ? _verifyEmailOtp : null,
                  icon: const Icon(Icons.verified, size: 18),
                  label: const Text('Verify Code'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📱 WhatsApp OTP (mobile)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Send and verify one-time passwords via WhatsApp',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'OTP Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.password),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isInitialized ? _sendWhatsAppOTP : null,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send OTP'),
                ),
                ElevatedButton.icon(
                  onPressed: _isInitialized && _otpController.text.isNotEmpty
                      ? _verifyWhatsAppOTP
                      : null,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Verify OTP'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherFeaturesCard() {
    return FeatureCard(
      title: '🔧 Other Features',
      description: 'Additional authentication methods available in the SDK',
      actions: [
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.email, size: 18),
          label: const Text('Email OTP'),
        ),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.sms, size: 18),
          label: const Text('SMS OTP'),
        ),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.fingerprint, size: 18),
          label: const Text('Passkeys'),
        ),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.qr_code, size: 18),
          label: const Text('TOTP'),
        ),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.qr_code_scanner, size: 18),
          label: const Text('QR Code Auth'),
        ),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.notifications, size: 18),
          label: const Text('Push Auth'),
        ),
      ],
    );
  }

  // In-App Verification (Trusted Device) Methods

  Future<void> _getInAppCredential() async {
    try {
      _addOutput('🔍 Getting trusted device credential...');
      final result = await authsignal.inapp.getCredential();

      if (result.data != null) {
        _addOutput('✅ Trusted device credential found!');
        _addOutput('   Credential ID: ${result.data!.credentialId}');
        _addOutput('   Created: ${result.data!.createdAt}');
        _addOutput('   User: ${result.data!.userId}');
      } else {
        _addOutput('ℹ️ No device credential found');
        _addOutput('   This device is not yet registered as trusted');
        _addOutput('   Add a credential first using "Add Credential"');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _addInAppCredential() async {
    try {
      _addOutput('📝 Requesting registration token from backend...');
      final tokenResponse = await backendService.getRegistrationToken(
        _userIdController.text,
      );

      if (tokenResponse == null) {
        _addOutput('❌ Failed to get registration token');
        _addOutput('   Check backend connection');
        return;
      }

      _addOutput('✅ Token received (${tokenResponse.state})');
      await authsignal.setToken(tokenResponse.token);

      _addOutput('🔐 Registering this device as trusted...');
      final result =
          await authsignal.inapp.addCredential(token: tokenResponse.token);

      if (result.data != null) {
        _addOutput('✅ Trusted device credential added!');
        _addOutput('   Credential ID: ${result.data!.credentialId}');
        _addOutput('   User ID: ${result.data!.userId}');
        _addOutput('   This device is now registered as trusted');
      } else {
        _addOutput('❌ Failed to add credential: ${result.error}');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _verifyInApp() async {
    try {
      _addOutput('📝 Getting challenge token from backend...');
      final tokenResponse = await backendService.getChallengeToken(
        userId: _userIdController.text,
        phoneNumber: _phoneController.text,
      );

      if (tokenResponse == null) {
        _addOutput('❌ Failed to get challenge token');
        return;
      }

      _addOutput('✅ Challenge token received (${tokenResponse.state})');
      await authsignal.setToken(tokenResponse.token);

      _addOutput('🔐 Verifying this trusted device...');
      final result = await authsignal.inapp.verify();

      if (result.data != null) {
        _addOutput('✅ Device verification successful!');
        _addOutput('   Token: ${result.data!.token.substring(0, 20)}...');
        _addOutput('   User: ${result.data!.userId}');
        _addOutput('   Auth ID: ${result.data!.userAuthenticatorId}');
        _addOutput('🎉 Trusted device authentication completed!');
      } else {
        _addOutput('❌ Verification failed: ${result.error}');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _removeInAppCredential() async {
    try {
      _addOutput('🗑️ Removing trusted device credential...');
      final result = await authsignal.inapp.removeCredential();

      if (result.data == true) {
        _addOutput('✅ Device credential removed successfully');
        _addOutput('   This device is no longer trusted');
      } else {
        _addOutput('❌ Failed to remove credential: ${result.error}');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  // WhatsApp Methods

  Future<void> _sendWhatsAppOTP() async {
    try {
      _addOutput('📝 Getting challenge token from backend...');
      final tokenResponse = await backendService.getChallengeToken(
        userId: _userIdController.text,
        phoneNumber: _phoneController.text,
      );

      if (tokenResponse == null) {
        _addOutput('❌ Failed to get challenge token');
        return;
      }

      await authsignal.setToken(tokenResponse.token);
      _addOutput('📱 Sending WhatsApp OTP...');

      final result = await authsignal.whatsapp.challenge();

      if (result.data != null) {
        _addOutput('✅ WhatsApp OTP sent!');
        _addOutput('   Challenge ID: ${result.data!.challengeId}');
        _addOutput('   Check WhatsApp on ${_phoneController.text}');
      } else {
        _addOutput('❌ Failed to send OTP: ${result.error}');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _verifyWhatsAppOTP() async {
    try {
      _addOutput('🔍 Verifying WhatsApp OTP: ${_otpController.text}');
      final result = await authsignal.whatsapp.verify(_otpController.text);

      if (result.data != null) {
        if (result.data!.isVerified) {
          _addOutput('✅ WhatsApp OTP verified successfully!');
          _addOutput('   Token: ${result.data!.token?.substring(0, 20)}...');
          _addOutput('🎉 Authentication completed!');
        } else {
          _addOutput('❌ OTP verification failed');
          _addOutput(
              '   Reason: ${result.data!.failureReason ?? "Invalid code"}');
        }
      } else {
        _addOutput('❌ Verification error: ${result.error}');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
