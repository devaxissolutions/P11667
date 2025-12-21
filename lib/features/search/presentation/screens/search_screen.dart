import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../quotes/presentation/providers/quote_provider.dart';
import '../../../quotes/presentation/widgets/quote_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController searchController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController(
      text: ref.read(searchStatsProvider),
    );
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currentQuery = ref.watch(searchStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ModernSearchBar(
                      controller: searchController,
                      focusNode: _focusNode,
                      onChanged: (value) {
                        ref.read(searchStatsProvider.notifier).update(value);
                      },
                      onClear: () {
                        searchController.clear();
                        ref.read(searchStatsProvider.notifier).update('');
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Trending Topics',
                          style: AppTypography.h3.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: categories.map((topic) {
                            final isSelected = currentQuery == topic;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _CategoryPill(
                                label: topic,
                                isSelected: isSelected,
                                onTap: () {
                                  if (isSelected) {
                                    ref.read(searchStatsProvider.notifier).update('');
                                    searchController.clear();
                                  } else {
                                    ref.read(searchStatsProvider.notifier).update(topic);
                                    searchController.text = topic;
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            searchResults.when(
              data: (quotes) {
                if (quotes.isEmpty) {
                  if (currentQuery.isNotEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No results found',
                                style: AppTypography.body1.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final quote = quotes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: QuoteCard(
                            quote: quote,
                            trailing: IconButton(
                              icon: Icon(
                                quote.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: quote.isFavorite
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                              onPressed: () {
                                ref.read(quotesProvider.notifier).toggleFavorite(quote);
                                ref.invalidate(searchResultsProvider);
                              },
                            ),
                          ),
                        );
                      },
                      childCount: quotes.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _ModernSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppColors.primary
              : Colors.white.withOpacity(0.05),
          width: 1.5,
        ),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search authors, topics, or keywords...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: focusNode.hasFocus ? AppColors.primary : AppColors.textSecondary,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        cursorColor: AppColors.primary,
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
