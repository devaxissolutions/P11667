import 'package:dev_quotes/core/error/failures.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/data/models/quote_model.dart';

abstract class QuoteRepository {
  Future<Result<Quote>> getRandomQuote();
  Future<Result<List<Quote>>> searchQuotes(
    String query, {
    String? category,
    String? author,
  });
  Future<Result<String>> addQuote(Quote quote);
  Future<Result<void>> updateQuote(Quote quote);
  Stream<List<Quote>> getFavorites(String userId);
  Stream<List<Quote>> getUserQuotes(String userId);
  Stream<List<Quote>> getPublicQuotes();
  Future<Result<void>> addFavorite(String quoteId, String userId);
  Future<Result<void>> removeFavorite(String quoteId, String userId);
  Future<Result<Quote>> getQuoteById(String quoteId);
}
