import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dev_quotes/core/utils/logger.dart';
import 'package:dev_quotes/data/dto/quote_dto.dart';
import 'package:dev_quotes/data/dto/user_dto.dart';
import 'package:dev_quotes/data/datasources/local/sync_queue_local_data_source.dart';
import 'package:dev_quotes/data/services/offline/sync_operation.dart';
import 'package:dev_quotes/data/services/offline/sync_handler.dart';
import 'package:dev_quotes/core/services/circuit_breaker.dart';

import 'package:dev_quotes/domain/entities/sync_status.dart';

/// Service that manages offline-first synchronization
/// Queues operations when offline and syncs when connectivity is restored
class OfflineSyncService {
  final SyncQueueLocalDataSource _syncQueue;
  final Connectivity _connectivity;
  final CircuitBreaker _circuitBreaker;
  final Map<SyncOperationType, SyncHandler> _handlers;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  OfflineSyncService({
    required SyncQueueLocalDataSource syncQueue,
    required CircuitBreaker circuitBreaker,
    required Map<SyncOperationType, SyncHandler> handlers,
    Connectivity? connectivity,
  }) : _syncQueue = syncQueue,
       _circuitBreaker = circuitBreaker,
       _handlers = handlers,
       _connectivity = connectivity ?? Connectivity();

  /// Initialize the sync service and start listening to connectivity changes
  Future<void> initialize() async {
    Logger.d('Initializing OfflineSyncService');
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    
    // Check initial connectivity and sync if online
    final result = await _connectivity.checkConnectivity();
    await _onConnectivityChanged(result);
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }

  /// Handle connectivity changes
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final hasConnection = !results.contains(ConnectivityResult.none);
    
    if (hasConnection && !_isSyncing) {
      Logger.d('Connectivity restored - starting sync');
      await _processSyncQueue();
    }
  }

  /// Queue a quote creation operation
  Future<void> queueQuoteCreation(QuoteDto quote) async {
    final operation = SyncOperation.createQuote(
      quoteId: quote.id,
      data: quote.toJson(),
      timestamp: DateTime.now(),
    );
    await _syncQueue.addOperation(operation);
    _syncStatusController.add(SyncStatus.pending);
    
    // Try to sync immediately if online
    final result = await _connectivity.checkConnectivity();
    if (!result.contains(ConnectivityResult.none)) {
      await _processSyncQueue();
    }
  }

  /// Queue a quote update operation
  Future<void> queueQuoteUpdate(QuoteDto quote) async {
    final operation = SyncOperation.updateQuote(
      quoteId: quote.id,
      data: quote.toJson(),
      timestamp: DateTime.now(),
    );
    await _syncQueue.addOperation(operation);
    _syncStatusController.add(SyncStatus.pending);
    
    final result = await _connectivity.checkConnectivity();
    if (!result.contains(ConnectivityResult.none)) {
      await _processSyncQueue();
    }
  }

  /// Queue a quote deletion operation
  Future<void> queueQuoteDeletion(String quoteId) async {
    final operation = SyncOperation.deleteQuote(
      quoteId: quoteId,
      timestamp: DateTime.now(),
    );
    await _syncQueue.addOperation(operation);
    _syncStatusController.add(SyncStatus.pending);
    
    final result = await _connectivity.checkConnectivity();
    if (!result.contains(ConnectivityResult.none)) {
      await _processSyncQueue();
    }
  }

  /// Queue a favorite toggle operation
  Future<void> queueFavoriteToggle(String quoteId, bool isFavorite, String userId) async {
    final operation = SyncOperation.toggleFavorite(
      quoteId: quoteId,
      isFavorite: isFavorite,
      userId: userId,
      timestamp: DateTime.now(),
    );
    await _syncQueue.addOperation(operation);
    _syncStatusController.add(SyncStatus.pending);
    
    final result = await _connectivity.checkConnectivity();
    if (!result.contains(ConnectivityResult.none)) {
      await _processSyncQueue();
    }
  }

  /// Queue a profile update operation
  Future<void> queueProfileUpdate(UserDto user) async {
    final operation = SyncOperation.updateProfile(
      userId: user.id,
      data: user.toJson(),
      timestamp: DateTime.now(),
    );
    await _syncQueue.addOperation(operation);
    _syncStatusController.add(SyncStatus.pending);
    
    final result = await _connectivity.checkConnectivity();
    if (!result.contains(ConnectivityResult.none)) {
      await _processSyncQueue();
    }
  }

  /// Process all pending sync operations
  Future<void> _processSyncQueue() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);
    
    try {
      final pendingOperations = await _syncQueue.getPendingOperations();
      
      if (pendingOperations.isEmpty) {
        _syncStatusController.add(SyncStatus.synced);
        _isSyncing = false;
        return;
      }

      Logger.d('Processing ${pendingOperations.length} sync operations');
      
      for (final operation in pendingOperations) {
        try {
          await _circuitBreaker.execute(() => _executeOperation(operation));
          await _syncQueue.markOperationCompleted(operation.id);
        } catch (e) {
          Logger.e('Sync operation failed: ${operation.type}', e);
          await _syncQueue.markOperationFailed(operation.id, e.toString());
          
          if (_circuitBreaker.state == CircuitState.open) {
            Logger.w('Circuit breaker opened - stopping sync processing');
            break;
          }

          // Stop processing if it's an auth error
          if (e.toString().contains('permission-denied') ||
              e.toString().contains('unauthenticated')) {
            break;
          }
        }
      }
      
      final remainingOps = await _syncQueue.getPendingOperations();
      if (remainingOps.isEmpty) {
        _syncStatusController.add(SyncStatus.synced);
      } else {
        _syncStatusController.add(SyncStatus.error);
      }
    } catch (e) {
      Logger.e('Error processing sync queue', e);
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute a single sync operation
  Future<void> _executeOperation(SyncOperation operation) async {
    final handler = _handlers[operation.type];
    if (handler != null) {
      await handler.execute(operation);
    } else {
      throw Exception('No sync handler found for operation type: ${operation.type}');
    }
  }

  /// Force a manual sync
  Future<void> forceSync() async {
    if (!_isSyncing) {
      await _processSyncQueue();
    }
  }

  /// Get count of pending operations
  Future<int> getPendingOperationCount() async {
    final ops = await _syncQueue.getPendingOperations();
    return ops.length;
  }

  /// Clear all pending operations (use with caution)
  Future<void> clearSyncQueue() async {
    await _syncQueue.clearAllOperations();
    _syncStatusController.add(SyncStatus.synced);
  }
}
