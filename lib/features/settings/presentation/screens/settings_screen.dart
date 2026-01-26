
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';
import 'package:dev_quotes/core/providers.dart';
import 'package:dev_quotes/core/widgets/update_dialog.dart';
import 'package:dev_quotes/core/services/update_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isCheckingUpdate = false;

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? AppColors.error : AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    if (_isCheckingUpdate) return;

    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      final updateService = ref.read(updateServiceProvider);
      _showSnackBar(context, 'Checking for updates...');

      final result = await updateService.isUpdateAvailable();

      if (!mounted) return;

      switch (result) {
        case UpdateCheckResult.noInternet:
          _showSnackBar(context, 'No internet connection. Please check your network.', isError: true);
          break;
        case UpdateCheckResult.rateLimitExceeded:
          _showSnackBar(context, 'Update server busy (Rate Limit). Please try again later.', isError: true);
          break;
        case UpdateCheckResult.error:
          _showSnackBar(context, 'Failed to check for updates.', isError: true);
          break;
        case UpdateCheckResult.noUpdate:
          _showSnackBar(context, 'You are using the latest version.');
          break;
        case UpdateCheckResult.updateAvailable:
          // Proceed to fetch details
          final releaseInfo = await updateService.getLatestReleaseInfo();
          if (releaseInfo != null && mounted) {
             // Hide the "Checking..." snackbar or just let it be
             if (context.mounted) {
               showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => UpdateDialog(
                  version: releaseInfo['version'],
                  releaseNotes: releaseInfo['releaseNotes'],
                  onUpdate: () async {
                    // Start download
                    final success = await updateService.downloadAndInstallUpdate(
                      releaseInfo['downloadUrl'],
                      (progress) {
                        // The dialog handles its own state if wired up, 
                        // or we rely on the existing simplistic binding.
                        // Ideally we'd pass a controller, but adhering to minimal UI changes:
                      },
                      () {
                        Navigator.of(context).pop();
                      },
                    );
                    if (success && context.mounted) {
                      Navigator.of(context).pop();
                      _showSnackBar(context, 'Update downloaded successfully');
                    } else if (context.mounted) {
                      // Only show failed if it wasn't just cancelled/closed successfully logic
                      // But downloadAndInstallUpdate returns false on error.
                      // Note: It returns false on user cancel in some implementations? 
                      // No, current logic returns false on error.
                      _showSnackBar(context, 'Update failed or cancelled', isError: true);
                    }
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              );
             }
          } else {
             _showSnackBar(context, 'Failed to load update details.', isError: true);
          }
          break;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preferences & Account',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    SettingsSection(
                      title: 'General',
                      children: [
                        SettingsToggleTile(
                          icon: Icons.notifications_rounded,
                          title: 'Notifications',
                          value: settings.notificationsEnabled,
                          onChanged: (value) {
                            notifier.toggleNotifications(value);
                          },
                          showDivider: true,
                        ),
                        SettingsToggleTile(
                          icon: Icons.public_rounded,
                          title: 'Show Public Quotes',
                          value: settings.showPublicQuotes,
                          onChanged: (value) {
                            notifier.toggleShowPublicQuotes(value);
                          },
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SettingsSection(
                      title: 'Account',
                      children: [
                        SettingsTile(
                          icon: Icons.person_rounded,
                          title: 'Profile',
                          onTap: () => context.push('/profile'),
                        ),
                        SettingsTile(
                          icon: Icons.add_circle_rounded,
                          title: 'Add Quote',
                          onTap: () => context.push('/add-quote'),
                        ),
                        SettingsTile(
                          icon: Icons.format_quote_rounded,
                          title: 'My Quotes',
                          onTap: () => context.push('/my-quotes'),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SettingsSection(
                      title: 'About',
                      children: [
                        SettingsTile(
                          icon: Icons.info_rounded,
                          title: 'About DevQuote',
                          onTap: () => context.push('/about'),
                        ),
                        SettingsTile(
                          icon: Icons.privacy_tip_rounded,
                          title: 'Privacy Policy',
                          onTap: () => context.push('/privacy-policy'),
                        ),
                        SettingsTile(
                          icon: Icons.description_rounded,
                          title: 'Terms of Service',
                          onTap: () => context.push('/terms-of-service'),
                        ),
                        Opacity(
                          opacity: _isCheckingUpdate ? 0.5 : 1.0,
                          child: SettingsTile(
                            icon: _isCheckingUpdate 
                                ? Icons.hourglass_empty_rounded 
                                : Icons.system_update_rounded,
                            title: _isCheckingUpdate ? 'Checking...' : 'Check for Updates',
                            onTap: _isCheckingUpdate ? () {} : _checkForUpdates,
                            showDivider: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            context.go('/auth');
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.error.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Version 1.0.0', // Ideally fetch this dynamically too
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

