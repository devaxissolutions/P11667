import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'controllers/onboarding_controller.dart';
import 'screens/welcome_screen.dart';
import 'screens/daily_quotes_screen.dart';
import 'screens/search_favorites_screen.dart';
import 'screens/topic_selection_screen.dart';
import 'screens/notification_permission_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;
  static const int totalPages = 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    ref.read(currentPageProvider.notifier).setPage(page);
  }

  void _nextPage() {
    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage < totalPages - 1) {
      _pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() async {
    final controller = ref.read(onboardingControllerProvider);
    await controller.completeOnboarding();
    if (mounted) {
      context.go('/auth');
    }
  }

  void _completeOnboarding() async {
    final controller = ref.read(onboardingControllerProvider);
    await controller.completeOnboarding();
    if (mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: [
        WelcomeScreen(
          onGetStarted: _nextPage,
          currentPage: 0,
          totalPages: totalPages,
        ),
        DailyQuotesScreen(
          onNext: _nextPage,
          onSkip: _skipToEnd,
          currentPage: 1,
          totalPages: totalPages,
        ),
        SearchFavoritesScreen(
          onNext: _nextPage,
          onSkip: _skipToEnd,
          currentPage: 2,
          totalPages: totalPages,
        ),
        TopicSelectionScreen(
          onContinue: _nextPage,
          onSkip: _skipToEnd,
          currentPage: 3,
          totalPages: totalPages,
        ),
        NotificationPermissionScreen(
          onEnableNotifications: _completeOnboarding,
          onSkip: _completeOnboarding,
          currentPage: 4,
          totalPages: totalPages,
        ),
      ],
    );
  }
}

