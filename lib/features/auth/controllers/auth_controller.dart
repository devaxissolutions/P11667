import 'package:dev_quotes/core/providers.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';

// Auth state notifier
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

  Future<void> login(String email, String password) async {
    state = const AsyncValue.data(AuthLoading());

    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.login(email, password);

      if (result is Success) {
        // The stream will update the state
      } else if (result is Error) {
        state = AsyncValue.data(AuthError((result as Error).failure.message));
      }
    } catch (e) {
      state = const AsyncValue.data(
        AuthError('Something went wrong. Please try again.'),
      );
    }
  }

  Future<void> signup(String name, String email, String password) async {
    state = const AsyncValue.data(AuthLoading());

    try {
      final repository = ref.read(authRepositoryProvider);
      // Signup expects username, email, password
      final result = await repository.signup(email, password, name);

      if (result is Success) {
        // The stream will update the state
      } else if (result is Error) {
        state = AsyncValue.data(AuthError((result as Error).failure.message));
      }
    } catch (e) {
      state = const AsyncValue.data(
        AuthError('Something went wrong. Please try again.'),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.data(AuthLoading());

    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.signInWithGoogle();

      if (result is Success) {
        // The stream will update the state
      } else if (result is Error) {
        state = AsyncValue.data(AuthError((result as Error).failure.message));
      }
    } catch (e) {
      state = const AsyncValue.data(
        AuthError('Something went wrong. Please try again.'),
      );
    }
  }

  Future<void> logout() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.logout();
      // The stream will update to unauthenticated
    } catch (e) {
      state = const AsyncValue.data(
        AuthError('Something went wrong. Please try again.'),
      );
    }
  }

  void clearError() {
    if (state.value is AuthError) {
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  void updateUser(dynamic user) {
    if (state.value is AuthAuthenticated) {
      state = AsyncValue.data(AuthAuthenticated(user));
    }
  }
}

final authProvider = StreamNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
