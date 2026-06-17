## 2.7.0

- Added passkey credential sync support with `syncCredentials` enabled by default for sign-up and sign-in.
- Updated native dependencies to Authsignal iOS `~> 2.10.0` and Authsignal Android `3.11.0`.
- Raised Android build tooling to support AndroidX Credentials 1.6.0.

## 2.6.0

- Added an optional `pushToken` parameter to `push.addCredential` for registering a device push token during enrollment.

## 2.5.0

- Added public custom data points to challenge responses: action-scope data under `custom` and user-scope data under `user.custom` on `AppChallenge` and `ClaimChallengeResponse`.

## 2.4.1

- Added Authsignal SDK identity/version headers and wrapper-aware User-Agent metadata for native mobile requests.

## 2.4.0

### New Features

- Added `Authsignal.getDeviceId()` and a `deviceID` constructor parameter for cross-platform device identifiers.
- Added `passkey.shouldPromptToCreatePasskey({username})`.
- Added `passkey.signUp(ignorePasskeyAlreadyExistsError: ...)` to suppress the "passkey already exists" error.
- Added Flutter web credential tracking for `passkey.shouldPromptToCreatePasskey({username})` and pinned the browser SDK CDN version.
- Expanded `push.addCredential`, `qr.addCredential`, and `inapp.addCredential` with `requireUserAuthentication`, `keychainAccess`, and `performAttestation` parameters (iOS honors all three; Android honors `performAttestation`).
- Added `username` parameter to `inapp.getCredential`, `inapp.addCredential`, `inapp.removeCredential`, and `inapp.verify`.
- Added `action` parameter to `inapp.verify`.
- Added PIN authentication suite: `inapp.createPin`, `inapp.verifyPin`, `inapp.deletePin`, `inapp.getAllPinUsernames`.
- Added `KeychainAccess` enum and `VerifyPinResponse` type.
- `ClaimChallengeResponse` now includes `actionCode` and `idempotencyKey`.
- Flutter web `getDeviceId` now persists a generated identifier via `localStorage` (uses `crypto.randomUUID()` when available) so repeat calls return the same value.


## 2.3.0

### Flutter Web Support

- Added SMS OTP support for Flutter web (`sms.enroll`, `sms.challenge`, `sms.verify`).
- Added TOTP/Authenticator app support for Flutter web (`totp.enroll`, `totp.verify`).
- Added WhatsApp OTP support for Flutter web (`whatsapp.challenge`, `whatsapp.verify`).
- Updated example app with SMS OTP, TOTP, and WhatsApp sections for web.

## 2.2.0

- Migrate from deprecated `dart:html` and `dart:js_util` to `package:web` and `dart:js_interop` for Flutter web support.

## 2.1.0

### Flutter Web Support

- Federated plugin structure with shared platform interface and dedicated web implementation.
- Flutter web support for email OTP and passkeys via Authsignal Browser SDK (automatic script loading, no manual `<script>` tag required).
- Passkey flows (`signUp`, `signIn`) for Flutter web apps ([docs](https://docs.authsignal.com/sdks/client/web/passkeys)).
- Public API updated so `Authsignal` initialization, `setToken`, and authenticator methods delegate through platform interface.
- Example app extended with passkey and email OTP demos.

## 2.0.0

### Breaking Changes

- Remove `device` namespace for all app verification flows. Introduce `qr` and `inapp` alongside `push` to use instead.
- The `push.getCredential` method now returns `AuthsignalResponse<AppCredential?>` instead of `AuthsignalResponse<PushCredential?>`.
- The `push.addCredential` method now returns `AuthsignalResponse<AppCredential>` instead of `AuthsignalResponse<bool>`.
- Renamed `PushCredential` to `AppCredential` and added `userId` field.
- Renamed `PushChallenge` to `AppChallenge`.
- Removed `DeviceCredential`, `DeviceChallenge`, and `VerifyDeviceResponse` types.
- Added `InAppVerifyResponse` type for in-app authentication verification.

### New Features

- Added `qr` namespace with methods:
  - `qr.getCredential()` - Get QR code credential
  - `qr.addCredential()` - Add QR code credential
  - `qr.removeCredential()` - Remove QR code credential
  - `qr.claimChallenge()` - Claim QR code challenge
  - `qr.updateChallenge()` - Update QR code challenge
- Added `inapp` namespace with methods:
  - `inapp.getCredential()` - Get in-app credential
  - `inapp.addCredential()` - Add in-app credential
  - `inapp.removeCredential()` - Remove in-app credential
  - `inapp.verify()` - Verify in-app authentication

## 1.2.1

Documentation

## 1.2.0

- Add device credentials SDK methods

## 0.1.1

- Make versioning consistent.

## 0.1.0

- Authsignal Flutter SDK initial release.
