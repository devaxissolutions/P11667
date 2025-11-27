import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../widgets/auth_tab_selector.dart';
import 'login_form.dart';
import 'signup_form.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late PageController _pageController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTab);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    // Clear errors when switching tabs
    if (index == 0) {
      // Switching to login, clear signup errors
      ref.read(signupControllerProvider.notifier).clearError();
    } else {
      // Switching to signup, clear login errors
      ref.read(loginControllerProvider.notifier).clearError();
    }

    setState(() {
      _selectedTab = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    // Clear errors when swiping between tabs
    if (index == 0) {
      ref.read(signupControllerProvider.notifier).clearError();
    } else {
      ref.read(loginControllerProvider.notifier).clearError();
    }

    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  // DevQuote logo/title
                  Text('DevQuote', style: AppTypography.title1),
                  const SizedBox(height: 48),
                  // Tab selector
                  AuthTabSelector(
                    selectedIndex: _selectedTab,
                    onTabSelected: _onTabSelected,
                  ),
                ],
              ),
            ),

            // Forms
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const LoginForm(key: ValueKey('login')),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SignupForm(
                      key: const ValueKey('signup'),
                      onSwitchToLogin: () {
                        _onTabSelected(0);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
