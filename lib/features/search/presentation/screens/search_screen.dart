import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../quotes/presentation/providers/quote_provider.dart';
import '../../../quotes/presentation/widgets/quote_card.dart';
import '../../../quotes/presentation/widgets/quote_category_chip.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController(
      text: ref.read(searchStatsProvider),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currentQuery = ref.watch(searchStatsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: searchController,
                onChanged: (value) {
                  ref.read(searchStatsProvider.notifier).update(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search authors or topics...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            ref.read(searchStatsProvider.notifier).update('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Trending Topics', style: AppTypography.h3),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((topic) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: QuoteCategoryChip(
                            label: topic,
                            onTap: () {
                              ref
                                  .read(searchStatsProvider.notifier)
                                  .update(topic);
                              searchController.text = topic;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: searchResults.when(
                  data: (quotes) {
                    if (quotes.isEmpty && currentQuery.isNotEmpty) {
                      return Center(
                        child: Text(
                          'No quotes found',
                          style: AppTypography.body1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: quotes.length,
                      itemBuilder: (context, index) {
                        final quote = quotes[index];
                        return QuoteCard(
                          quote: quote,
                          trailing: IconButton(
                            icon: Icon(
                              quote.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: quote.isFavorite
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                            onPressed: () {
                              ref
                                  .read(quotesProvider.notifier)
                                  .toggleFavorite(quote);
                              // Refresh search results to reflect favorite change
                              ref.invalidate(searchResultsProvider);
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
