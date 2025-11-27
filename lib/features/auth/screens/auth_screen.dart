import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../widgets/auth_tab_selector.dart';
import 'login_form.dart';
import 'signup_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // DevQuote logo/title
              Text(
                'DevQuote',
                style: AppTypography.title1,
              ),

              const SizedBox(height: 48),

              // Tab selector
              AuthTabSelector(
                selectedIndex: _selectedTab,
                onTabSelected: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
              ),

              // Forms
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedTab == 0
                    ? const LoginForm(
                        key: ValueKey('login'),
                      )
                    : SignupForm(
                        key: const ValueKey('signup'),
                        onSwitchToLogin: () {
                          setState(() {
                            _selectedTab = 0;
                          });
                        },
                      ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
