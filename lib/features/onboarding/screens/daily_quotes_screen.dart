import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/onboarding_layout.dart';

class DailyQuotesScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int currentPage;
  final int totalPages;

  const DailyQuotesScreen({
    super.key,
    required this.onNext,
    required this.onSkip,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      icon: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.format_quote,
            color: Colors.white,
            size: 48,
          ),
        ),
      ),
      title: 'Daily Quotes',
      subtitle: 'Receive a fresh dose of wisdom every day.',
      button: PrimaryButton(
        text: 'Next',
        onPressed: onNext,
      ),
      currentPage: currentPage,
      totalPages: totalPages,
      onSkip: onSkip,
    );
  }
}
