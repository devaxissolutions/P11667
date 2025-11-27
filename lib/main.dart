import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'routes/app_router.dart';

import 'package:dev_quotes/core/providers.dart';
import 'package:dev_quotes/core/services/firebase_service.dart';
import 'package:dev_quotes/core/utils/seed_data.dart';
import 'package:dev_quotes/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with generated options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Note: GoogleSignIn requires SHA fingerprints to be added to Firebase Console
    // and Google Sign-In provider to be enabled to generate OAuth client IDs
    // Register background handler for Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // Request permission and get token (best-effort)
    final firebaseService = FirebaseService();
    try {
      final token = await firebaseService.requestPermissionAndGetToken();
      if (token != null) {
        // If a user is already signed in, attach the token to their user doc
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await firebaseService.attachTokenToUser(
            userId: user.uid,
            token: token,
          );
        }
      }
      // Listen for token refreshes and attach them when available
      firebaseService.tokenStream.listen((newToken) async {
        if (newToken != null) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await firebaseService.attachTokenToUser(
              userId: user.uid,
              token: newToken,
            );
          }
        }
      });
      // Foreground message handling
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // ignore: avoid_print
        print('FCM foreground message: ${message.messageId}');
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // handle deep link or navigation if desired
        // ignore: avoid_print
        print('FCM opened app from message: ${message.messageId}');
      });
    } catch (e) {
      debugPrint('FCM init error: $e');
    }
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  // Seed database on first run (check if already seeded)
  final hasSeeded = prefs.getBool('db_seeded') ?? false;
  if (!hasSeeded) {
    try {
      await seedQuotes();
      await seedCategories();
      await prefs.setBool('db_seeded', true);
      debugPrint('✅ Database seeded successfully');
    } catch (e) {
      debugPrint('❌ Error seeding database: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const DevQuoteApp(),
    ),
  );
}

class DevQuoteApp extends ConsumerWidget {
  const DevQuoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'DevQuote',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
