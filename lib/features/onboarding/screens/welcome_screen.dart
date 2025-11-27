import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/onboarding_layout.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  final int currentPage;
  final int totalPages;

  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
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
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
      title: 'Welcome to DevQuote',
      subtitle: 'Discover inspiring developer quotes daily',
      button: PrimaryButton(
        text: 'Get Started',
        onPressed: onGetStarted,
      ),
      currentPage: currentPage,
      totalPages: totalPages,
    );
  }
}
