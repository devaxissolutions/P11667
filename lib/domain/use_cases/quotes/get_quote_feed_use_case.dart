import 'package:dev_quotes/domain/entities/quote.dart';
import 'package:dev_quotes/domain/repositories/quote_repository.dart';

class GetQuoteFeedUseCase {
  final QuoteRepository _repository;

  GetQuoteFeedUseCase(this._repository);

  Stream<List<Quote>> execute(String userId, bool showPublic) {
    if (userId.isEmpty) {
      return _repository.getPublicQuotes();
    }

    final feedStream = _repository.getQuoteFeed(userId, showPublic);
    
    // Business Rule: If user has no quotes and is NOT showing public quotes, 
    // we might want to suggest showing public quotes or provide a default set.
    // This orchestration can be complex with Streams.
    // For now, we return the repository stream and handle specific empty-state 
    // UI logic in the provider/presentation layer using this Use Case.
    
    return feedStream;
  }
}
