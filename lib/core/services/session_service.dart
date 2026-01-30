import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dev_quotes/core/utils/logger.dart';

/// MEDIUM SECURITY FIX: Session management service
/// Handles automatic token refresh and session timeout
class SessionService {
  static const Duration _tokenRefreshInterval = Duration(hours: 1);
  static const Duration _sessionTimeout = Duration(hours: 24);
  
  Timer? _refreshTimer;
  DateTime? _sessionStartTime;
  
  /// Initialize session management
  void initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _sessionStartTime = DateTime.now();
      _startTokenRefresh(user);
    }
    
    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _sessionStartTime = DateTime.now();
        _startTokenRefresh(user);
      } else {
        _stopTokenRefresh();
      }
    });
  }
  
  /// Start automatic token refresh
  void _startTokenRefresh(User user) {
    _stopTokenRefresh();
    
    _refreshTimer = Timer.periodic(_tokenRefreshInterval, (_) async {
      try {
        // Check session timeout
        if (_sessionStartTime != null) {
          final sessionDuration = DateTime.now().difference(_sessionStartTime!);
          if (sessionDuration > _sessionTimeout) {
            Logger.w('Session timeout reached, signing out');
            await FirebaseAuth.instance.signOut();
            return;
          }
        }
        
        // Force token refresh
        await user.getIdToken(true);
        Logger.d('Token refreshed successfully');
      } catch (e) {
        Logger.e('Failed to refresh token', e);
      }
    });
  }
  
  /// Stop token refresh timer
  void _stopTokenRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
  
  /// Dispose service
  void dispose() {
    _stopTokenRefresh();
  }
  
  /// Check if session is still valid
  bool get isSessionValid {
    if (_sessionStartTime == null) return false;
    final sessionDuration = DateTime.now().difference(_sessionStartTime!);
    return sessionDuration <= _sessionTimeout;
  }
  
  /// Get remaining session time
  Duration? get remainingSessionTime {
    if (_sessionStartTime == null) return null;
    final elapsed = DateTime.now().difference(_sessionStartTime!);
    final remaining = _sessionTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
