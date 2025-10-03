<img width="1070" alt="Authsignal" src="https://raw.githubusercontent.com/authsignal/authsignal-flutter/main/.github/images/authsignal.png">

# Authsignal Flutter SDK

Check out our [official Flutter documentation](https://docs.authsignal.com/sdks/client/flutter).

## Installation

Add the Authsignal Flutter SDK to your project:

```yaml
dependencies:
  authsignal_flutter: ^1.2.1
```

Then install the package:

```bash
flutter pub get
```

For iOS apps, install CocoaPods dependencies:

```bash
cd ios && pod install
```

## Initialization

Initialize the Authsignal client in your code:

```dart
import 'package:authsignal_flutter/authsignal_flutter.dart';

final authsignal = Authsignal(
  tenantID: 'YOUR_TENANT_ID',
  baseURL: 'YOUR_REGION_BASE_URL',
);
```

You can find your `tenantID` in the [Authsignal Portal](https://portal.authsignal.com).

You must specify the correct `baseURL` for your tenant's region.

| Region | Base URL |
|--------|----------|
| US (Oregon) | `https://api.authsignal.com/v1` |
| AU (Sydney) | `https://au.api.authsignal.com/v1` |
| EU (Dublin) | `https://eu.api.authsignal.com/v1` |

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
