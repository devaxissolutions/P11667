import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Settings',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  SettingsSection(
                    title: 'General',
                    children: [
                      SettingsToggleTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        value: settings.notificationsEnabled,
                        onChanged: (value) {
                          notifier.toggleNotifications(value);
                          _showSnackBar(
                            context,
                            value
                                ? 'Notifications enabled'
                                : 'Notifications disabled',
                          );
                        },
                        showDivider: false,
                      ),
                      SettingsToggleTile(
                        icon: Icons.public_outlined,
                        title: 'Show Public Quotes',
                        value: settings.showPublicQuotes,
                        onChanged: (value) {
                          notifier.toggleShowPublicQuotes(value);
                          _showSnackBar(
                            context,
                            value
                                ? 'Public quotes enabled'
                                : 'Public quotes disabled',
                          );
                        },
                        showDivider: false,
                      ),
                      // App Icon is in the design but not explicitly requested in the prompt details,
                      // but I'll add it as a placeholder if needed, or skip for now based on prompt.
                      // Prompt says: GENERAL: Notifications toggle, Theme toggle.
                      // So I will stick to that.
                    ],
                  ),
                  SettingsSection(
                    title: 'Account',
                    children: [
                      SettingsTile(
                        icon: Icons.person_outline,
                        title: 'Profile',
                        onTap: () => context.push('/settings/profile'),
                      ),
                      SettingsTile(
                        icon: Icons.add_circle_outline,
                        title: 'Add Quote',
                        onTap: () => context.push('/settings/add-quote'),
                      ),
                      SettingsTile(
                        icon: Icons.format_quote_outlined,
                        title: 'My Quotes',
                        onTap: () => context.push('/my-quotes'),
                      ),
                      SettingsTile(
                        icon: Icons.logout,
                        title: 'Logout',
                        textColor: const Color(0xFFFF453A),
                        iconColor: const Color(0xFFFF453A),
                        showDivider: false,
                        onTap: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            context.go('/auth');
                          }
                        },
                      ),
                    ],
                  ),
                  SettingsSection(
                    title: 'About',
                    children: [
                      SettingsTile(
                        icon: Icons.info_outline,
                        title: 'About DevQuote',
                        onTap: () => context.push('/settings/about'),
                      ),
                      SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => context.push('/settings/privacy-policy'),
                      ),
                      SettingsTile(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () => context.push('/settings/terms-of-service'),
                      ),
                      SettingsTile(
                        icon: Icons.code,
                        title: 'App Version',
                        trailing: Text(
                          '1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
