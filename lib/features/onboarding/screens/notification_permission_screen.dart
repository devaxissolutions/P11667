import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/services/notifications/notification_service.dart';

class NotificationPermissionScreen extends StatefulWidget {
  final VoidCallback onEnableNotifications;
  final VoidCallback onSkip;
  final int currentPage;
  final int totalPages;

  const NotificationPermissionScreen({
    super.key,
    required this.onEnableNotifications,
    required this.onSkip,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isRequesting = false;
  bool _isPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    // Check if permission is permanently denied to show appropriate UI
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _isPermanentlyDenied = status.isPermanentlyDenied;
      });
    }
  }

  Future<void> _handleEnableNotifications() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      // If permanently denied, go directly to settings
      if (_isPermanentlyDenied) {
        await _showSettingsDialog();
        return;
      }

      final granted = await _notificationService
          .requestNotificationPermission();

      if (mounted) {
        if (granted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notifications enabled successfully!'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );

          // Wait a bit for the user to see the message
          await Future.delayed(const Duration(milliseconds: 500));

          // Complete onboarding
          widget.onEnableNotifications();
        } else {
          // Check if now permanently denied after the request
          final status = await Permission.notification.status;
          final isPermanentlyDenied = status.isPermanentlyDenied;

          if (isPermanentlyDenied) {
            // Show dialog to go to settings
            await _showSettingsDialog();
          } else {
            // Show error message for denied
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Notification permission denied. You can enable it later in settings.',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );

            // Still complete onboarding even if denied
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              widget.onEnableNotifications();
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permission: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
        // Re-check permission status
        await _checkPermissionStatus();
      }
    }
  }

  Future<void> _showSettingsDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Notification Permission Required',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          content: Text(
            'To receive daily quote notifications, please enable notifications in your device settings.',
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Skip',
                style: AppTypography.buttonText.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onEnableNotifications();
              },
            ),
            TextButton(
              child: Text(
                'Open Settings',
                style: AppTypography.buttonText.copyWith(
                  color: AppColors.primary,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
                // After returning from settings, complete onboarding
                widget.onEnableNotifications();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 48),

              const Spacer(flex: 2),

              // Bell icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                'Turn on notifications?',
                style: AppTypography.title1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Stay inspired with daily quote notifications delivered right to your screen.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.totalPages,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: widget.currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.currentPage == index
                          ? AppColors.primary
                          : AppColors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Enable button
              PrimaryButton(
                text: _isPermanentlyDenied
                    ? 'Open Settings'
                    : (_isRequesting
                          ? 'Requesting...'
                          : 'Enable Notifications'),
                onPressed: _isRequesting ? () {} : _handleEnableNotifications,
              ),

              const SizedBox(height: 16),

              // Skip button
              TextButton(
                onPressed: _isRequesting ? null : widget.onSkip,
                child: Text(
                  'Skip for now',
                  style: AppTypography.body2.copyWith(
                    color: _isRequesting
                        ? AppColors.textSecondary.withOpacity(0.5)
                        : AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
