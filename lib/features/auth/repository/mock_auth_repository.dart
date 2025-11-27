import '../models/auth_user.dart';
import '../utils/validators.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  AuthUser? _currentUser;

  @override
  Future<AuthUser> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Validate inputs
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      throw Exception(emailError);
    }

    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) {
      throw Exception(passwordError);
    }

    // Mock successful login
    _currentUser = AuthUser(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: 'Mock User',
      photoUrl: null,
    );

    return _currentUser!;
  }

  @override
  Future<AuthUser> signup(String name, String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Validate inputs
    final nameError = Validators.validateName(name);
    if (nameError != null) {
      throw Exception(nameError);
    }

    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      throw Exception(emailError);
    }

    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) {
      throw Exception(passwordError);
    }

    // Mock successful signup
    _currentUser = AuthUser(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name,
      photoUrl: null,
    );

    return _currentUser!;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock successful Google sign-in
    _currentUser = AuthUser(
      id: 'google-user-${DateTime.now().millisecondsSinceEpoch}',
      email: 'user@gmail.com',
      name: 'Google User',
      photoUrl: 'https://via.placeholder.com/150',
    );

    return _currentUser!;
  }

  @override
  Future<void> sendPasswordResetLink(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Validate email
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      throw Exception(emailError);
    }

    // Mock successful email sent
    // In real implementation, this would send an actual email
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Validate password
    final passwordError = Validators.validatePassword(newPassword);
    if (passwordError != null) {
      throw Exception(passwordError);
    }

    // Mock successful password reset
    // In real implementation, this would update the password in the backend
  }

  @override
  Future<void> logout() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = null;
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return _currentUser;
  }
}
