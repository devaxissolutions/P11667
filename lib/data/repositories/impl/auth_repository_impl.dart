import 'package:dev_quotes/core/error/failures.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/core/utils/logger.dart';
import 'package:dev_quotes/data/datasources/auth_remote_data_source.dart';
import 'package:dev_quotes/data/datasources/user_data_source.dart';
import 'package:dev_quotes/data/datasources/local_data_source.dart';
import 'package:dev_quotes/core/services/rate_limit_service.dart';
import 'package:dev_quotes/data/dto/user_dto.dart';
import 'package:dev_quotes/data/mappers/user_mapper.dart';
import 'package:dev_quotes/domain/entities/user.dart';
import 'package:dev_quotes/domain/repositories/auth_repository.dart';
import 'package:dev_quotes/features/auth/utils/auth_exception_handler.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authDataSource;
  final UserDataSource _userDataSource;
  final LocalDataSource _localDataSource;
  final RateLimitService _rateLimitService;

  AuthRepositoryImpl({
    required AuthRemoteDataSource authDataSource,
    required UserDataSource userDataSource,
    required LocalDataSource localDataSource,
    required RateLimitService rateLimitService,
  }) : _authDataSource = authDataSource,
       _userDataSource = userDataSource,
       _localDataSource = localDataSource,
       _rateLimitService = rateLimitService;

  @override
  Future<Result<User>> login(String email, String password) async {
    if (_rateLimitService.isLocked('login')) {
      return Error(RateLimitFailure(_rateLimitService.getLockMessage('login')));
    }

    try {
      final credential = await _authDataSource.login(email, password);
      if (credential.user == null) {
        return const Error(AuthFailure('Authentication failed'));
      }
      
      final userDto = await _userDataSource.getUser(credential.user!.uid);
      if (userDto != null) {
        await _localDataSource.cacheUser(userDto);
        _rateLimitService.clearAttempts('login');
        return Success(UserMapper.toDomain(userDto));
      } else {
        return const Error(ServerFailure('User data not found'));
      }
    } catch (e, stackTrace) {
      _rateLimitService.recordAttempt('login');
      Logger.e('Login failed', e, stackTrace);
      
      String message;
      if (e is firebase.FirebaseAuthException) {
        message = AuthExceptionHandler.handleFirebaseAuthException(e);
      } else {
        message = 'Authentication failed. Please try again.';
      }
      return Error(AuthFailure(message));
    }
  }

  @override
  Future<Result<User>> signup(
    String email,
    String password,
    String username,
  ) async {
    if (_rateLimitService.isLocked('signup')) {
      return Error(RateLimitFailure(_rateLimitService.getLockMessage('signup')));
    }

    try {
      final credential = await _authDataSource.signup(email, password);
      final newUser = UserDto(
        id: credential.user!.uid,
        email: email,
        username: username,
      );
      await _userDataSource.saveUser(newUser);
      await _localDataSource.cacheUser(newUser);
      _rateLimitService.clearAttempts('signup');
      return Success(UserMapper.toDomain(newUser));
    } catch (e, stackTrace) {
      _rateLimitService.recordAttempt('signup');
      Logger.e('Signup failed', e, stackTrace);
      
      String message;
      if (e is firebase.FirebaseAuthException) {
        message = AuthExceptionHandler.handleFirebaseAuthException(e);
      } else {
        message = 'Registration failed. Please try again.';
      }
      return Error(AuthFailure(message));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _authDataSource.logout();
      return const Success(null);
    } catch (e) {
      String message;
      if (e is firebase.FirebaseAuthException) {
        message = AuthExceptionHandler.handleFirebaseAuthException(e);
      } else {
        message = 'Something went wrong. Please try again.';
      }
      return Error(AuthFailure(message));
    }
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final currentUser = _authDataSource.currentUser;
      if (currentUser != null) {
        final localUser = await _localDataSource.getLastUser();
        if (localUser != null && localUser.id == currentUser.uid) {
          _userDataSource.getUser(currentUser.uid).then((remoteUser) {
            if (remoteUser != null) _localDataSource.cacheUser(remoteUser);
          });
          return Success(UserMapper.toDomain(localUser));
        }

        final userDto = await _userDataSource.getUser(currentUser.uid);
        if (userDto != null) {
          await _localDataSource.cacheUser(userDto);
          return Success(UserMapper.toDomain(userDto));
        }
      }
      return const Error(AuthFailure('No user logged in'));
    } catch (e) {
      String message;
      if (e is firebase.FirebaseAuthException) {
        message = AuthExceptionHandler.handleFirebaseAuthException(e);
      } else {
        message = 'Something went wrong. Please try again.';
      }
      return Error(AuthFailure(message));
    }
  }

  @override
  Future<Result<User>> signInWithGoogle() async {
    try {
      final credential = await _authDataSource.signInWithGoogle();
      if (credential.user == null) {
        return const Error(AuthFailure('Google authentication failed'));
      }
      
      var userDto = await _userDataSource.getUser(credential.user!.uid);

      if (userDto == null) {
        userDto = UserDto(
          id: credential.user!.uid,
          email: credential.user!.email ?? '',
          username: credential.user!.displayName ?? 'User',
          photoUrl: credential.user!.photoURL,
        );
        await _userDataSource.saveUser(userDto);
      }

      await _localDataSource.cacheUser(userDto);
      return Success(UserMapper.toDomain(userDto));
    } catch (e, stackTrace) {
      Logger.e('Google sign-in failed', e, stackTrace);
      
      String message;
      if (e is firebase.FirebaseAuthException) {
        message = AuthExceptionHandler.handleFirebaseAuthException(e);
      } else {
        message = 'Google sign-in failed. Please try again.';
      }
      return Error(AuthFailure(message));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    if (_rateLimitService.isLocked('reset_password')) {
      return Error(
        RateLimitFailure(_rateLimitService.getLockMessage('reset_password')),
      );
    }

    try {
      await _authDataSource.resetPassword(email);
      _rateLimitService.clearAttempts('reset_password');
      return const Success(null);
    } catch (e) {
      _rateLimitService.recordAttempt('reset_password');
      String message;
      if (e is firebase.FirebaseAuthException) {
        message = AuthExceptionHandler.handleFirebaseAuthException(e);
      } else {
        message = 'Something went wrong. Please try again.';
      }
      return Error(AuthFailure(message));
    }
  }

  @override
  Future<Result<void>> confirmPasswordReset(
    String code,
    String newPassword,
  ) async {
    if (_rateLimitService.isLocked('confirm_password_reset')) {
      return Error(
        RateLimitFailure(
          _rateLimitService.getLockMessage('confirm_password_reset'),
        ),
      );
    }

    try {
      await _authDataSource.confirmPasswordReset(code, newPassword);
      _rateLimitService.clearAttempts('confirm_password_reset');
      return const Success(null);
    } catch (e) {
      _rateLimitService.recordAttempt('confirm_password_reset');
      String message;
      if (e is firebase.FirebaseAuthException) {
        message = AuthExceptionHandler.handleFirebaseAuthException(e);
      } else {
        message = 'Something went wrong. Please try again.';
      }
      return Error(AuthFailure(message));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _authDataSource.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final userDto = await _userDataSource.getUser(firebaseUser.uid);
        if (userDto != null) {
          await _localDataSource.cacheUser(userDto);
          return UserMapper.toDomain(userDto);
        } else {
          final cached = await _localDataSource.getLastUser();
          if (cached != null && cached.id == firebaseUser.uid) {
            return UserMapper.toDomain(cached);
          }
          return null;
        }
      } catch (e) {
        final cached = await _localDataSource.getLastUser();
        if (cached != null && cached.id == firebaseUser.uid) {
          return UserMapper.toDomain(cached);
        }
        return null;
      }
    });
  }

  @override
  Future<Result<void>> deleteAccount() async {
    final currentUser = _authDataSource.currentUser;
    if (currentUser == null) {
      return const Error(AuthFailure('No user logged in'));
    }

    try {
      final uid = currentUser.uid;

      // 1. Delete user data from Firestore
      await _userDataSource.deleteUser(uid);

      // 2. Delete Firebase Auth user
      // Note: This may fail if the user has not signed in recently.
      // In a real app, you would handle re-authentication here.
      await _authDataSource.deleteAccount();

      // 3. Clear local cache
      await _localDataSource.clearCache();

      return const Success(null);
    } catch (e) {
      Logger.e('Account deletion failed', e);
      return Error(AuthFailure(e.toString()));
    }
  }
}
