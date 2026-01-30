import 'dart:async';
import 'package:dev_quotes/core/utils/logger.dart';

/// MEDIUM SECURITY FIX: Circuit breaker pattern for external API calls
/// Prevents cascading failures and reduces load on failing services
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration timeoutDuration;
  final Duration resetTimeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitState _state = CircuitState.closed;

  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.timeoutDuration = const Duration(seconds: 30),
    this.resetTimeout = const Duration(minutes: 5),
  });

  CircuitState get state => _state;

  bool get isOpen => _state == CircuitState.open;

  bool get isHalfOpen => _state == CircuitState.halfOpen;

  bool get isClosed => _state == CircuitState.closed;

  /// Execute a function with circuit breaker protection
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (isOpen) {
      // Check if we should try half-open
      if (_lastFailureTime != null) {
        final timeSinceLastFailure = DateTime.now().difference(_lastFailureTime!);
        if (timeSinceLastFailure >= resetTimeout) {
          Logger.d('Circuit breaker $name: Moving to half-open state');
          _state = CircuitState.halfOpen;
        } else {
          throw CircuitBreakerOpenException(
            'Circuit breaker $name is open. Try again in ${resetTimeout - timeSinceLastFailure}',
          );
        }
      } else {
        throw CircuitBreakerOpenException('Circuit breaker $name is open');
      }
    }

    try {
      // Execute with timeout
      final result = await operation().timeout(timeoutDuration);
      
      // Success - reset if half-open
      if (isHalfOpen) {
        Logger.d('Circuit breaker $name: Resetting to closed state');
        _reset();
      }
      
      return result;
    } catch (e) {
      _recordFailure();
      rethrow;
    }
  }

  void _recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      Logger.w('Circuit breaker $name: Opening circuit after $_failureCount failures');
      _state = CircuitState.open;
    }
  }

  void _reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _state = CircuitState.closed;
  }

  /// Manually reset the circuit breaker
  void reset() {
    Logger.d('Circuit breaker $name: Manual reset');
    _reset();
  }
}

enum CircuitState { closed, open, halfOpen }

class CircuitBreakerOpenException implements Exception {
  final String message;
  CircuitBreakerOpenException(this.message);

  @override
  String toString() => message;
}
