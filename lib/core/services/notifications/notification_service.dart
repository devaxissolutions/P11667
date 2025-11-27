import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

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

  // FCM Server Key - Get from Firebase Console > Project Settings > Cloud Messaging > Server Key
  // WARNING: This should be stored securely, not hardcoded in production
  static const String _fcmServerKey = 'YOUR_FCM_SERVER_KEY_HERE';

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
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
    await _requestPermissions();

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

  Future<void> _requestPermissions() async {
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
    if (_navigatorKey?.currentContext != null) {
      GoRouter.of(_navigatorKey!.currentContext!).go('/quote/$quoteId');
    } else {
      debugPrint('Navigator key not set or context not available');
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

  // Method to send notification for new quote
  Future<void> sendNewQuoteNotification(
    String quoteId,
    String quoteText,
    String author,
    String creatorId,
  ) async {
    try {
      // Get all users with notifications enabled
      final usersSnapshot = await _firestore
          .collection('users')
          .where('preferences.notificationsEnabled', isEqualTo: true)
          .get();

      final tokens = <String>[];
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final token = data['fcmToken'] as String?;
        final userId = doc.id;
        if (token != null && userId != creatorId) {
          tokens.add(token);
        }
      }

      if (tokens.isEmpty) return;

      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');

      final headers = {
        'Authorization': 'key=$_fcmServerKey',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        'registration_ids': tokens, // Send to multiple tokens
        'notification': {
          'title': 'New Quote Added',
          'body': '"$quoteText" - $author',
        },
        'data': {
          'quoteId': quoteId,
          'type': 'new_quote',
          'userId': creatorId, // Include for potential use
        },
      });

      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        debugPrint('Notification sent to ${tokens.length} users');
      } else {
        debugPrint(
          'Failed to send notification: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
