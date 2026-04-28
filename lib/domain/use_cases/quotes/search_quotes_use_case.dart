import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/domain/entities/quote.dart';
import 'package:dev_quotes/domain/repositories/quote_repository.dart';

class SearchQuotesUseCase {
  final QuoteRepository _repository;

  SearchQuotesUseCase(this._repository);

  Future<Result<List<Quote>>> execute(String query, {String? category, String? author}) async {
    // Business Rule: Sanitize query
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const Success([]);
    
    // Business Rule: Limit search length
    if (cleanQuery.length > 50) {
      return const Success([]); // Or return failure
    }

    return await _repository.searchQuotes(
      cleanQuery,
      category: category,
      author: author,
    );
  }
}
