import 'package:dev_quotes/data/datasources/user_data_source.dart';
import 'package:dev_quotes/data/services/offline/sync_handler.dart';
import 'package:dev_quotes/data/services/offline/sync_operation.dart';

class UserSyncHandler implements SyncHandler {
  final UserDataSource _userDataSource;

  UserSyncHandler(this._userDataSource);

  @override
  Future<void> execute(SyncOperation operation) async {
    switch (operation.type) {
      case SyncOperationType.updateProfile:
        await _userDataSource.saveUserFromJson(operation.data);
        break;
      default:
        throw Exception('Unsupported operation type for UserSyncHandler: ${operation.type}');
    }
  }
}
