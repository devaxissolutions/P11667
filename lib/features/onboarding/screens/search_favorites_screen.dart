import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/onboarding_layout.dart';

class SearchFavoritesScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int currentPage;
  final int totalPages;

  const SearchFavoritesScreen({
    super.key,
    required this.onNext,
    required this.onSkip,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      icon: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
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
                Icons.search,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Container(
            width: 80,
            height: 80,
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
                Icons.favorite,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
      title: 'Search & Favorites',
      subtitle: 'Find specific quotes and save your favorites for quick access.',
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
