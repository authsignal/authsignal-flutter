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
