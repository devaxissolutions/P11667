import 'package:dev_quotes/core/error/failures.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/data/datasources/firestore_data_source.dart';
import 'package:dev_quotes/data/datasources/local_data_source.dart';
import 'package:dev_quotes/data/mappers/quote_mapper.dart';
import 'package:dev_quotes/data/models/quote_model.dart';
import 'package:dev_quotes/data/repositories/interfaces/quote_repository.dart';

class QuoteRepositoryImpl implements QuoteRepository {
  final FirestoreDataSource _firestoreDataSource;
  final LocalDataSource _localDataSource;

  QuoteRepositoryImpl({
    required FirestoreDataSource firestoreDataSource,
    required LocalDataSource localDataSource,
  }) : _firestoreDataSource = firestoreDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Result<Quote>> getRandomQuote() async {
    try {
      // Try network
      final quoteDto = await _firestoreDataSource.getRandomQuote();
      await _localDataSource.cacheLastQuote(quoteDto);
      return Success(QuoteMapper.toDomain(quoteDto));
    } catch (e) {
      // Fallback to cache
      try {
        final cachedQuote = await _localDataSource.getLastQuote();
        if (cachedQuote != null) {
          return Success(QuoteMapper.toDomain(cachedQuote));
        }
        return Error(CacheFailure('No cached quote found'));
      } catch (cacheError) {
        return Error(CacheFailure(cacheError.toString()));
      }
    }
  }

  @override
  Future<Result<List<Quote>>> searchQuotes(
    String query, {
    String? category,
    String? author,
  }) async {
    try {
      // If category is provided, we might use getQuotesByCategory and filter?
      // Or just searchQuotes (which currently only does text search).
      // For now, we use searchQuotes and filter in memory if needed, or update DataSource to support complex queries.
      // Given the DataSource implementation, let's just use searchQuotes.
      final dtos = await _firestoreDataSource.searchQuotes(query);
      final quotes = dtos.map((dto) => QuoteMapper.toDomain(dto)).toList();

      // In-memory filtering for category/author if not handled by Firestore query
      var filtered = quotes;
      if (category != null) {
        filtered = filtered.where((q) => q.category == category).toList();
      }
      if (author != null) {
        filtered = filtered.where((q) => q.author.contains(author)).toList();
      }

      return Success(filtered);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> addQuote(Quote quote) async {
    try {
      await _firestoreDataSource.addQuote(QuoteMapper.fromDomain(quote));
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateQuote(Quote quote) async {
    try {
      await _firestoreDataSource.updateQuote(QuoteMapper.fromDomain(quote));
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Quote>> getFavorites(String userId) {
    return _firestoreDataSource.getFavoritesIds(userId).asyncMap((ids) async {
      if (ids.isEmpty) return [];
      final dtos = await _firestoreDataSource.getQuotesByIds(ids);
      return dtos
          .map((dto) => QuoteMapper.toDomain(dto, isFavorite: true))
          .toList();
    });
  }

  @override
  Stream<List<Quote>> getUserQuotes(String userId) {
    return _firestoreDataSource.getUserQuotes(userId).map((dtos) {
      return dtos.map((dto) => QuoteMapper.toDomain(dto)).toList();
    });
  }

  @override
  Stream<List<Quote>> getPublicQuotes() {
    return _firestoreDataSource.getPublicQuotes().map((dtos) {
      return dtos.map((dto) => QuoteMapper.toDomain(dto)).toList();
    });
  }

  @override
  Future<Result<void>> addFavorite(String quoteId, String userId) async {
    try {
      await _firestoreDataSource.addFavorite(userId, quoteId);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> removeFavorite(String quoteId, String userId) async {
    try {
      await _firestoreDataSource.removeFavorite(userId, quoteId);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Quote>>> getQuotesByCategory(String categoryId) async {
    try {
      final dtos = await _firestoreDataSource.getQuotesByCategory(categoryId);
      return Success(dtos.map((dto) => QuoteMapper.toDomain(dto)).toList());
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}
