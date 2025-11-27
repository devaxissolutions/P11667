import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level background message handler required by FCM plugin.
/// Must be a top-level function.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  // Handle background message (analytics, silent update, etc.)
  // Keep lightweight: store or log if needed.
  if (message.notification != null) {
    // Example: print for debugging
    // ignore: avoid_print
    print(
      'Background message: ${message.messageId} ${message.notification!.title}',
    );
  }
}

class FirebaseService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  FirebaseService({FirebaseMessaging? messaging, FirebaseFirestore? firestore})
    : _messaging = messaging ?? FirebaseMessaging.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> requestPermissionAndGetToken() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _messaging.getToken();
      return token;
    }
    return null;
  }

  Stream<String?> get tokenStream => _messaging.onTokenRefresh;

  /// Safe helper: attach token to user's Firestore document under `fcmTokens` array.
  Future<void> attachTokenToUser({
    required String userId,
    required String token,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      // If update fails (maybe field doesn't exist), try set with merge
      await _firestore.collection('users').doc(userId).set({
        'fcmTokens': [token],
      }, SetOptions(merge: true));
    }
  }
}
