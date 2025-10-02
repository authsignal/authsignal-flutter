# Authsignal Flutter SDK - Example App

Example app showing how to integrate Authsignal Flutter SDK with Device Credentials and WhatsApp OTP.

## Quick Start

### 1. Prerequisites

- Flutter SDK (>=3.3.0)
- iOS Simulator or Android Emulator
- Node.js (for the backend test server)
- An Authsignal account with Tenant ID and API Secret

### 2. Configure Your Credentials

Create a `.env` file in the example directory (or modify `lib/config.dart`):

```dart
class AuthsignalConfig {
  static const String tenantId = 'YOUR_TENANT_ID';
  static const String baseUrl = 'https://api.authsignal.com/v1';
  static const String backendUrl = 'http://localhost:3000'; // Your backend
}
```

### 3. Set Up Backend Server

The example requires a backend server to generate tokens (as tokens should never be generated client-side in production).

```bash
cd backend
npm install
```

Update `backend/.env`:
```
AUTHSIGNAL_SECRET=your_secret_key
AUTHSIGNAL_TENANT_ID=your_tenant_id
AUTHSIGNAL_BASE_URL=https://api.authsignal.com/v1
PORT=3000
```

Start the server:
```bash
npm start
```

### 4. Run the Example App

```bash
cd example
flutter pub get
flutter run
```

## Learn More

- [Authsignal Documentation](https://docs.authsignal.com)
- [Flutter SDK Reference](https://docs.authsignal.com/sdks/client/flutter)
- [API Reference](https://docs.authsignal.com/api)

