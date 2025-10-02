# Example Backend Server

This is a simple Node.js backend server that demonstrates how to integrate with Authsignal's server-side API for the Flutter SDK example app.

## ⚠️ Important Security Note

**This is an example server for development and testing purposes only.**

In production:
- Never expose your API secret key
- Implement proper authentication and authorization
- Use environment-specific configurations
- Add rate limiting and security middleware
- Validate all inputs
- Use HTTPS

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Edit `.env` with your Authsignal credentials:

```env
AUTHSIGNAL_SECRET=your_secret_key
AUTHSIGNAL_TENANT_ID=your_tenant_id
AUTHSIGNAL_BASE_URL=https://api.authsignal.com/v1
PORT=3000
```

Get your credentials from [Authsignal Portal](https://portal.authsignal.com) → Settings → API Keys

### 3. Start Server

Development mode (with auto-reload):
```bash
npm run dev
```

Production mode:
```bash
npm start
```

The server will start on `http://localhost:3000`

## API Endpoints

### Health Check
```bash
GET /health
```

### Registration Token
Get a token for registering new authenticators (device credentials, passkeys, etc.)

```bash
POST /api/registration-token
Content-Type: application/json

{
  "userId": "user_123"
}
```

### Challenge Token
Get a token for authentication challenges

```bash
POST /api/challenge-token
Content-Type: application/json

{
  "userId": "user_123",
  "phoneNumber": "+1234567890"
}
```

### Validate Token
Validate a completed challenge token

```bash
POST /api/validate
Content-Type: application/json

{
  "token": "eyJ..."
}
```

### Get User
Get user information and authenticators

```bash
GET /api/user/:userId
```

## Testing

Test the health endpoint:
```bash
curl http://localhost:3000/health
```

Test registration token:
```bash
curl -X POST http://localhost:3000/api/registration-token \
  -H "Content-Type: application/json" \
  -d '{"userId":"test_user_123"}'
```

## Flutter Integration

### iOS Simulator
Use `http://localhost:3000` in your Flutter app

### Android Emulator
Use `http://10.0.2.2:3000` in your Flutter app (10.0.2.2 is the special IP that maps to localhost)

Update `lib/config.dart` in the example app:
```dart
static const String backendUrl = 'http://localhost:3000'; // iOS
// or
static const String backendUrl = 'http://10.0.2.2:3000'; // Android
```

## Troubleshooting

### "Missing required environment variables"
- Ensure `.env` file exists and has all required variables
- Check that you copied `.env.example` to `.env`

### "Connection refused" from Flutter app
- Ensure the server is running
- Check the correct URL for your platform (localhost vs 10.0.2.2)
- Check firewall settings

### "Unauthorized" or "Invalid credentials"
- Verify your API secret and tenant ID are correct
- Ensure no extra whitespace in your `.env` file

## Production Deployment

For production deployment, consider:

1. **Environment Variables**: Use proper secret management (AWS Secrets Manager, Azure Key Vault, etc.)
2. **Authentication**: Add user authentication to your endpoints
3. **Rate Limiting**: Implement rate limiting to prevent abuse
4. **HTTPS**: Always use HTTPS in production
5. **Monitoring**: Add logging and monitoring
6. **Validation**: Add robust input validation
7. **Error Handling**: Implement comprehensive error handling

Example production frameworks:
- AWS Lambda + API Gateway
- Google Cloud Functions
- Azure Functions
- Heroku
- Vercel / Netlify Functions

## Learn More

- [Authsignal Server API Documentation](https://docs.authsignal.com/api)
- [Node SDK Documentation](https://docs.authsignal.com/sdks/server/node)
- [Security Best Practices](https://docs.authsignal.com/security)

