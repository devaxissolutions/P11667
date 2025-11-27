import 'dart:io';
import 'package:dev_quotes/core/error/failures.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/data/datasources/firestore_data_source.dart';
import 'package:dev_quotes/data/datasources/local_data_source.dart';
import 'package:dev_quotes/data/mappers/user_mapper.dart';
import 'package:dev_quotes/data/models/user_model.dart';
import 'package:dev_quotes/data/repositories/interfaces/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirestoreDataSource _firestoreDataSource;
  final LocalDataSource _localDataSource;

  ProfileRepositoryImpl({
    required FirestoreDataSource firestoreDataSource,
    required LocalDataSource localDataSource,
  }) : _firestoreDataSource = firestoreDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Result<User>> getUserProfile(String userId) async {
    try {
      final userDto = await _firestoreDataSource.getUser(userId);
      if (userDto != null) {
        await _localDataSource.cacheUser(userDto);
        return Success(UserMapper.toDomain(userDto));
      }
      return const Error(ServerFailure('User not found'));
    } catch (e) {
      // Fallback
      try {
        final cachedUser = await _localDataSource.getLastUser();
        if (cachedUser != null && cachedUser.id == userId) {
          return Success(UserMapper.toDomain(cachedUser));
        }
        return Error(ServerFailure(e.toString()));
      } catch (_) {
        return Error(ServerFailure(e.toString()));
      }
    }
  }

  @override
  Future<Result<void>> updateProfile(User user) async {
    try {
      final userDto = UserMapper.fromDomain(user);
      await _firestoreDataSource.updateUser(userDto);
      await _localDataSource.cacheUser(userDto);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> uploadAvatar(String userId, File imageFile) async {
    // Profile pictures use initials instead of uploaded images
    // This method is kept for interface compatibility but returns an error
    return const Error(
      ServerFailure('Avatar upload not supported - using initials instead'),
    );
  }
}
