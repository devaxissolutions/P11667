import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../quotes/presentation/providers/quote_provider.dart';
import '../../../quotes/presentation/widgets/quote_action_bar.dart';
import '../../../quotes/presentation/widgets/quote_category_chip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(quotesProvider);
    final currentIndex = ref.watch(currentQuoteIndexProvider);
    final connectivityAsync = ref.watch(connectivityProvider);

    final isOffline = connectivityAsync.maybeWhen(
      data: (results) => results.every((r) => r == ConnectivityResult.none),
      orElse: () => false,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (isOffline)
              Container(
                color: AppColors.surface.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "You're offline. Some features may be limited.",
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: quotesAsync.when(
                data: (quotes) {
                  if (quotes.isEmpty) {
                    return const Center(child: Text("No quotes found"));
                  }
                  final quote = quotes[currentIndex % quotes.length];

                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        QuoteCategoryChip(label: quote.category),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                          child: Center(
                            child: Column(
                              key: ValueKey<String>(quote.id),
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '"${normalizeQuoteString(quote.text)}"',
                                    style: AppTypography.h2.copyWith(
                                      color: Colors.white,
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Text(
                                    "- ${normalizeQuoteString(quote.author)}",
                                    style: AppTypography.body1.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        QuoteActionBar(
                          isFavorite: quote.isFavorite,
                          onFavorite: () => ref
                              .read(quotesProvider.notifier)
                              .toggleFavorite(quote),
                          onShare: () {
                            Share.share(
                              '"${normalizeQuoteString(quote.text)}" - ${normalizeQuoteString(quote.author)}',
                            );
                          },
                          onShuffle: () {
                            ref
                                .read(currentQuoteIndexProvider.notifier)
                                .increment();
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
