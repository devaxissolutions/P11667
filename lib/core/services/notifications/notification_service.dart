import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/domain/repositories/profile_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:dev_quotes/core/utils/logger.dart';

/// Top-level background message handler required by FCM plugin.
/// Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  Logger.d('Background message: ${message.messageId}');
  // For background messages, we can show local notification if needed
  // But typically, FCM handles it automatically for background
}

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final ProfileRepository _profileRepository;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService({
    required FirebaseMessaging messaging,
    required FirebaseAuth auth,
    required ProfileRepository profileRepository,
  })  : _messaging = messaging,
        _auth = auth,
        _profileRepository = profileRepository;

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _pendingNotificationPath;

  // SECURITY NOTE: Push notifications to other users must be sent from a secure backend
  // (e.g., Firebase Cloud Functions). Never include FCM Server Keys in client code.

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    if (_pendingNotificationPath != null) {
      Logger.d('Processing pending notification path: $_pendingNotificationPath');
      final path = _pendingNotificationPath!;
      _pendingNotificationPath = null;
      _navigateToPath(path);
    }
  }

  static const String _channelId = 'devquote_channel';
  static const String _channelName = 'DevQuote Notifications';
  static const String _channelDescription = 'Notifications for new quotes';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    // Request permissions
    await requestNotificationPermission();

    // Get initial token
    final token = await _messaging.getToken();
    if (token != null) {
      await _updateUserToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateUserToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle initial message (app opened from terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }
  }

  Future<bool> requestNotificationPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    Logger.d('FCM permission status: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<bool> isNotificationPermissionGranted() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      Logger.d('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> _updateUserToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      final result = await _profileRepository.updateFCMToken(user.uid, token);
      if (result is Success) {
        Logger.d('FCM token updated for user: ${user.uid}');
      } else {
        Logger.e('Failed to update FCM token', (result as Error).failure.message);
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    Logger.d('Foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    _showLocalNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    Logger.d('Message opened app: ${message.messageId}');
    _navigateToQuote(message);
  }

  void _handleInitialMessage(RemoteMessage message) {
    Logger.d('Initial message: ${message.messageId}');
    _navigateToQuote(message);
  }

  void _onNotificationTapped(NotificationResponse response) {
    Logger.d('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final quoteId = data['quoteId'];
        if (quoteId != null) {
          _navigateToQuoteId(quoteId);
        }
      } catch (e) {
        Logger.d('Error parsing notification payload: $e');
      }
    }
  }

  void _navigateToQuote(RemoteMessage message) {
    final quoteId = message.data['quoteId'];
    if (quoteId != null) {
      _navigateToQuoteId(quoteId);
    }
  }

  void _navigateToQuoteId(String quoteId) {
    _navigateToPath('/quote/$quoteId');
  }

  void _navigateToPath(String path) {
    if (_navigatorKey?.currentContext != null) {
      GoRouter.of(_navigatorKey!.currentContext!).go(path);
    } else {
      Logger.d('Navigator key not set or context not available. Storing path: $path');
      _pendingNotificationPath = path;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  // Method to update notification preferences
  Future<void> updateNotificationPreference(bool enabled) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _profileRepository.updateNotificationPreference(user.uid, enabled);
    }
  }

  // Method to get current notification preference
  Future<bool> getNotificationPreference() async {
    final user = _auth.currentUser;
    if (user != null) {
      final result = await _profileRepository.getNotificationPreference(user.uid);
      if (result is Success) {
        return (result as Success).data;
      }
    }
    return true;
  }

  /// Request to send notification for new quote.
  /// 
  /// IMPORTANT: This should trigger a Cloud Function or backend API.
  /// Never send push notifications directly from client code as it requires
  /// exposing the FCM Server Key, which is a critical security vulnerability.
  /// 
  /// To implement properly:
  /// 1. Create a Cloud Function triggered by Firestore writes to 'quotes' collection
  /// 2. The Cloud Function should handle sending notifications securely
  /// 3. Or call a secure backend API endpoint that handles notification sending
  Future<void> sendNewQuoteNotification(
    String quoteId,
    String quoteText,
    String author,
    String creatorId,
  ) async {
    // TODO: Implement via Cloud Functions or secure backend API
    // This method is intentionally disabled for security reasons.
    // Push notifications should be triggered server-side when a quote is created.
    Logger.d('sendNewQuoteNotification: Notifications should be sent via Cloud Functions');
  }
}
