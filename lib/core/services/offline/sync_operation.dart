import 'package:hive/hive.dart';

/// Types of sync operations
@HiveType(typeId: 10)
enum SyncOperationType {
  @HiveField(0)
  createQuote,
  @HiveField(1)
  updateQuote,
  @HiveField(2)
  deleteQuote,
  @HiveField(3)
  toggleFavorite,
  @HiveField(4)
  updateProfile,
}

/// Status of a sync operation
@HiveType(typeId: 11)
enum SyncOperationStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  completed,
  @HiveField(2)
  failed,
}

/// Represents a single sync operation to be queued
@HiveType(typeId: 12)
class SyncOperation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final SyncOperationType type;

  @HiveField(2)
  final Map<String, dynamic> data;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  SyncOperationStatus status;

  @HiveField(5)
  String? errorMessage;

  @HiveField(6)
  int retryCount;

  @HiveField(7)
  String? quoteId;

  @HiveField(8)
  String? userId;

  SyncOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.status = SyncOperationStatus.pending,
    this.errorMessage,
    this.retryCount = 0,
    this.quoteId,
    this.userId,
  });

  /// Factory constructor for creating a quote
  factory SyncOperation.createQuote({
    required String quoteId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) {
    return SyncOperation(
      id: 'create_${quoteId}_${timestamp.millisecondsSinceEpoch}',
      type: SyncOperationType.createQuote,
      quoteId: quoteId,
      data: data,
      timestamp: timestamp,
    );
  }

  /// Factory constructor for updating a quote
  factory SyncOperation.updateQuote({
    required String quoteId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) {
    return SyncOperation(
      id: 'update_${quoteId}_${timestamp.millisecondsSinceEpoch}',
      type: SyncOperationType.updateQuote,
      quoteId: quoteId,
      data: data,
      timestamp: timestamp,
    );
  }

  /// Factory constructor for deleting a quote
  factory SyncOperation.deleteQuote({
    required String quoteId,
    required DateTime timestamp,
  }) {
    return SyncOperation(
      id: 'delete_${quoteId}_${timestamp.millisecondsSinceEpoch}',
      type: SyncOperationType.deleteQuote,
      quoteId: quoteId,
      data: {'quoteId': quoteId},
      timestamp: timestamp,
    );
  }

  /// Factory constructor for toggling favorite
  factory SyncOperation.toggleFavorite({
    required String quoteId,
    required bool isFavorite,
    String? userId,
    required DateTime timestamp,
  }) {
    return SyncOperation(
      id: 'fav_${quoteId}_${isFavorite}_${timestamp.millisecondsSinceEpoch}',
      type: SyncOperationType.toggleFavorite,
      quoteId: quoteId,
      userId: userId,
      data: {
        'quoteId': quoteId,
        'isFavorite': isFavorite,
        'userId': userId,
      },
      timestamp: timestamp,
    );
  }

  /// Factory constructor for updating profile
  factory SyncOperation.updateProfile({
    required String userId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) {
    return SyncOperation(
      id: 'profile_${userId}_${timestamp.millisecondsSinceEpoch}',
      type: SyncOperationType.updateProfile,
      userId: userId,
      data: data,
      timestamp: timestamp,
    );
  }

  /// Increment retry count
  void incrementRetry() {
    retryCount++;
  }

  /// Mark as failed with error message
  void markFailed(String error) {
    status = SyncOperationStatus.failed;
    errorMessage = error;
  }

  /// Mark as completed
  void markCompleted() {
    status = SyncOperationStatus.completed;
    errorMessage = null;
  }

  @override
  String toString() {
    return 'SyncOperation(id: $id, type: $type, status: $status, retryCount: $retryCount)';
  }
}
