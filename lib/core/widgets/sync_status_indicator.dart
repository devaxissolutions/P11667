import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_quotes/core/services/offline/offline_sync_service.dart';
import 'package:dev_quotes/core/theme/colors.dart';

/// Widget that displays the current sync status
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, return an empty container as the sync service provider
    // needs to be properly set up. This can be enhanced later with a
// proper stream-based sync status provider.
    return const SizedBox.shrink();
  }
}

/// A more comprehensive sync status indicator that can be used in the app bar
class SyncStatusIcon extends StatelessWidget {
  final SyncStatus status;
  final int pendingCount;

  const SyncStatusIcon({
    super.key,
    required this.status,
    this.pendingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String tooltip;

    switch (status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        color = Colors.green;
        tooltip = 'All changes synced';
        break;
      case SyncStatus.pending:
        icon = Icons.cloud_off;
        color = Colors.orange;
        tooltip = pendingCount > 0 
            ? '$pendingCount changes pending sync' 
            : 'Changes pending sync';
        break;
      case SyncStatus.syncing:
        icon = Icons.cloud_sync;
        color = AppColors.primary;
        tooltip = 'Syncing...';
        break;
      case SyncStatus.error:
        icon = Icons.cloud_off;
        color = Colors.red;
        tooltip = 'Sync error. Tap to retry.';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: status == SyncStatus.syncing
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          : Icon(icon, color: color, size: 24),
    );
  }
}

/// A banner that shows when the app is offline
class OfflineBanner extends StatelessWidget {
  final bool isVisible;
  final VoidCallback? onTap;

  const OfflineBanner({
    super.key,
    required this.isVisible,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: Colors.orange,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'You\'re offline. Changes will sync when connected.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A snackbar that shows sync status changes
class SyncStatusSnackBar extends SnackBar {
  SyncStatusSnackBar({
    super.key,
    required SyncStatus status,
    int pendingCount = 0,
  }) : super(
          content: _SyncStatusContent(status: status, pendingCount: pendingCount),
          duration: status == SyncStatus.syncing 
              ? const Duration(days: 1) // Keep showing while syncing
              : const Duration(seconds: 3),
          backgroundColor: _getBackgroundColor(status),
        );

  static Color _getBackgroundColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.syncing:
        return AppColors.primary;
      case SyncStatus.error:
        return Colors.red;
    }
  }
}

class _SyncStatusContent extends StatelessWidget {
  final SyncStatus status;
  final int pendingCount;

  const _SyncStatusContent({
    required this.status,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    switch (status) {
      case SyncStatus.synced:
        message = 'All changes synced';
        icon = Icons.cloud_done;
        break;
      case SyncStatus.pending:
        message = pendingCount > 0 
            ? '$pendingCount changes pending' 
            : 'Changes pending sync';
        icon = Icons.cloud_off;
        break;
      case SyncStatus.syncing:
        message = 'Syncing changes...';
        icon = Icons.cloud_sync;
        break;
      case SyncStatus.error:
        message = 'Sync failed. Will retry automatically.';
        icon = Icons.error_outline;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
