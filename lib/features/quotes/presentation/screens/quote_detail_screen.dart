import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/string_utils.dart';
import '../providers/quote_provider.dart';
import '../widgets/quote_action_bar.dart';
import '../widgets/quote_category_chip.dart';

class QuoteDetailScreen extends ConsumerWidget {
  final String quoteId;

  const QuoteDetailScreen({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(quoteByIdProvider(quoteId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: quoteAsync.when(
          data: (quote) {
            if (quote == null) {
              return const Center(
                child: Text(
                  'Quote not found',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuoteCategoryChip(label: quote.category),
                  const Spacer(),
                  Center(
                    child: Column(
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
                  const Spacer(),
                  QuoteActionBar(
                    isFavorite: quote.isFavorite,
                    onFavorite: () =>
                        ref.read(quotesProvider.notifier).toggleFavorite(quote),
                    onShare: () {
                      Share.share(
                        '"${normalizeQuoteString(quote.text)}" - ${normalizeQuoteString(quote.author)}',
                      );
                    },
                    onShuffle: null, // No shuffle in detail view
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'Error loading quote: $err',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
