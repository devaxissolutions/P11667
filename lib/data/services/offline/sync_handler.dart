import 'package:dev_quotes/data/services/offline/sync_operation.dart';

abstract class SyncHandler {
  Future<void> execute(SyncOperation operation);
}
