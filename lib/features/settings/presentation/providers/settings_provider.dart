import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_quotes/di/service_locator.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../auth/models/auth_state.dart';

class SettingsState {
  final bool notificationsEnabled;
  final bool showPublicQuotes;

  const SettingsState({
    this.notificationsEnabled = true,
    this.showPublicQuotes = false,
  });

  SettingsState copyWith({bool? notificationsEnabled, bool? showPublicQuotes}) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      showPublicQuotes: showPublicQuotes ?? this.showPublicQuotes,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _showPublicQuotesKey = 'show_public_quotes';

  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    bool showPublicQuotes = prefs.getBool(_showPublicQuotesKey) ?? false;

    // Try to load from Firestore if user is authenticated
    final authAsync = ref.read(authProvider);
    final authState = authAsync.value;
    if (authState is AuthAuthenticated) {
      final userDataSource = ref.read(userDataSourceProvider);
      try {
        showPublicQuotes = await userDataSource.getUserPreference(
          authState.user.id,
          'showPublicQuotes',
          showPublicQuotes,
        );
        final notificationsFromFirestore = await userDataSource.getUserPreference(
          authState.user.id,
          'notificationsEnabled',
          notificationsEnabled,
        );
        // Update local cache
        await prefs.setBool(_showPublicQuotesKey, showPublicQuotes);
        await prefs.setBool(_notificationsKey, notificationsFromFirestore);
        state = SettingsState(
          notificationsEnabled: notificationsFromFirestore,
          showPublicQuotes: showPublicQuotes,
        );
        return;
      } catch (e) {
        // Fall back to local
      }
    }

    state = SettingsState(
      notificationsEnabled: notificationsEnabled,
      showPublicQuotes: showPublicQuotes,
    );
  }

  void toggleNotifications(bool value) async {
    if (value) {
      // If enabling, request permission first
      final notificationService = ref.read(notificationServiceProvider);
      final granted = await notificationService.requestNotificationPermission();
      
      if (!granted) {
        // If permission denied, we can't enable it in state
        return;
      }
    }

    // Update state immediately for responsive UI
    state = state.copyWith(notificationsEnabled: value);

    // Save preference and handle FCM in background
    _updateNotificationSettings(value);
  }

  void toggleShowPublicQuotes(bool value) async {
    // Update state immediately
    state = state.copyWith(showPublicQuotes: value);

    // Save to local cache
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_showPublicQuotesKey, value);

    // Save to Firestore
    final authAsync = ref.read(authProvider);
    final authState = authAsync.value;
    if (authState is AuthAuthenticated) {
      final userDataSource = ref.read(userDataSourceProvider);
      try {
        await userDataSource.setUserPreference(
          authState.user.id,
          'showPublicQuotes',
          value,
        );
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _updateNotificationSettings(bool value) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);

      // Update Firestore preference
      final authAsync = ref.read(authProvider);
      final authState = authAsync.value;
      
      final userDataSource = ref.read(userDataSourceProvider);
      final notificationService = ref.read(notificationServiceProvider);

      if (authState is AuthAuthenticated) {
        await userDataSource.setUserPreference(
          authState.user.id,
          'notificationsEnabled',
          value,
        );

        if (value) {
          // If enabled, ensure we have the token synced
          final token = await notificationService.getFCMToken();
          if (token != null) {
            await userDataSource.updateUserFCMToken(authState.user.id, token);
          }
        }
      }

      // Save to local cache
      await prefs.setBool(_notificationsKey, value);
    } catch (e) {
      // Handle error silently
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
