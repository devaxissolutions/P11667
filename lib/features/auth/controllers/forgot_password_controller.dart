import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_quotes/di/service_locator.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';

// Forgot password state
class ForgotPasswordState {
  final String email;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const ForgotPasswordState({
    this.email = '',
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ForgotPasswordState copyWith({
    String? email,
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// Forgot password notifier
class ForgotPasswordNotifier extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  void setEmail(String email) {
    state = state.copyWith(email: email, error: null);
  }

  Future<void> sendResetLink() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.resetPassword(state.email);

      if (result is Success) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else if (result is Error) {
        state = state.copyWith(isLoading: false, error: result.failure.message);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  void reset() {
    state = const ForgotPasswordState();
  }
}

final forgotPasswordProvider =
    NotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(() {
      return ForgotPasswordNotifier();
    });
