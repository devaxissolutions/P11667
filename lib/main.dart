import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/theme.dart';
import 'core/widgets/update_dialog.dart';
import 'routes/app_router.dart';

import 'package:dev_quotes/di/service_locator.dart';
import 'package:dev_quotes/core/services/notifications/notification_service.dart';

import 'package:dev_quotes/core/utils/logger.dart';
import 'package:dev_quotes/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:dev_quotes/core/services/update_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  // Load environment variables if available
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    Logger.d('Skipping .env load: ${e.toString()}');
  }

  // Initialize Google Sign In for v7.x
  try {
    await GoogleSignIn.instance.initialize(
      serverClientId: '958725673026-q173iglhhef0av7tbo402uttr61sc7d2.apps.googleusercontent.com',
    );
  } catch (e) {
    Logger.d('GoogleSignIn initialization failed: $e');
  }

  // Initialize Hive for offline-first architecture
  await Hive.initFlutter();

  // Declare startupTrace variable
  Trace? startupTrace;

  try {
    // Initialize Firebase with generated options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // OFFLINE-FIRST: Enable Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // MEDIUM SECURITY FIX: Activate Firebase App Check
    // This prevents unauthorized API usage even if API keys are exposed
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity, // SECURE: Use playIntegrity in production
      appleProvider: AppleProvider.appAttest,
    );

    // Enable Firebase Performance Monitoring
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

    // Start app startup trace after Firebase is initialized
    startupTrace = FirebasePerformance.instance.newTrace("app_startup_time");
    await startupTrace.start();

    // Register background handler for Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    Logger.d('Firebase init failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // MEDIUM SECURITY FIX: Initialize session management via DI
  container.read(sessionServiceProvider).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DevQuoteApp(),
    ),
  );

  // Perform background initialization after the UI is launched
  _initializeBackgroundTasks(container, prefs, startupTrace);
}

/// Run background initialization tasks without blocking the UI
Future<void> _initializeBackgroundTasks(
  ProviderContainer container,
  SharedPreferences prefs,
  Trace? startupTrace,
) async {
  try {
    // Initialize notifications in background
    try {
      await container.read(notificationServiceProvider).initialize();
    } catch (e) {
      Logger.d('Notification service init failed: $e');
    }
    
    // NOTE: Client-side seeding removed for production. 
    // Seeding is now handled by administrative scripts or cloud functions.
    
  } catch (e) {
    Logger.d('Background init error: $e');
  } finally {
    // Stop startup trace after initialization is complete
    if (startupTrace != null) {
      await startupTrace.stop();
    }
  }
}

class DevQuoteApp extends ConsumerStatefulWidget {
  const DevQuoteApp({super.key});

  @override
  ConsumerState<DevQuoteApp> createState() => _DevQuoteAppState();
}

class _DevQuoteAppState extends ConsumerState<DevQuoteApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Synchronize navigator key with NotificationService
      final key = ref.read(navigatorKeyProvider);
      ref.read(notificationServiceProvider).setNavigatorKey(key);
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final updateService = ref.read(updateServiceProvider);
    final result = await updateService.isUpdateAvailable();
    if (result == UpdateCheckResult.updateAvailable && mounted) {
      final releaseInfo = await updateService.getLatestReleaseInfo();
      if (releaseInfo != null && mounted) {
        _showUpdateDialog(releaseInfo);
      }
    }
  }

  void _showUpdateDialog(Map<String, dynamic> releaseInfo) {
    final navigatorKey = ref.read(navigatorKeyProvider);
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UpdateDialog(
        version: releaseInfo['version'],
        releaseNotes: releaseInfo['releaseNotes'],
        onUpdate: () async {
          final updateService = ref.read(updateServiceProvider);
          await updateService.launchPlayStore();
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        },
        onCancel: () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'DevQuote',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
