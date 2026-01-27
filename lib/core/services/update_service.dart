import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


enum UpdateCheckResult {
  updateAvailable,
  noUpdate,
  noInternet,
  rateLimitExceeded,
  error,
}

class UpdateService {
  static const String githubApiUrl =
      'https://api.github.com/repos/devaxissolutions/P11667/releases/latest';

  final Dio _dio = Dio(BaseOptions(
    receiveTimeout: const Duration(minutes: 2),
    sendTimeout: const Duration(minutes: 2),
  ));

  Future<UpdateCheckResult> isUpdateAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return UpdateCheckResult.noInternet;
      }

      final response = await _dio.get(githubApiUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        final latestTag = data['tag_name'] as String;
        final currentVersion = await _getCurrentVersion();

        debugPrint('Checking versions: Latest=$latestTag, Current=$currentVersion');

        if (_isVersionNewer(latestTag, currentVersion)) {
          debugPrint('Update available: $latestTag > $currentVersion');
          return UpdateCheckResult.updateAvailable;
        } else {
          debugPrint('No update needed: $latestTag is not newer than $currentVersion');
          return UpdateCheckResult.noUpdate;
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('GitHub API 404: No releases found or repository is private.');
        return UpdateCheckResult.error;
      } else if (e.response?.statusCode == 403) {
        debugPrint('GitHub API 403: Rate Limit Exceeded');
        return UpdateCheckResult.rateLimitExceeded;
      } else {
        debugPrint('Network error checking for updates: ${e.message}');
      }
    } catch (e) {
      debugPrint('Unexpected error checking for updates: $e');
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
      debugPrint('Semantic version parse failed, falling back to basic comparison: $e');
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
      debugPrint('Error fetching release info: $e');
    }
    return null;
  }

  /// Result of the download and install operation
  /// Returns a tuple-like map with 'success' and optional 'error' message
  Future<Map<String, dynamic>> downloadAndInstallUpdate(
    String downloadUrl,
    Function(double) onProgress,
    VoidCallback onCancel,
  ) async {
    String? downloadedFilePath;
    
    try {
      // 1. Get temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'update_${DateTime.now().millisecondsSinceEpoch}.apk';
      downloadedFilePath = '${tempDir.path}/$fileName';

      // 2. Download APK first
      debugPrint('Downloading APK to: $downloadedFilePath');
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
      
      debugPrint('Download completed successfully');

      // 3. After download completes, request install permission (Android)
      if (Platform.isAndroid) {
        final permissionResult = await _requestInstallPermission();
        if (!permissionResult['granted']) {
          return {
            'success': false,
            'error': permissionResult['error'] ?? 'Install permission denied',
            'permissionDenied': true,
            'permanentlyDenied': permissionResult['permanentlyDenied'] ?? false,
          };
        }
      }

      // 4. Install APK
      debugPrint('Installing APK from: $downloadedFilePath');
      final result = await OpenFile.open(downloadedFilePath);
      
      if (result.type != ResultType.done) {
        debugPrint('OpenFile error: ${result.message}');
        return {
          'success': false,
          'error': 'Failed to open APK installer: ${result.message}',
        };
      }

      return {'success': true};
    } catch (e) {
      debugPrint('Error downloading/installing update: $e');
      return {
        'success': false,
        'error': 'Download failed: ${e.toString()}',
      };
    }
  }

  /// Request the install packages permission on Android
  /// Returns a map with 'granted' boolean and optional 'error' message
  Future<Map<String, dynamic>> _requestInstallPermission() async {
    try {
      // Check current permission status
      var status = await Permission.requestInstallPackages.status;
      debugPrint('Current install permission status: $status');

      if (status.isGranted) {
        return {'granted': true};
      }

      // If permanently denied, we need to open settings
      if (status.isPermanentlyDenied) {
        debugPrint('Install permission is permanently denied');
        return {
          'granted': false,
          'error': 'Permission to install apps is permanently denied. Please enable it in Settings.',
          'permanentlyDenied': true,
        };
      }

      // Request permission
      debugPrint('Requesting install permission...');
      status = await Permission.requestInstallPackages.request();
      debugPrint('Permission request result: $status');

      if (status.isGranted) {
        return {'granted': true};
      }

      // Check if now permanently denied after request
      if (status.isPermanentlyDenied) {
        return {
          'granted': false,
          'error': 'Permission to install apps was denied. Please enable it in Settings to install updates.',
          'permanentlyDenied': true,
        };
      }

      return {
        'granted': false,
        'error': 'Permission to install apps was denied. The update cannot be installed without this permission.',
        'permanentlyDenied': false,
      };
    } catch (e) {
      debugPrint('Error requesting install permission: $e');
      return {
        'granted': false,
        'error': 'Failed to request install permission: ${e.toString()}',
      };
    }
  }

  /// Open app settings so user can manually enable the install permission
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}
