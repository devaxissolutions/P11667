import 'package:dev_quotes/di/service_locator.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_quotes/core/performance/perf_service.dart';
import '../models/auth_state.dart';

// Auth state notifier - handles authentication status only
class AuthNotifier extends StreamNotifier<AuthState> {
  @override
  Stream<AuthState> build() {
    final repository = ref.watch(authRepositoryProvider);
    return repository.authStateChanges.map((user) {
      if (user != null) {
        return AuthAuthenticated(user);
      } else {
        return const AuthUnauthenticated();
      }
    });
  }

  Future<void> logout() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.logout();
      // The stream will update to unauthenticated
    } catch (e) {
      // Handle logout error if needed
    }
  }

  Future<Result<void>> deleteAccount() async {
    final repository = ref.read(authRepositoryProvider);
    return await repository.deleteAccount();
  }

  void updateUser(dynamic user) {
    if (state.value is AuthAuthenticated) {
      state = AsyncValue.data(AuthAuthenticated(user));
    }
  }
}

// Login controller - handles login operations and errors
class LoginController extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await PerfService.trace(
        "login_trace",
        () async => await repository.login(email, password),
      );

      if (result is Success) {
        // Mark onboarding as completed when user logs in
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool('onboarding_completed', true);
        state = const AsyncValue.data(null); // Success, no error
      } else if (result is Error) {
        state = AsyncValue.data((result as Error).failure.message);
      }
    } catch (e) {
      state = const AsyncValue.data('Something went wrong. Please try again.');
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.signInWithGoogle();

      if (result is Success) {
        // Mark onboarding as completed when user signs in with Google
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool('onboarding_completed', true);
        state = const AsyncValue.data(null); // Success, no error
      } else if (result is Error) {
        state = AsyncValue.data((result as Error).failure.message);
      }
    } catch (e) {
      state = const AsyncValue.data('Something went wrong. Please try again.');
    }
  }

  void clearError() {
    state = const AsyncValue.data(null);
  }
}

// Signup controller - handles signup operations and errors
class SignupController extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> signup(String name, String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.signup(email, password, name);

      if (result is Success) {
        // Mark onboarding as completed when user signs up
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool('onboarding_completed', true);
        state = const AsyncValue.data(null); // Success, no error
      } else if (result is Error) {
        state = AsyncValue.data((result as Error).failure.message);
      }
    } catch (e) {
      state = const AsyncValue.data('Something went wrong. Please try again.');
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.signInWithGoogle();

      if (result is Success) {
        // Mark onboarding as completed when user signs in with Google
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool('onboarding_completed', true);
        state = const AsyncValue.data(null); // Success, no error
      } else if (result is Error) {
        state = AsyncValue.data((result as Error).failure.message);
      }
    } catch (e) {
      state = const AsyncValue.data('Something went wrong. Please try again.');
    }
  }

  void clearError() {
    state = const AsyncValue.data(null);
  }
}

final authProvider = StreamNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

final loginControllerProvider =
    NotifierProvider<LoginController, AsyncValue<String?>>(
      () => LoginController(),
    );

final signupControllerProvider =
    NotifierProvider<SignupController, AsyncValue<String?>>(
      () => SignupController(),
    );
