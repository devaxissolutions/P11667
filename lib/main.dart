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
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dev_quotes/core/services/update_service.dart';

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

    // Register background handler for Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const DevQuoteApp(),
    ),
  );

  // Perform background initialization after the UI is launched
  _initializeBackgroundTasks(prefs, startupTrace);
}

/// Run background initialization tasks without blocking the UI
Future<void> _initializeBackgroundTasks(
  SharedPreferences prefs,
  Trace? startupTrace,
) async {
  try {
    // Initialize notifications in background
    await NotificationService().initialize();

    // Check connectivity before seeding
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    // Seed database on first run (check if already seeded)
    final hasSeeded = prefs.getBool('db_seeded') ?? false;
    if (!hasSeeded && hasInternet) {
      // Small delay to let the app settle
      await Future.delayed(const Duration(seconds: 1));

      try {
        await seedQuotes();
        await seedCategories();
        await prefs.setBool('db_seeded', true);
        debugPrint('✅ Database seeded successfully');
      } catch (e) {
        debugPrint('❌ Error seeding database: $e');
      }
    } else if (!hasSeeded && !hasInternet) {
      debugPrint('ℹ️ Skip seeding: No internet connection');
    }
  } catch (e) {
    debugPrint('Background init error: $e');
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
      NotificationService().setNavigatorKey(key);
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UpdateDialog(
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
              if (mounted && dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
          );
          // Capture the root context before async gap if possible, or reliably check mounted
          // Note: dialogContext is for the dialog. `context` is the state's context.
          
          if (!mounted) return;
          
          // Close dialog first
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }

          // Then show snackbar using state context
          if (mounted) {
             if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Update downloaded successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Update failed')),
              );
            }
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
