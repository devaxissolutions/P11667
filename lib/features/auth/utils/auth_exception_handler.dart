import 'package:firebase_auth/firebase_auth.dart';

class AuthExceptionHandler {
  static String handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'expired-action-code':
        return 'The password reset link has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'The password reset link is invalid. Please request a new one.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
