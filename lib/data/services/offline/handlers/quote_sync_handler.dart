import 'package:dev_quotes/data/datasources/quote_data_source.dart';
import 'package:dev_quotes/data/services/offline/sync_handler.dart';
import 'package:dev_quotes/data/services/offline/sync_operation.dart';

class QuoteSyncHandler implements SyncHandler {
  final QuoteDataSource _quoteDataSource;

  QuoteSyncHandler(this._quoteDataSource);

  @override
  Future<void> execute(SyncOperation operation) async {
    switch (operation.type) {
      case SyncOperationType.createQuote:
        await _quoteDataSource.addQuoteFromJson(operation.data);
        break;
      case SyncOperationType.updateQuote:
        await _quoteDataSource.updateQuoteFromJson(
          operation.quoteId!,
          operation.data,
        );
        break;
      case SyncOperationType.deleteQuote:
        await _quoteDataSource.deleteQuote(operation.quoteId!, '');
        break;
      case SyncOperationType.toggleFavorite:
        final userId = operation.data['userId'] as String?;
        final isFavorite = operation.data['isFavorite'] as bool? ?? false;
        if (userId != null && operation.quoteId != null) {
          if (isFavorite) {
            await _quoteDataSource.addFavorite(userId, operation.quoteId!);
          } else {
            await _quoteDataSource.removeFavorite(userId, operation.quoteId!);
          }
        }
        break;
      default:
        throw Exception('Unsupported operation type for QuoteSyncHandler: ${operation.type}');
    }
  }
}
