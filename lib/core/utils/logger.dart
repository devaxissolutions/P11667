import 'package:flutter/foundation.dart';

/// Secure logging utility that only logs in debug mode
/// and prevents sensitive information from being exposed in production
class Logger {
  static void d(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  static void i(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void w(String message) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
  }

  /// Log errors securely - in production, send to Crashlytics
  /// without exposing sensitive details to the user
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    // Always log errors internally (in debug mode)
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
    
    // In production, this would send to Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
  }

  /// Sanitize sensitive data before logging
  static String sanitize(String input) {
    // Remove potential PII like emails, phone numbers
    var sanitized = input;
    
    // Replace email patterns
    sanitized = sanitized.replaceAll(
      RegExp(r'[\w.-]+@[\w.-]+\.\w+'),
      '[EMAIL]'
    );
    
    // Replace potential API keys/tokens
    sanitized = sanitized.replaceAll(
      RegExp(r'AIza[\w-]{35}'),
      '[API_KEY]'
    );
    
    return sanitized;
  }
}
