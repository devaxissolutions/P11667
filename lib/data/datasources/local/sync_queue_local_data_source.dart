import 'package:dev_quotes/core/services/offline/sync_operation.dart';
import 'package:dev_quotes/core/utils/logger.dart';
import 'package:hive/hive.dart';

/// Local data source for managing the sync queue using Hive
class SyncQueueLocalDataSource {
  static const String _boxName = 'sync_queue';
  Box<SyncOperation>? _box;

  /// Initialize the Hive box
  Future<void> initialize() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<SyncOperation>(_boxName);
      Logger.d('SyncQueueLocalDataSource initialized with ${_box!.length} operations');
    }
  }

  /// Get the Hive box (throws if not initialized)
  Box<SyncOperation> get _syncBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('SyncQueueLocalDataSource not initialized. Call initialize() first.');
    }
    return _box!;
  }

  /// Add a new sync operation to the queue
  Future<void> addOperation(SyncOperation operation) async {
    await initialize();
    await _syncBox.put(operation.id, operation);
    Logger.d('Added sync operation: ${operation.id}');
  }

  /// Get all pending operations sorted by timestamp
  Future<List<SyncOperation>> getPendingOperations() async {
    await initialize();
    final operations = _syncBox.values
        .where((op) => op.status == SyncOperationStatus.pending)
        .toList();
    
    // Sort by timestamp (oldest first)
    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return operations;
  }

  /// Get all failed operations
  Future<List<SyncOperation>> getFailedOperations() async {
    await initialize();
    return _syncBox.values
        .where((op) => op.status == SyncOperationStatus.failed)
        .toList();
  }

  /// Get all operations (for debugging)
  Future<List<SyncOperation>> getAllOperations() async {
    await initialize();
    return _syncBox.values.toList();
  }

  /// Mark an operation as completed
  Future<void> markOperationCompleted(String operationId) async {
    await initialize();
    final operation = _syncBox.get(operationId);
    if (operation != null) {
      operation.markCompleted();
      await operation.save();
      Logger.d('Marked operation as completed: $operationId');
    }
  }

  /// Mark an operation as failed
  Future<void> markOperationFailed(String operationId, String errorMessage) async {
    await initialize();
    final operation = _syncBox.get(operationId);
    if (operation != null) {
      operation.markFailed(errorMessage);
      operation.incrementRetry();
      await operation.save();
      Logger.d('Marked operation as failed: $operationId (retry: ${operation.retryCount})');
    }
  }

  /// Delete a completed operation from the queue
  Future<void> deleteOperation(String operationId) async {
    await initialize();
    await _syncBox.delete(operationId);
    Logger.d('Deleted operation: $operationId');
  }

  /// Clear all completed operations
  Future<int> clearCompletedOperations() async {
    await initialize();
    final completedOps = _syncBox.values
        .where((op) => op.status == SyncOperationStatus.completed)
        .map((op) => op.id)
        .toList();
    
    await _syncBox.deleteAll(completedOps);
    Logger.d('Cleared ${completedOps.length} completed operations');
    return completedOps.length;
  }

  /// Clear all operations (use with caution)
  Future<void> clearAllOperations() async {
    await initialize();
    await _syncBox.clear();
    Logger.d('Cleared all sync operations');
  }

  /// Get the count of pending operations
  Future<int> getPendingCount() async {
    await initialize();
    return _syncBox.values
        .where((op) => op.status == SyncOperationStatus.pending)
        .length;
  }

  /// Get the count of failed operations
  Future<int> getFailedCount() async {
    await initialize();
    return _syncBox.values
        .where((op) => op.status == SyncOperationStatus.failed)
        .length;
  }

  /// Close the Hive box
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
  }
}
