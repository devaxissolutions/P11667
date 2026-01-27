import 'package:shared_preferences/shared_preferences.dart';

class RateLimitService {
  final SharedPreferences _prefs;

  static const int maxAttempts = 5;
  static const int lockTimeMinutes = 15;
  static const int windowMinutes = 5;

  RateLimitService(this._prefs);

  bool isLocked(String key) {
    final lockUntil = _prefs.getInt('ratelimit_${key}_lock_until') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now < lockUntil;
  }

  int getRemainingLockTime(String key) {
    final lockUntil = _prefs.getInt('ratelimit_${key}_lock_until') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = lockUntil - now;
    return remaining > 0 ? (remaining / 1000).ceil() : 0;
  }

  void recordAttempt(String key) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final attempts = _prefs.getStringList('ratelimit_${key}_attempts') ?? [];

    // Cleanup old attempts outside the window
    final windowStart = now - (windowMinutes * 60 * 1000);
    final validAttempts = attempts
        .where((a) {
          final timestamp = int.tryParse(a);
          return timestamp != null && timestamp > windowStart;
        })
        .toList();

    validAttempts.add(now.toString());

    if (validAttempts.length >= maxAttempts) {
      final lockUntil = now + (lockTimeMinutes * 60 * 1000);
      _prefs.setInt('ratelimit_${key}_lock_until', lockUntil);
    }

    _prefs.setStringList('ratelimit_${key}_attempts', validAttempts);
  }

  void clearAttempts(String key) {
    _prefs.remove('ratelimit_${key}_attempts');
    _prefs.remove('ratelimit_${key}_lock_until');
  }

  String getLockMessage(String key) {
    final seconds = getRemainingLockTime(key);
    final minutes = (seconds / 60).ceil();
    return 'Too many attempts. Please try again in $minutes minute${minutes > 1 ? 's' : ''}.';
  }
}
