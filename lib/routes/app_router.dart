import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_quotes/features/auth/controllers/auth_controller.dart';
import 'package:dev_quotes/features/auth/models/auth_state.dart';
import 'package:dev_quotes/core/providers.dart';

import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_link_sent_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/reset_success_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/widgets/scaffold_with_nav_bar.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/profile/profile_screen.dart';
import '../features/settings/presentation/screens/add_quote/add_quote_screen.dart';
import '../features/settings/presentation/screens/about/about_screen.dart';
import '../features/quotes/presentation/screens/quote_detail_screen.dart';
import '../features/my_quotes/presentation/screens/my_quotes_screen.dart';
import '../features/settings/presentation/screens/policy/privacy_policy_screen.dart';
import '../features/settings/presentation/screens/terms/terms_of_service_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: ref.watch(navigatorKeyProvider),
    initialLocation: '/loading',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authProvider);
      final authState = authAsync.value;
      final isLoggedIn = authState is AuthAuthenticated;
      final isLoggingIn = state.matchedLocation.startsWith('/auth');
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isLoading = state.matchedLocation == '/loading';

      // Read directly from prefs to get the latest value
      final prefs = ref.read(sharedPreferencesProvider);
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;

      // If loading or initial, stay
      if (authState is AuthInitial ||
          authState is AuthLoading ||
          authAsync.isLoading) {
        return null;
      }

      if (isLoading) {
        if (isLoggedIn) return '/home';
        return onboardingCompleted ? '/auth' : '/onboarding';
      }

      // If logged in, prevent access to auth and onboarding pages
      if (isLoggedIn) {
        if (isLoggingIn || isOnboarding) return '/home';
        return null;
      }

      // If not logged in
      if (!onboardingCompleted) {
        if (!isOnboarding) return '/onboarding';
      } else {
        // Onboarding completed, but not logged in
        if (!isLoggingIn) return '/auth';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/reset-link-sent',
        builder: (context, state) => const ResetLinkSentScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (context, state) {
          final oobCode = state.uri.queryParameters['oobCode'];
          return ResetPasswordScreen(oobCode: oobCode);
        },
      ),
      GoRoute(
        path: '/auth/reset-success',
        builder: (context, state) => const ResetSuccessScreen(),
      ),
      GoRoute(
        path: '/my-quotes',
        builder: (context, state) => const MyQuotesScreen(),
      ),
      GoRoute(
        path: '/quote/:id',
        builder: (context, state) {
          final quoteId = state.pathParameters['id']!;
          return QuoteDetailScreen(quoteId: quoteId);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const ProfileScreen(),
                  ),
                  GoRoute(
                    path: 'add-quote',
                    builder: (context, state) => const AddQuoteScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const AboutScreen(),
                  ),
                  GoRoute(
                    path: 'privacy-policy',
                    builder: (context, state) => const PrivacyPolicyScreen(),
                  ),
                  GoRoute(
                    path: 'terms-of-service',
                    builder: (context, state) => const TermsOfServiceScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AuthState>>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }
}
