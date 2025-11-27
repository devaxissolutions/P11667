import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging;

  NotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  /// Request notification permission from the user using Firebase Messaging
  /// This ensures proper platform-specific permission dialogs for FCM
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        // Note: provisional is iOS 12+ only, but safe to include
        provisional: false,
      );

      // Check the authorization status
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          // Permission granted - get token to ensure FCM works
          final token = await _messaging.getToken();
          return token != null;
        case AuthorizationStatus.denied:
        case AuthorizationStatus.notDetermined:
          return false;
      }
    } catch (e) {
      // If Firebase messaging fails, fall back to false
      return false;
    }
  }

  /// Check if notification permission is already granted
  Future<bool> isNotificationPermissionGranted() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      return false;
    }
  }

  /// Get the current FCM token (only if permission is granted)
  Future<String?> getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      return null;
    }
  }
}
