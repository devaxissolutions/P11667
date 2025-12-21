import 'package:dev_quotes/core/error/failures.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/data/models/user_model.dart';

abstract class AuthRepository {
  Future<Result<User>> login(String email, String password);
  Future<Result<User>> signup(String email, String password, String username);
  Future<Result<void>> logout();
  Future<Result<User>> getCurrentUser();
  Future<Result<User>> signInWithGoogle();
  Future<Result<void>> resetPassword(String email);
  Future<Result<void>> confirmPasswordReset(String code, String newPassword);
  Stream<User?> get authStateChanges;
}
