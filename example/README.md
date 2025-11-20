# Authsignal Flutter SDK - Example App

Example app showing how to integrate Authsignal Flutter SDK with Device Credentials and WhatsApp OTP.

## Quick start

### 1. Prerequisites

- Flutter SDK (>=3.3.0)
- iOS simulator or Android emulator
- Node.js (for the backend test server)
- An Authsignal account with tenant ID and API secret

### 2. Configure your credentials

Create a `.env` file in the example directory (or modify `lib/config.dart`):

```dart
class AuthsignalConfig {
  static const String tenantId = 'YOUR_TENANT_ID';
  static const String baseUrl = 'https://api.authsignal.com/v1';
  static const String backendUrl = 'http://localhost:3000'; // Your backend
}
```

### 3. Set up backend server

The example requires a backend server to generate tokens. This server uses the Authsignal Node.js SDK (v2.12.0).

⚠️ **Security:** Only use an API secret key from a non-production tenant when running this server.

```bash
cd backend
npm install
```

Copy and update the environment file:
```bash
cp .env.example .env
```

Then edit `backend/.env`:
```env
AUTHSIGNAL_SECRET=your_secret_key
AUTHSIGNAL_TENANT_ID=your_tenant_id
AUTHSIGNAL_BASE_URL=https://api.authsignal.com/v1
PORT=3000
```

Start the server:
```bash
npm start
# Or for development with auto-reload:
npm run dev
```

📖 See [backend/README.md](backend/README.md) for detailed backend documentation, API endpoints, and troubleshooting.

### 4. Run the example app

```bash
cd example
flutter pub get
flutter run
```

## Learn more

- [Authsignal documentation](https://docs.authsignal.com)
- [Flutter SDK reference](https://docs.authsignal.com/sdks/client/flutter)
- [API reference](https://docs.authsignal.com/api)

