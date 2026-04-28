import 'package:dev_quotes/domain/entities/user.dart';

enum AuthMethod { none, email, signup, google, logout }

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final AuthMethod action;

  const AuthLoading([this.action = AuthMethod.none]);
}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}
