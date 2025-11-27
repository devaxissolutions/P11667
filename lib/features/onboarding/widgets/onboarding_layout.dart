import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class OnboardingLayout extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final Widget button;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onSkip;

  const OnboardingLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.currentPage,
    required this.totalPages,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Skip button (only show if not last page)
              if (onSkip != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Skip',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 48),

              const Spacer(flex: 2),

              // Icon
              icon,

              const SizedBox(height: 48),

              // Title
              Text(
                title,
                style: AppTypography.title1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                subtitle,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  totalPages,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? AppColors.primary
                          : AppColors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Button
              button,

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
