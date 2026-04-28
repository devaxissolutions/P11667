import 'package:dio/dio.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Map<String, dynamic>? _latestReleaseCache;

  Future<UpdateCheckResult> isUpdateAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return UpdateCheckResult.noInternet;
      }

      // Use circuit breaker for GitHub API call
      final response = await _circuitBreaker.execute(() => _dio.get(githubApiUrl));
      if (response.statusCode == 200) {
        final data = response.data;
        _latestReleaseCache = data;
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

  Future<Map<String, dynamic>?> getLatestReleaseInfo() async {
    if (_latestReleaseCache == null) {
      await isUpdateAvailable();
    }

    if (_latestReleaseCache != null) {
      return {
        'version': _latestReleaseCache!['tag_name'],
        'releaseNotes': _latestReleaseCache!['body'],
        'downloadUrl': _latestReleaseCache!['html_url'],
      };
    }
    return null;
  }

  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (packageInfo.buildNumber.isNotEmpty) {
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    }
    return packageInfo.version;
  }

  bool _isVersionNewer(String latest, String current) {
    try {
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

  /// Redirect to Play Store for updates
  Future<void> launchPlayStore() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final packageName = packageInfo.packageName;
    final url = Uri.parse('market://details?id=$packageName');
    final webUrl = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Logger.e('Could not launch Play Store', e);
    }
  }

  /// Open app settings so user can manually enable permissions
  Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }
}
