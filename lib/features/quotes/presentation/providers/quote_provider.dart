import 'dart:async';
import 'package:dev_quotes/di/service_locator.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/domain/entities/quote.dart';
import 'package:dev_quotes/domain/entities/category.dart';
import 'package:dev_quotes/features/auth/controllers/auth_controller.dart';
import 'package:dev_quotes/features/auth/models/auth_state.dart';
import 'package:dev_quotes/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_quotes/core/performance/perf_service.dart';

// State for the list of quotes (Home Screen)
class QuotesNotifier extends Notifier<AsyncValue<List<Quote>>> {
  @override
  AsyncValue<List<Quote>> build() {
    // Listen to settings changes
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.showPublicQuotes != next.showPublicQuotes) {
        loadQuotes(next.showPublicQuotes, ref.read(authProvider).value);
      }
    });

    // Listen to auth changes
    ref.listen(authProvider, (previous, next) {
      if (previous?.value != next.value) {
        loadQuotes(ref.read(settingsProvider).showPublicQuotes, next.value);
      }
    });

    // Initial load
    loadQuotes(
      ref.read(settingsProvider).showPublicQuotes,
      ref.read(authProvider).value,
    );
    return const AsyncValue.loading();
  }

  Future<void> loadQuotes(bool showPublicQuotes, AuthState? authState) async {
    try {
      state = const AsyncValue.loading();
      final getQuoteFeedUseCase = ref.read(getQuoteFeedUseCaseProvider);
      
      String userId = '';
      if (authState is AuthAuthenticated) {
        userId = authState.user.id;
      }

      final quotesStream = getQuoteFeedUseCase.execute(userId, showPublicQuotes);
      
      final quotes = await PerfService.trace(
        "load_quotes_feed_trace",
        () async => await quotesStream.first.timeout(
          const Duration(seconds: 5),
          onTimeout: () => <Quote>[],
        ),
      );
      
      // Fallback: If user has no quotes and default quotes are also missing, 
      // show public quotes regardless of setting.
      if (quotes.isEmpty && !showPublicQuotes && userId.isNotEmpty) {
        final fallbackQuotes = await getQuoteFeedUseCase
            .execute(userId, true)
            .first
            .timeout(const Duration(seconds: 5), onTimeout: () => <Quote>[]);
        state = AsyncValue.data(fallbackQuotes.take(10).toList());
      } else {
        state = AsyncValue.data(quotes.take(10).toList());
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(Quote quote) async {
    final authAsync = ref.read(authProvider);
    final authState = authAsync.value;
    if (authState is! AuthAuthenticated) return;

    final toggleFavoriteUseCase = ref.read(toggleFavoriteUseCaseProvider);
    final userId = authState.user.id;

    // Optimistic update
    state.whenData((quotes) {
      final updatedQuotes = quotes.map((q) {
        if (q.id == quote.id) {
          return q.copyWith(isFavorite: !q.isFavorite);
        }
        return q;
      }).toList();
      state = AsyncValue.data(updatedQuotes);
    });

    final result = await toggleFavoriteUseCase.execute(
      quote.id,
      userId,
      quote.isFavorite,
    );
    
    if (result is Error) {
      // Revert on error
      loadQuotes(
        ref.read(settingsProvider).showPublicQuotes,
        ref.read(authProvider).value,
      );
    }
  }

  void shuffle() {
    state.whenData((quotes) {
      final shuffled = List<Quote>.from(quotes)..shuffle();
      state = AsyncValue.data(shuffled);
    });
  }
}

final quotesProvider =
    NotifierProvider<QuotesNotifier, AsyncValue<List<Quote>>>(
      QuotesNotifier.new,
    );

// Provider for the current quote index on Home Screen
class CurrentQuoteIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

final currentQuoteIndexProvider =
    NotifierProvider<CurrentQuoteIndexNotifier, int>(
      CurrentQuoteIndexNotifier.new,
    );

// Provider for favorites
final favoritesProvider = StreamProvider<List<Quote>>((ref) {
  final authAsync = ref.watch(authProvider);
  final authState = authAsync.value;
  if (authState is AuthAuthenticated) {
    final repository = ref.watch(quoteRepositoryProvider);
    return repository.getFavorites(authState.user.id);
  }
  return Stream.value([]);
});

// Provider for my quotes
final myQuotesProvider = StreamProvider<List<Quote>>((ref) {
  final authAsync = ref.watch(authProvider);
  final authState = authAsync.value;
  if (authState is AuthAuthenticated) {
    final repository = ref.watch(quoteRepositoryProvider);
    return repository.getUserQuotes(authState.user.id);
  }
  return Stream.value([]);
});

// Provider for updating quotes
class UpdateQuoteNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> updateQuote(Quote quote) async {
    state = const AsyncValue.loading();
    final repository = ref.read(quoteRepositoryProvider);
    final result = await repository.updateQuote(quote);
    if (result is Success) {
      state = const AsyncValue.data(null);
    } else if (result is Error) {
      state = AsyncValue.error(result.failure, StackTrace.current);
    }
  }
}

final updateQuoteProvider =
    NotifierProvider<UpdateQuoteNotifier, AsyncValue<void>>(
      UpdateQuoteNotifier.new,
    );

// Search
class SearchStatsNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final searchStatsProvider = NotifierProvider<SearchStatsNotifier, String>(
  SearchStatsNotifier.new,
);

final searchResultsProvider = FutureProvider<List<Quote>>((ref) async {
  final query = ref.watch(searchStatsProvider);
  if (query.isEmpty) return [];

  final searchUseCase = ref.watch(searchQuotesUseCaseProvider);

  // Get favorites to check status
  final favoritesAsync = ref.watch(favoritesProvider);
  final favoriteIds = favoritesAsync.value?.map((q) => q.id).toSet() ?? {};

  final result = await PerfService.trace(
    "search_quotes_trace",
    () async => await searchUseCase.execute(query),
  );

  if (result is Success<List<Quote>>) {
    return result.data.map((quote) {
      return quote.copyWith(
        isFavorite: favoriteIds.contains(quote.id),
      );
    }).toList();
  }
  
  return [];
});

// Provider for single quote by ID
final quoteByIdProvider = FutureProvider.family<Quote?, String>((
  ref,
  quoteId,
) async {
  final repository = ref.watch(quoteRepositoryProvider);
  final result = await repository.getQuoteById(quoteId);
  if (result is Success<Quote>) {
    return result.data;
  }
  return null;
});

// Categories
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  final result = await categoryRepo.getCategories();
  if (result is Success<List<Category>>) {
    return result.data.map((c) => c.name).toList();
  }
  return [];
});
