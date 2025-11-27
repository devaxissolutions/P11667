import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  /// Request notification permission from the user
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return true;
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
      case PermissionStatus.permanentlyDenied:
        return false;
      default:
        return false;
    }
  }

  /// Check if notification permission is already granted
  Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  /// Open app settings if permission is permanently denied
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
