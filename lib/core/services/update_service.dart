import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dev_quotes/core/services/circuit_breaker.dart';
import 'package:dev_quotes/core/utils/logger.dart';


enum UpdateCheckResult {
  updateAvailable,
  noUpdate,
  noInternet,
  rateLimitExceeded,
  error,
}

/// Permission check result for update flow
enum PermissionCheckResult {
  granted,
  denied,
  permanentlyDenied,
  error,
}

class UpdateService {
  static const String githubApiUrl =
      'https://api.github.com/repos/devaxissolutions/P11667/releases/latest';

  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();
  static UpdateService get instance => _instance;

  final Dio _dio = Dio(BaseOptions(
    receiveTimeout: const Duration(minutes: 2),
    sendTimeout: const Duration(minutes: 2),
  ));
  
  // MEDIUM SECURITY FIX: Circuit breaker for GitHub API calls
  final CircuitBreaker _circuitBreaker = CircuitBreaker(
    name: 'github_api',
    failureThreshold: 3,
    timeoutDuration: const Duration(seconds: 10),
    resetTimeout: const Duration(minutes: 5),
  );

  Future<UpdateCheckResult> isUpdateAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return UpdateCheckResult.noInternet;
      }

      // MEDIUM SECURITY FIX: Use circuit breaker for GitHub API call
      final response = await _circuitBreaker.execute(() => _dio.get(githubApiUrl));
      if (response.statusCode == 200) {
        final data = response.data;
        final latestTag = data['tag_name'] as String;
        final currentVersion = await _getCurrentVersion();

        if (_isVersionNewer(latestTag, currentVersion)) {
          Logger.d('Update available: $latestTag > $currentVersion');
          return UpdateCheckResult.updateAvailable;
        } else {
          Logger.d('No update needed: $latestTag is not newer than $currentVersion');
          return UpdateCheckResult.noUpdate;
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        Logger.d('GitHub API 404: No releases found or repository is private.');
        return UpdateCheckResult.error;
      } else if (e.response?.statusCode == 403) {
        Logger.d('GitHub API 403: Rate Limit Exceeded');
        return UpdateCheckResult.rateLimitExceeded;
      } else {
        Logger.d('Network error checking for updates: ${e.message}');
      }
    } catch (e) {
      Logger.d('Unexpected error checking for updates: $e');
    }
    return UpdateCheckResult.error;
  }

  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    // Use full version with build number if available (e.g. 1.2.0+5)
    if (packageInfo.buildNumber.isNotEmpty) {
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    }
    return packageInfo.version;
  }

  bool _isVersionNewer(String latest, String current) {
    try {
      // Remove 'v' prefix if present
      final cleanLatest = latest.startsWith('v') ? latest.substring(1) : latest;
      final cleanCurrent = current.startsWith('v') ? current.substring(1) : current;

      final latestVer = Version.parse(cleanLatest);
      final currentVer = Version.parse(cleanCurrent);

      return latestVer > currentVer;
    } catch (e) {
      Logger.d('Semantic version parse failed, falling back to basic comparison: $e');
      return _basicVersionComparison(latest, current);
    }
  }

  bool _basicVersionComparison(String latest, String current) {
    final latestParts = latest.replaceAll('v', '').split(RegExp(r'[.+ ]'));
    final currentParts = current.replaceAll('v', '').split(RegExp(r'[.+ ]'));

    final length = latestParts.length > currentParts.length 
        ? latestParts.length 
        : currentParts.length;

    for (int i = 0; i < length; i++) {
      final latestNum = i < latestParts.length ? int.tryParse(latestParts[i]) ?? 0 : 0;
      final currentNum = i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;

      if (latestNum > currentNum) return true;
      if (latestNum < currentNum) return false;
    }
    return false;
  }

  Future<Map<String, dynamic>?> getLatestReleaseInfo() async {
    try {
      final response = await _dio.get(githubApiUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        final assets = data['assets'] as List?;
        if (assets != null && assets.isNotEmpty) {
          final apkAsset = assets.firstWhere(
            (asset) => (asset['name'] as String).endsWith('.apk'),
            orElse: () => null,
          );
          if (apkAsset != null) {
            return {
              'version': data['tag_name'],
              'downloadUrl': apkAsset['browser_download_url'],
              'releaseNotes': data['body'] ?? '',
              'size': apkAsset['size'] ?? 0,
            };
          }
        }
      }
    } catch (e) {
      Logger.d('Error fetching release info: $e');
    }
    return null;
  }

  /// Check all required permissions for update download and installation
  /// Returns a map with overall result and detailed status for each permission
  Future<Map<String, dynamic>> checkUpdatePermissions() async {
    if (!Platform.isAndroid) {
      return {
        'allGranted': true,
        'storage': PermissionCheckResult.granted,
        'install': PermissionCheckResult.granted,
      };
    }

    // Check storage permission (for Android < 11)
    PermissionCheckResult storageResult;
    try {
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        storageResult = PermissionCheckResult.granted;
      } else if (storageStatus.isPermanentlyDenied) {
        storageResult = PermissionCheckResult.permanentlyDenied;
      } else {
        storageResult = PermissionCheckResult.denied;
      }
    } catch (e) {
      Logger.e('Error checking storage permission', e);
      storageResult = PermissionCheckResult.error;
    }

    // Check install unknown apps permission (for Android 8.0+)
    PermissionCheckResult installResult;
    try {
      final installStatus = await Permission.requestInstallPackages.status;
      if (installStatus.isGranted) {
        installResult = PermissionCheckResult.granted;
      } else if (installStatus.isPermanentlyDenied) {
        installResult = PermissionCheckResult.permanentlyDenied;
      } else {
        installResult = PermissionCheckResult.denied;
      }
    } catch (e) {
      Logger.e('Error checking install permission', e);
      installResult = PermissionCheckResult.error;
    }

    final allGranted = storageResult == PermissionCheckResult.granted && 
                       installResult == PermissionCheckResult.granted;

    return {
      'allGranted': allGranted,
      'storage': storageResult,
      'install': installResult,
    };
  }

  /// Request all required permissions for update
  /// Returns a map with 'success' boolean and detailed results
  Future<Map<String, dynamic>> requestUpdatePermissions() async {
    if (!Platform.isAndroid) {
      return {'success': true};
    }

    final results = <String, dynamic>{};

    // Request storage permission (for Android < 11)
    try {
      final storageStatus = await Permission.storage.request();
      results['storage'] = storageStatus.isGranted;
      results['storagePermanentlyDenied'] = storageStatus.isPermanentlyDenied;
    } catch (e) {
      Logger.e('Error requesting storage permission', e);
      results['storage'] = false;
      results['storageError'] = e.toString();
    }

    // Request install unknown apps permission (for Android 8.0+)
    try {
      final installStatus = await Permission.requestInstallPackages.request();
      results['install'] = installStatus.isGranted;
      results['installPermanentlyDenied'] = installStatus.isPermanentlyDenied;
    } catch (e) {
      Logger.e('Error requesting install permission', e);
      results['install'] = false;
      results['installError'] = e.toString();
    }

    results['success'] = (results['storage'] == true) && (results['install'] == true);
    return results;
  }

  /// Result of the download and install operation
  /// Returns a tuple-like map with 'success' and optional 'error' message
  Future<Map<String, dynamic>> downloadAndInstallUpdate(
    String downloadUrl,
    Function(double) onProgress,
    VoidCallback onCancel,
  ) async {
    // First, check all required permissions
    final permissionCheck = await checkUpdatePermissions();
    if (!permissionCheck['allGranted']) {
      return {
        'success': false,
        'error': _buildPermissionErrorMessage(permissionCheck),
        'permissionDenied': true,
        'storageDenied': permissionCheck['storage'] != PermissionCheckResult.granted,
        'installDenied': permissionCheck['install'] != PermissionCheckResult.granted,
        'storagePermanentlyDenied': permissionCheck['storage'] == PermissionCheckResult.permanentlyDenied,
        'installPermanentlyDenied': permissionCheck['install'] == PermissionCheckResult.permanentlyDenied,
      };
    }

    String? downloadedFilePath;
    
    try {
      // MEDIUM SECURITY FIX: Verify HTTPS and trusted domain
      if (!downloadUrl.startsWith('https://')) {
        return {
          'success': false,
          'error': 'Insecure download URL. Only HTTPS is allowed.',
        };
      }
      
      // Verify domain is trusted (GitHub)
      final uri = Uri.parse(downloadUrl);
      final trustedDomains = ['github.com', 'githubusercontent.com'];
      final isTrusted = trustedDomains.any((domain) => uri.host.endsWith(domain));
      if (!isTrusted) {
        return {
          'success': false,
          'error': 'Untrusted download source.',
        };
      }
      
      // 1. Get temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'update_${DateTime.now().millisecondsSinceEpoch}.apk';
      downloadedFilePath = '${tempDir.path}/$fileName';

      // 2. Download APK first
      Logger.d('Downloading APK to: $downloadedFilePath');
      await _dio.download(
        downloadUrl,
        downloadedFilePath,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );
      
      Logger.d('Download completed successfully');

      // 3. After download completes, request install permission again (Android)
      // Permissions might have been revoked during download
      if (Platform.isAndroid) {
        final permissionResult = await checkUpdatePermissions();
        if (!permissionResult['allGranted']) {
          return {
            'success': false,
            'error': _buildPermissionErrorMessage(permissionResult),
            'permissionDenied': true,
            'storageDenied': permissionResult['storage'] != PermissionCheckResult.granted,
            'installDenied': permissionResult['install'] != PermissionCheckResult.granted,
            'storagePermanentlyDenied': permissionResult['storage'] == PermissionCheckResult.permanentlyDenied,
            'installPermanentlyDenied': permissionResult['install'] == PermissionCheckResult.permanentlyDenied,
          };
        }
      }

      // 4. Install APK
      Logger.d('Installing APK from: $downloadedFilePath');
      final result = await OpenFile.open(downloadedFilePath);
      
      if (result.type != ResultType.done) {
        Logger.d('OpenFile error: ${result.message}');
        return {
          'success': false,
          'error': 'Failed to open APK installer: ${result.message}',
        };
      }

      return {'success': true};
    } catch (e) {
      Logger.d('Error downloading/installing update: $e');
      return {
        'success': false,
        'error': 'Download failed: ${e.toString()}',
      };
    }
  }

  /// Build a user-friendly error message based on permission check results
  String _buildPermissionErrorMessage(Map<String, dynamic> permissionCheck) {
    final List<String> missingPermissions = [];
    
    if (permissionCheck['storage'] != PermissionCheckResult.granted) {
      missingPermissions.add('Storage access');
    }
    if (permissionCheck['install'] != PermissionCheckResult.granted) {
      missingPermissions.add('Install unknown apps');
    }
    
    if (missingPermissions.isEmpty) {
      return 'Required permissions are missing.';
    }
    
    return 'The following permissions are required: ${missingPermissions.join(', ')}. Please grant them in Settings.';
  }

  /// Open app settings so user can manually enable permissions
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Open system settings for install unknown apps permission
  Future<bool> openInstallSettings() async {
    return await openAppSettings();
  }
}
