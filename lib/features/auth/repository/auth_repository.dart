import '../models/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> login(String email, String password);
  Future<AuthUser> signup(String name, String email, String password);
  Future<AuthUser> signInWithGoogle();
  Future<void> sendPasswordResetLink(String email);
  Future<void> resetPassword(String token, String newPassword);
  Future<void> logout();
  Future<AuthUser?> getCurrentUser();
}
