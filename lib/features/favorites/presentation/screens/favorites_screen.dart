import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../quotes/presentation/providers/quote_provider.dart';
import '../../../quotes/presentation/widgets/quote_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

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
                      'Your Favorites',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            favoritesAsync.when(
              data: (favorites) {
                if (favorites.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.1),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite_border_rounded,
                              size: 48,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No favorites yet',
                            style: AppTypography.h3.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the heart on any quote\nto save it here.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 100), // Spacing for fab/nav if needed
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final quote = favorites[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Dismissible(
                            key: ValueKey(quote.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                                size: 28,
                              ),
                            ),
                            onDismissed: (_) {
                              ref
                                  .read(quotesProvider.notifier)
                                  .toggleFavorite(quote);
                            },
                            child: QuoteCard(
                              quote: quote,
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.favorite_rounded,
                                  color: AppColors.error,
                                  size: 24,
                                ),
                                onPressed: () {
                                  ref
                                      .read(quotesProvider.notifier)
                                      .toggleFavorite(quote);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: favorites.length,
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
