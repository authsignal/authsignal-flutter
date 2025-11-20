import 'package:flutter/material.dart';

class ConfigCard extends StatelessWidget {
  final bool isInitialized;
  final bool isConfigured;
  final bool backendHealthy;
  final TextEditingController userIdController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final VoidCallback onInitialize;

  const ConfigCard({
    super.key,
    required this.isInitialized,
    required this.isConfigured,
    required this.backendHealthy,
    required this.userIdController,
    required this.emailController,
    required this.phoneController,
    required this.onInitialize,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!isConfigured)
                  Chip(
                    label: const Text(
                      'Not Configured',
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.orange[100],
                    avatar: const Icon(Icons.warning, size: 16),
                  ),
                if (isConfigured && !backendHealthy)
                  Chip(
                    label: const Text(
                      'Backend Offline',
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.red[100],
                    avatar: const Icon(Icons.cloud_off, size: 16),
                  ),
                if (isConfigured && backendHealthy)
                  Chip(
                    label: const Text(
                      'Ready',
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.green[100],
                    avatar: const Icon(Icons.check_circle, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                helperText: 'Unique identifier for the user',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                helperText: 'Used for Email OTP demos',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (for OTP)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                helperText: 'E.164 format: +1234567890',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isInitialized ? null : onInitialize,
                icon: Icon(isInitialized ? Icons.check : Icons.play_arrow),
                label: Text(
                  isInitialized ? 'SDK Initialized' : 'Initialize SDK',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            if (!isConfigured) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Update lib/config.dart with your credentials',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
