import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dev_quotes/core/theme/colors.dart';
import 'package:dev_quotes/core/theme/typography.dart';
import 'package:dev_quotes/core/utils/string_utils.dart';
import 'package:dev_quotes/domain/entities/quote.dart';

enum QuoteCardStyle { list, hero }

class CoreQuoteCard extends StatelessWidget {
  final Quote quote;
  final QuoteCardStyle style;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showQuotes;

  const CoreQuoteCard({
    super.key,
    required this.quote,
    this.style = QuoteCardStyle.list,
    this.onTap,
    this.trailing,
    this.showQuotes = true,
  });

  @override
  Widget build(BuildContext context) {
    if (style == QuoteCardStyle.hero) {
      return _buildHeroStyle(context);
    }
    return _buildListStyle(context);
  }

  Widget _buildListStyle(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${normalizeQuoteString(quote.text)}"',
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    normalizeQuoteString(quote.author),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 16), trailing!],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStyle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (showQuotes)
            Positioned(
              top: 24,
              left: 24,
              child: Icon(
                Icons.format_quote_rounded,
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                size: 64,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        normalizeQuoteString(quote.text),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "— ${normalizeQuoteString(quote.author)}",
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    quote.category,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8B5CF6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(height: 24),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
