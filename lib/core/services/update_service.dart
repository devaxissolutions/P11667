import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class UpdateService {
  static const String githubApiUrl =
      'https://api.github.com/repos/devaxissolutions/P11667/releases/latest';

  final Dio _dio = Dio();

  Future<bool> isUpdateAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      final response = await _dio.get(githubApiUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = data['tag_name'] as String;
        final currentVersion = await _getCurrentVersion();

        return _isVersionNewer(latestVersion, currentVersion);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('No updates found (404): No releases yet in the repository.');
      } else {
        debugPrint('Error checking for updates: ${e.message}');
      }
    } catch (e) {
      debugPrint('Unexpected error checking for updates: $e');
    }
    return false;
  }

  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  bool _isVersionNewer(String latest, String current) {
    final latestParts = latest.replaceAll('v', '').split('.');
    final currentParts = current.split('.');

    for (int i = 0; i < latestParts.length; i++) {
      final latestNum = int.tryParse(latestParts[i]) ?? 0;
      final currentNum = i < currentParts.length
          ? int.tryParse(currentParts[i]) ?? 0
          : 0;

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
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching release info: $e');
    }
    return null;
  }

  Future<bool> downloadAndInstallUpdate(
    String downloadUrl,
    Function(double) onProgress,
    VoidCallback onCancel,
  ) async {
    try {
      // Request storage permission
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        throw Exception('Storage permission denied');
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'update.apk';
      final filePath = '${tempDir.path}/$fileName';

      // Download APK
      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
        cancelToken: CancelToken(),
      );

      // Install APK by opening it
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception('Failed to open APK file');
      }

      return true;
    } catch (e) {
      debugPrint('Error downloading/installing update: $e');
      return false;
    }
  }
}
