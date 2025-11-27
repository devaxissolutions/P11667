import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../quotes/presentation/providers/quote_provider.dart';
import '../../../quotes/presentation/widgets/quote_card.dart';
import '../../../quotes/presentation/widgets/edit_quote_dialog.dart';

class MyQuotesScreen extends ConsumerWidget {
  const MyQuotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myQuotesAsync = ref.watch(myQuotesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Quotes',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: myQuotesAsync.when(
          data: (quotes) {
            if (quotes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You haven\'t added any quotes yet',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share your wisdom with the community',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quotes.length,
              itemBuilder: (context, index) {
                final quote = quotes[index];
                return QuoteCard(
                  quote: quote,
                  onTap: () {
                    // Show quote detail modal centered
                    _showQuoteDetail(context, quote);
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: AppColors.textSecondary),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => EditQuoteDialog(quote: quote),
                      );
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error loading your quotes: $err')),
        ),
      ),
    );
  }

  void _showQuoteDetail(BuildContext context, dynamic quote) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F0F13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '"${normalizeQuoteString(quote.text)}"',
                style: AppTypography.h2.copyWith(
                  color: Colors.white,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "- ${normalizeQuoteString(quote.author)}",
                style: AppTypography.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
