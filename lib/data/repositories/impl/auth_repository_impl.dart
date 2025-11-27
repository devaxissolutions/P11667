import 'package:dev_quotes/core/error/failures.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/data/datasources/auth_remote_data_source.dart';
import 'package:dev_quotes/data/datasources/firestore_data_source.dart';
import 'package:dev_quotes/data/datasources/local_data_source.dart';
import 'package:dev_quotes/data/dto/user_dto.dart';
import 'package:dev_quotes/data/mappers/user_mapper.dart';
import 'package:dev_quotes/data/models/user_model.dart';
import 'package:dev_quotes/data/repositories/interfaces/auth_repository.dart';
import 'package:dev_quotes/features/auth/utils/auth_exception_handler.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authDataSource;
  final FirestoreDataSource _firestoreDataSource;
  final LocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource authDataSource,
    required FirestoreDataSource firestoreDataSource,
    required LocalDataSource localDataSource,
  }) : _authDataSource = authDataSource,
       _firestoreDataSource = firestoreDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Result<User>> login(String email, String password) async {
    try {
      final credential = await _authDataSource.login(email, password);
      final userDto = await _firestoreDataSource.getUser(credential.user!.uid);
      if (userDto != null) {
        await _localDataSource.cacheUser(userDto);
        return Success(UserMapper.toDomain(userDto));
      } else {
        return const Error(ServerFailure('User data not found'));
      }
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
  Future<Result<User>> signup(
    String email,
    String password,
    String username,
  ) async {
    try {
      final credential = await _authDataSource.signup(email, password);
      final newUser = UserDto(
        id: credential.user!.uid,
        email: email,
        username: username,
      );
      await _firestoreDataSource.saveUser(newUser);
      await _localDataSource.cacheUser(newUser);
      return Success(UserMapper.toDomain(newUser));
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
  Future<Result<void>> logout() async {
    try {
      await _authDataSource.logout();
      // Clear local cache if needed, or keep it.
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
        // Try to get from local first for speed
        final localUser = await _localDataSource.getLastUser();
        if (localUser != null && localUser.id == currentUser.uid) {
          // Background refresh
          _firestoreDataSource.getUser(currentUser.uid).then((remoteUser) {
            if (remoteUser != null) _localDataSource.cacheUser(remoteUser);
          });
          return Success(UserMapper.toDomain(localUser));
        }

        final userDto = await _firestoreDataSource.getUser(currentUser.uid);
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
      var userDto = await _firestoreDataSource.getUser(credential.user!.uid);

      if (userDto == null) {
        // New Google User
        userDto = UserDto(
          id: credential.user!.uid,
          email: credential.user!.email ?? '',
          username: credential.user!.displayName ?? 'User',
          photoUrl: credential.user!.photoURL,
        );
        await _firestoreDataSource.saveUser(userDto);
      }

      await _localDataSource.cacheUser(userDto);
      return Success(UserMapper.toDomain(userDto));
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
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _authDataSource.resetPassword(email);
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
  Stream<User?> get authStateChanges {
    return _authDataSource.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final userDto = await _firestoreDataSource.getUser(firebaseUser.uid);
        if (userDto != null) {
          await _localDataSource.cacheUser(userDto);
          return UserMapper.toDomain(userDto);
        } else {
          // If not in Firestore, try local cache
          final cached = await _localDataSource.getLastUser();
          if (cached != null && cached.id == firebaseUser.uid) {
            return UserMapper.toDomain(cached);
          }
          return null;
        }
      } catch (e) {
        // Offline or error, use cache
        final cached = await _localDataSource.getLastUser();
        if (cached != null && cached.id == firebaseUser.uid) {
          return UserMapper.toDomain(cached);
        }
        return null;
      }
    });
  }
}
