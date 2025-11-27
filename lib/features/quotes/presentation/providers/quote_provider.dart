import 'dart:async';
import 'package:dev_quotes/core/providers.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/data/models/category_model.dart';
import 'package:dev_quotes/data/models/quote_model.dart';
import 'package:dev_quotes/features/auth/controllers/auth_controller.dart';
import 'package:dev_quotes/features/auth/models/auth_state.dart';
import 'package:dev_quotes/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      final repository = ref.read(quoteRepositoryProvider);

      if (authState is! AuthAuthenticated) {
        // If not authenticated, show public quotes
        final publicQuotes = await repository.getPublicQuotes().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () => <Quote>[],
        );
        state = AsyncValue.data(
          publicQuotes.take(10).toList(),
        ); // Limit to 10 for home
        return;
      }

      if (showPublicQuotes) {
        // Show all public quotes
        final publicQuotes = await repository.getPublicQuotes().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () => <Quote>[],
        );
        state = AsyncValue.data(publicQuotes.take(10).toList());
      } else {
        // Show only user's quotes
        final userQuotes = await repository
            .getUserQuotes(authState.user.id)
            .first
            .timeout(const Duration(seconds: 5), onTimeout: () => <Quote>[]);
        state = AsyncValue.data(userQuotes.take(10).toList());
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(Quote quote) async {
    final authAsync = ref.read(authProvider);
    final authState = authAsync.value;
    if (authState is! AuthAuthenticated) return; // Or prompt login

    final repository = ref.read(quoteRepositoryProvider);
    final userId = authState.user.id;

    // Optimistic update
    state.whenData((quotes) {
      final updatedQuotes = quotes.map((q) {
        if (q.id == quote.id) {
          return Quote(
            id: q.id,
            text: q.text,
            author: q.author,
            category: q.category,
            userId: q.userId,
            timestamp: q.timestamp,
            isFavorite: !q.isFavorite,
          );
        }
        return q;
      }).toList();
      state = AsyncValue.data(updatedQuotes);
    });

    if (quote.isFavorite) {
      await repository.removeFavorite(quote.id, userId);
    } else {
      await repository.addFavorite(quote.id, userId);
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
  final repository = ref.watch(quoteRepositoryProvider);

  // Always fetch public quotes
  final publicQuotesResult = await repository.getPublicQuotes().first;
  final publicQuotes = publicQuotesResult;

  if (query.isEmpty) {
    return publicQuotes;
  }

  // Filter client-side for now
  final lowerQuery = query.toLowerCase();
  final filtered = publicQuotes.where((quote) {
    return quote.text.toLowerCase().contains(lowerQuery) ||
        quote.author.toLowerCase().contains(lowerQuery) ||
        quote.category.toLowerCase().contains(lowerQuery);
  }).toList();

  return filtered;
});

// Categories
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  final result = await categoryRepository.getCategories();
  if (result is Success<List<Category>>) {
    return result.data.map((c) => c.name).toSet().toList();
  }
  return [];
});
