import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dev_quotes/features/auth/utils/auth_exception_handler.dart';

// Reset password state
class ResetPasswordState {
  final String newPassword;
  final String confirmPassword;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const ResetPasswordState({
    this.newPassword = '',
    this.confirmPassword = '',
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ResetPasswordState copyWith({
    String? newPassword,
    String? confirmPassword,
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return ResetPasswordState(
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// Reset password notifier
class ResetPasswordNotifier extends Notifier<ResetPasswordState> {
  @override
  ResetPasswordState build() => const ResetPasswordState();

  void setNewPassword(String password) {
    state = state.copyWith(newPassword: password, error: null);
  }

  void setConfirmPassword(String password) {
    state = state.copyWith(confirmPassword: password, error: null);
  }

  Future<void> resetPassword(String oobCode) async {
    if (state.newPassword.length < 6) {
      state = state.copyWith(error: 'Password must be at least 6 characters');
      return;
    }

    if (state.newPassword != state.confirmPassword) {
      state = state.copyWith(error: 'Passwords do not match');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: oobCode,
        newPassword: state.newPassword,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on FirebaseAuthException catch (e) {
      String errorMessage = AuthExceptionHandler.handleFirebaseAuthException(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  void reset() {
    state = const ResetPasswordState();
  }
}

final resetPasswordProvider =
    NotifierProvider<ResetPasswordNotifier, ResetPasswordState>(() {
      return ResetPasswordNotifier();
    });
