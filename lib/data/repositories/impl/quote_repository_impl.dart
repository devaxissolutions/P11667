import 'package:dev_quotes/core/error/failures.dart';
import 'package:dev_quotes/core/services/rate_limit_service.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:dev_quotes/data/datasources/local_data_source.dart';
import 'package:dev_quotes/data/mappers/quote_mapper.dart';
import 'package:dev_quotes/domain/entities/quote.dart';
import 'package:dev_quotes/domain/repositories/quote_repository.dart';

import 'package:dev_quotes/data/datasources/quote_data_source.dart';
import 'package:dev_quotes/data/services/offline/offline_sync_service.dart';

class QuoteRepositoryImpl implements QuoteRepository {
  final QuoteDataSource _quoteDataSource;
  final LocalDataSource _localDataSource;
  final RateLimitService? _rateLimitService;
  final OfflineSyncService _syncService;
  final Connectivity _connectivity;

  QuoteRepositoryImpl({
    required QuoteDataSource quoteDataSource,
    required LocalDataSource localDataSource,
    required OfflineSyncService syncService,
    RateLimitService? rateLimitService,
    Connectivity? connectivity,
  }) : _quoteDataSource = quoteDataSource,
       _localDataSource = localDataSource,
       _syncService = syncService,
       _rateLimitService = rateLimitService,
       _connectivity = connectivity ?? Connectivity();

  @override
  Future<Result<Quote>> getRandomQuote() async {
    try {
      final quoteDto = await _quoteDataSource.getRandomQuote();
      await _localDataSource.cacheLastQuote(quoteDto);
      return Success(QuoteMapper.toDomain(quoteDto));
    } catch (e) {
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
      final dtos = await _quoteDataSource.searchQuotes(query);
      final quotes = dtos.map((dto) => QuoteMapper.toDomain(dto)).toList();

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
  Future<Result<String>> addQuote(Quote quote) async {
    if (_rateLimitService != null) {
      final rateLimitKey = 'add_quote_${quote.userId}';
      if (_rateLimitService.isLocked(rateLimitKey)) {
        return Error(RateLimitFailure(
          'You are creating quotes too quickly. Please wait a moment.'
        ));
      }
    }

    final quoteDto = QuoteMapper.fromDomain(quote);

    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        await _syncService.queueQuoteCreation(quoteDto);
        return Success(quoteDto.id);
      }

      final id = await _quoteDataSource.addQuote(quoteDto);
      _rateLimitService?.recordAttempt('add_quote_${quote.userId}');
      return Success(id);
    } catch (e) {
      // If server fails, queue for sync as fallback
      await _syncService.queueQuoteCreation(quoteDto);
      return Success(quoteDto.id);
    }
  }

  @override
  Future<Result<void>> updateQuote(Quote quote) async {
    final quoteDto = QuoteMapper.fromDomain(quote);
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        await _syncService.queueQuoteUpdate(quoteDto);
        return const Success(null);
      }

      await _quoteDataSource.updateQuote(quoteDto);
      return const Success(null);
    } catch (e) {
      await _syncService.queueQuoteUpdate(quoteDto);
      return const Success(null);
    }
  }

  @override
  Future<Result<void>> deleteQuote(String quoteId, String currentUserId) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        await _syncService.queueQuoteDeletion(quoteId);
        return const Success(null);
      }

      await _quoteDataSource.deleteQuote(quoteId, currentUserId);
      return const Success(null);
    } catch (e) {
      await _syncService.queueQuoteDeletion(quoteId);
      return const Success(null);
    }
  }

  @override
  Stream<List<Quote>> getFavorites(String userId) {
    return _quoteDataSource.getFavoritesIds(userId).asyncMap((ids) async {
      if (ids.isEmpty) return [];
      final dtos = await _quoteDataSource.getQuotesByIds(ids);
      return dtos
          .map((dto) => QuoteMapper.toDomain(dto, isFavorite: true))
          .toList();
    });
  }

  @override
  Stream<List<Quote>> getUserQuotes(String userId) {
    return _quoteDataSource.getUserQuotes(userId).map((dtos) {
      return dtos.map((dto) => QuoteMapper.toDomain(dto)).toList();
    });
  }

  @override
  Stream<List<Quote>> getPublicQuotes() {
    return _quoteDataSource.getPublicQuotes().map((dtos) {
      return dtos.map((dto) => QuoteMapper.toDomain(dto)).toList();
    });
  }

  @override
  Stream<List<Quote>> getQuoteFeed(String userId, bool showPublic) {
    return _quoteDataSource.getQuoteFeed(userId, showPublic).map((dtos) {
      return dtos.map((dto) => QuoteMapper.toDomain(dto)).toList();
    });
  }

  @override
  Future<Result<void>> addFavorite(String quoteId, String userId) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        await _syncService.queueFavoriteToggle(quoteId, true, userId);
        return const Success(null);
      }

      await _quoteDataSource.addFavorite(userId, quoteId);
      return const Success(null);
    } catch (e) {
      await _syncService.queueFavoriteToggle(quoteId, true, userId);
      return const Success(null);
    }
  }

  @override
  Future<Result<void>> removeFavorite(String quoteId, String userId) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        await _syncService.queueFavoriteToggle(quoteId, false, userId);
        return const Success(null);
      }

      await _quoteDataSource.removeFavorite(userId, quoteId);
      return const Success(null);
    } catch (e) {
      await _syncService.queueFavoriteToggle(quoteId, false, userId);
      return const Success(null);
    }
  }

  @override
  Future<Result<Quote>> getQuoteById(String quoteId) async {
    try {
      final dto = await _quoteDataSource.getQuoteById(quoteId);
      if (dto == null) {
        return Error(ServerFailure('Quote not found'));
      }
      return Success(QuoteMapper.toDomain(dto));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}
