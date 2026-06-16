import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

enum PushMode { apns, firebase }

class PushService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static PushMode mode = PushMode.firebase;

  static Future<void> initialize() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('PushService: failed to request permission: $e');
    }
  }

  static Future<String?> getPushTokenForMode(PushMode mode) async {
    try {
      if (mode == PushMode.firebase) {
        return await _messaging.getToken();
      }

      if (Platform.isIOS) {
        return await _messaging.getAPNSToken();
      }
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('PushService: failed to get push token for $mode: $e');
      return null;
    }
  }

  static Future<String?> getPushToken() => getPushTokenForMode(mode);
}
