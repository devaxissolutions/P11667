import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

/// Top-level background message handler required by FCM plugin.
/// Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  debugPrint('Background message: ${message.messageId}');
  // For background messages, we can show local notification if needed
  // But typically, FCM handles it automatically for background
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _pendingNotificationPath;

  // SECURITY NOTE: Push notifications to other users must be sent from a secure backend
  // (e.g., Firebase Cloud Functions). Never include FCM Server Keys in client code.

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    if (_pendingNotificationPath != null) {
      debugPrint('Processing pending notification path: $_pendingNotificationPath');
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
      settings,
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

    debugPrint('FCM permission status: ${settings.authorizationStatus}');
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
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> _updateUserToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // If update fails, try set with merge
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      debugPrint('FCM token updated for user: ${user.uid}');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    _showLocalNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    _navigateToQuote(message);
  }

  void _handleInitialMessage(RemoteMessage message) {
    debugPrint('Initial message: ${message.messageId}');
    _navigateToQuote(message);
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final quoteId = data['quoteId'];
        if (quoteId != null) {
          _navigateToQuoteId(quoteId);
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
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
      debugPrint('Navigator key not set or context not available. Storing path: $path');
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
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  // Method to update notification preferences
  Future<void> updateNotificationPreference(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'preferences.notificationsEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Method to get current notification preference
  Future<bool> getNotificationPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['preferences']?['notificationsEnabled'] ?? true;
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
    debugPrint('sendNewQuoteNotification: Notifications should be sent via Cloud Functions');
  }
}
