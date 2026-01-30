import 'dart:async';

/// MEDIUM SECURITY FIX: Mixin to help manage disposable resources
/// Prevents memory leaks by ensuring proper cleanup
mixin DisposableMixin {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  bool _isDisposed = false;

  /// Check if the object has been disposed
  bool get isDisposed => _isDisposed;

  /// Add a stream subscription to be cancelled on dispose
  void addSubscription(StreamSubscription subscription) {
    if (_isDisposed) {
      subscription.cancel();
      return;
    }
    _subscriptions.add(subscription);
  }

  /// Add a timer to be cancelled on dispose
  void addTimer(Timer timer) {
    if (_isDisposed) {
      timer.cancel();
      return;
    }
    _timers.add(timer);
  }

  /// Dispose all resources
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel all timers
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }
}
