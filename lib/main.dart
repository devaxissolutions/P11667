import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'core/widgets/update_dialog.dart';
import 'routes/app_router.dart';

import 'package:dev_quotes/core/providers.dart';
import 'package:dev_quotes/core/services/notifications/notification_service.dart';
import 'package:dev_quotes/core/utils/seed_data.dart';
import 'package:dev_quotes/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_performance/firebase_performance.dart';

// Global navigator key for notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Declare startupTrace variable
  Trace? startupTrace;

  try {
    // Initialize Firebase with generated options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firebase Performance Monitoring
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

    // Start app startup trace after Firebase is initialized
    startupTrace = FirebasePerformance.instance.newTrace("app_startup_time");
    await startupTrace.start();

    // Note: GoogleSignIn requires SHA fingerprints to be added to Firebase Console
    // and Google Sign-In provider to be enabled to generate OAuth client IDs
    // Register background handler for Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize notifications
    await NotificationService().initialize();
    // The navigator key will be set inside the App widget using the provider
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

  // Stop startup trace after app is launched, if it was started
  if (startupTrace != null) {
    await startupTrace.stop();
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
      NotificationService().setNavigatorKey(key);
      
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final updateService = ref.read(updateServiceProvider);
    final hasUpdate = await updateService.isUpdateAvailable();
    if (hasUpdate && mounted) {
      final releaseInfo = await updateService.getLatestReleaseInfo();
      if (releaseInfo != null && mounted) {
        _showUpdateDialog(releaseInfo);
      }
    }
  }

  void _showUpdateDialog(Map<String, dynamic> releaseInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDialog(
        version: releaseInfo['version'],
        releaseNotes: releaseInfo['releaseNotes'],
        onUpdate: () async {
          final updateService = ref.read(updateServiceProvider);
          final success = await updateService.downloadAndInstallUpdate(
            releaseInfo['downloadUrl'],
            (progress) {
              // Update progress in dialog if needed
            },
            () {
              Navigator.of(context).pop();
            },
          );
          if (success) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Update downloaded successfully')),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Update failed')));
          }
        },
        onCancel: () => Navigator.of(context).pop(),
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
