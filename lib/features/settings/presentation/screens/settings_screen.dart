
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';
import 'package:dev_quotes/core/providers.dart';
import 'package:dev_quotes/core/widgets/update_dialog.dart';
import 'package:dev_quotes/core/services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  void _showPermissionDeniedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Permission Required',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'To install updates, please enable "Install unknown apps" permission for Dev Quotes in your device settings.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          final releaseInfo = await updateService.getLatestReleaseInfo();
          if (releaseInfo != null && mounted) {
            final progressNotifier = ValueNotifier<double>(0);
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => UpdateDialog(
                  version: releaseInfo['version'],
                  releaseNotes: releaseInfo['releaseNotes'],
                  size: releaseInfo['size'] ?? 0,
                  progressNotifier: progressNotifier,
                  onUpdate: () async {
                    final result = await updateService.downloadAndInstallUpdate(
                      releaseInfo['downloadUrl'],
                      (progress) {
                        progressNotifier.value = progress;
                      },
                      () {
                        Navigator.of(context).pop();
                      },
                    );
                    
                    final success = result['success'] as bool;
                    
                    if (success && context.mounted) {
                      Navigator.of(context).pop();
                      _showSnackBar(context, 'Update downloaded successfully. Please complete the installation.');
                    } else if (context.mounted) {
                      Navigator.of(context).pop();
                      
                      // Handle permission denial specifically
                      if (result['permissionDenied'] == true) {
                        final permanentlyDenied = result['permanentlyDenied'] == true;
                        final errorMessage = result['error'] as String? ?? 'Install permission denied';
                        
                        if (permanentlyDenied) {
                          // Show dialog to open settings
                          _showPermissionDeniedDialog(context, errorMessage);
                        } else {
                          _showSnackBar(context, errorMessage, isError: true);
                        }
                      } else {
                        final errorMessage = result['error'] as String? ?? 'Update failed';
                        _showSnackBar(context, errorMessage, isError: true);
                      }
                    }
                  },
                  onCancel: () {
                    progressNotifier.dispose();
                    Navigator.of(context).pop();
                  },
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

  Future<String> _getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: const Color(0xFF0F0F13),
            surfaceTintColor: Colors.transparent,
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Settings',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24, // Expanded size handled effectively by Scale
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            actions: [
               // Optional: Add an action here if needed, like a profile icon mini
            ],
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 20),
            SettingsSection(
              title: 'General',
              children: [
                SettingsToggleTile(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  value: settings.notificationsEnabled,
                  onChanged: (value) => notifier.toggleNotifications(value),
                  showDivider: true,
                ),
                SettingsToggleTile(
                  icon: Icons.public_rounded,
                  title: 'Show Public Quotes',
                  value: settings.showPublicQuotes,
                  onChanged: (value) => notifier.toggleShowPublicQuotes(value),
                  showDivider: false,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
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

            const SizedBox(height: 32),
            SettingsSection(
              title: 'Support & Legal', 
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

            const SizedBox(height: 40),
            TextButton(
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
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Log Out',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  FutureBuilder<String>(
                    future: _getVersion(),
                    builder: (context, snapshot) => Text(
                      'DevQuote v${snapshot.data ?? '1.2.0'}',
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Made with ❤️ by Developer',
                    style: GoogleFonts.inter(
                      color: Colors.grey[700],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

