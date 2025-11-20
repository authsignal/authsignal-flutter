# Authsignal Flutter Example Backend

This is an example Node.js backend server that demonstrates how to integrate with the Authsignal server-side API for use with the Flutter SDK.

## Prerequisites

- Node.js 16.0.0 or higher
- npm or yarn

## Setup

1. **Install dependencies:**

```bash
npm install
```

2. **Configure environment variables:**

Copy the `.env.example` file to `.env`:

```bash
cp .env.example .env
```

Then update the `.env` file with your Authsignal credentials:

```env
AUTHSIGNAL_SECRET=your_secret_key_here
AUTHSIGNAL_TENANT_ID=your_tenant_id_here
AUTHSIGNAL_BASE_URL=https://api.authsignal.com/v1
```

You can find your credentials in the [Authsignal Portal](https://portal.authsignal.com).

### Regional Base URLs

Use the appropriate base URL for your tenant's region:

| Region | Base URL |
|--------|----------|
| US (Oregon) | `https://api.authsignal.com/v1` |
| AU (Sydney) | `https://au.api.authsignal.com/v1` |
| EU (Dublin) | `https://eu.api.authsignal.com/v1` |

## Running the Server

### Development Mode

Run with auto-reload on file changes:

```bash
npm run dev
```

### Production Mode

```bash
npm start
```

The server will start on `http://localhost:3000` (or the port specified in your `.env` file).

## API Endpoints

### Health Check
```
GET /health
```

Check if the server is running.

### Get Registration Token
```
POST /api/registration-token
Content-Type: application/json

{
  "userId": "user_123"
}
```

Returns a token that allows the user to add new authenticators (device, email, etc.).

### Get Challenge Token
```
POST /api/challenge-token
Content-Type: application/json

{
  "userId": "user_123",
  "phoneNumber": "+1234567890"  // optional
}
```

Returns a token for authentication challenges. If the user has device authenticators enrolled, it will also create a device challenge.

### Validate Token
```
POST /api/validate
Content-Type: application/json

{
  "token": "token_from_client"
}
```

Validates a completed challenge token.

### Get User Info
```
GET /api/user/:userId
```

Retrieves user information including enrolled authenticators.

## Testing

### Using curl

**Health check:**
```bash
curl http://localhost:3000/health
```

**Get registration token:**
```bash
curl -X POST http://localhost:3000/api/registration-token \
  -H "Content-Type: application/json" \
  -d '{"userId":"test_user_123"}'
```

**Get challenge token:**
```bash
curl -X POST http://localhost:3000/api/challenge-token \
  -H "Content-Type: application/json" \
  -d '{"userId":"test_user_123"}'
```

### Android Emulator

If testing with the Android emulator, use the special IP address:
```
http://10.0.2.2:3000
```

### iOS Simulator

If testing with the iOS simulator, use:
```
http://localhost:3000
```

## Dependencies

This backend uses the following key dependencies:

- **[@authsignal/node](https://www.npmjs.com/package/@authsignal/node)** (v2.12.0) - Official Authsignal Node.js SDK
- **express** - Web framework
- **cors** - Cross-origin resource sharing
- **dotenv** - Environment variable management

## Troubleshooting

### Missing Environment Variables

If you see this error:
```
❌ Missing required environment variables!
```

Make sure you've created a `.env` file from `.env.example` and filled in your Authsignal credentials.

### Connection Issues from Flutter App

**Android Emulator:** Use `http://10.0.2.2:3000`  
**iOS Simulator:** Use `http://localhost:3000`  
**Physical Device:** Use your computer's local IP address (e.g., `http://192.168.1.100:3000`)

### Port Already in Use

If port 3000 is already in use, change the `PORT` value in your `.env` file to a different port number.

## Security Notes

⚠️ **Important:** This is an example backend for development and testing purposes.

For production use:
- Never expose your `AUTHSIGNAL_SECRET` in client-side code
- Implement proper authentication and authorization
- Use HTTPS in production
- Add rate limiting
- Validate and sanitize all inputs
- Follow security best practices

## Learn More

- [Authsignal Documentation](https://docs.authsignal.com)
- [Authsignal Node.js SDK](https://github.com/authsignal/authsignal-node)
- [Authsignal Portal](https://portal.authsignal.com)

