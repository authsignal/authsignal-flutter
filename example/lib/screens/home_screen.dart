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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final List<String> _outputLog = [];
  bool _isInitialized = false;
  bool _backendHealthy = false;

  @override
  void initState() {
    super.initState();
    _userIdController.text = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _phoneController.text = '+1234567890';
    backendService = BackendService();
    _checkBackendHealth();
    _addOutput('App started. Please configure and initialize.');
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
      _outputLog.add('${DateTime.now().toIso8601String().substring(11, 19)}: $message');
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
              phoneController: _phoneController,
              onInitialize: _initializeAuthsignal,
            ),
            const SizedBox(height: 16),
            _buildDeviceCredentialsCard(),
            const SizedBox(height: 16),
            _buildOtherFeaturesCard(),
            const SizedBox(height: 16),
            OutputConsole(output: _outputLog.join('\n')),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCredentialsCard() {
    return FeatureCard(
      title: '🔐 Device Credentials (Trusted Device)',
      description: 'Secure device-based authentication using cryptographic keys',
      actions: [
        ElevatedButton.icon(
          onPressed: _isInitialized ? _getDeviceCredential : null,
          icon: const Icon(Icons.info, size: 18),
          label: const Text('Get Credential'),
        ),
        ElevatedButton.icon(
          onPressed: _isInitialized ? _addDeviceCredential : null,
          icon: const Icon(Icons.add_circle, size: 18),
          label: const Text('Add Credential'),
        ),
        ElevatedButton.icon(
          onPressed: _isInitialized ? _verifyDevice : null,
          icon: const Icon(Icons.verified_user, size: 18),
          label: const Text('Verify Device'),
        ),
        ElevatedButton.icon(
          onPressed: _isInitialized ? _removeDeviceCredential : null,
          icon: const Icon(Icons.remove_circle, size: 18),
          label: const Text('Remove'),
        ),
      ],
    );
  }


  Widget _buildOtherFeaturesCard() {
    return FeatureCard(
      title: '🔧 Other Features',
      description: 'Additional authentication methods (coming soon to this example)',
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
      ],
    );
  }

  // Device Credentials Methods

  Future<void> _getDeviceCredential() async {
    try {
      _addOutput('🔍 Getting device credential...');
      final result = await authsignal.device.getCredential();

      if (result.data != null) {
        _addOutput('✅ Device credential found!');
        _addOutput('   Credential ID: ${result.data!.credentialId}');
        _addOutput('   Created: ${result.data!.createdAt}');
        _addOutput('   User: ${result.data!.userId}');
      } else {
        _addOutput('ℹ️ No device credential found');
        _addOutput('   Add a credential first using "Add Credential"');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _addDeviceCredential() async {
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

      _addOutput('🔐 Adding device credential...');
      final result = await authsignal.device.addCredential(
        token: tokenResponse.token,
        deviceName: 'Flutter Example Device',
        userAuthenticationRequired: false,
      );

      if (result.data != null) {
        _addOutput('✅ Device credential added successfully!');
        _addOutput('   Credential ID: ${result.data!.credentialId}');
        _addOutput('   This device is now registered');
      } else {
        _addOutput('❌ Failed to add credential: ${result.error}');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _verifyDevice() async {
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

      _addOutput('🔐 Verifying device...');
      final result = await authsignal.device.verify();

      if (result.data != null) {
        _addOutput('✅ Device verification successful!');
        _addOutput('   Token: ${result.data!.token.substring(0, 20)}...');
        _addOutput('   User: ${result.data!.userId}');
        _addOutput('   Auth ID: ${result.data!.userAuthenticatorId}');
        _addOutput('🎉 Device authentication completed!');
      } else {
        _addOutput('❌ Verification failed: ${result.error}');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _removeDeviceCredential() async {
    try {
      _addOutput('🗑️ Removing device credential...');
      final result = await authsignal.device.removeCredential();

      if (result.data == true) {
        _addOutput('✅ Device credential removed successfully');
      } else {
        _addOutput('❌ Failed to remove credential: ${result.error}');
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

