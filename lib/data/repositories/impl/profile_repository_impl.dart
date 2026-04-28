import 'dart:io';
import 'package:dev_quotes/core/error/failures.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/data/datasources/user_data_source.dart';
import 'package:dev_quotes/data/datasources/local_data_source.dart';
import 'package:dev_quotes/data/mappers/user_mapper.dart';
import 'package:dev_quotes/domain/entities/user.dart';
import 'package:dev_quotes/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final UserDataSource _userDataSource;
  final LocalDataSource _localDataSource;

  ProfileRepositoryImpl({
    required UserDataSource userDataSource,
    required LocalDataSource localDataSource,
  }) : _userDataSource = userDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Result<User>> getUserProfile(String userId) async {
    try {
      final userDto = await _userDataSource.getUser(userId);
      if (userDto != null) {
        await _localDataSource.cacheUser(userDto);
        return Success(UserMapper.toDomain(userDto));
      }
      return const Error(ServerFailure('User not found'));
    } catch (e) {
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
      await _userDataSource.updateUser(userDto);
      await _localDataSource.cacheUser(userDto);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> uploadAvatar(String userId, File imageFile) async {
    return const Error(
      ServerFailure('Avatar upload not supported - using initials instead'),
    );
  }

  @override
  Future<Result<void>> updateFCMToken(String userId, String token) async {
    try {
      await _userDataSource.updateUserFCMToken(userId, token);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateNotificationPreference(
      String userId, bool enabled) async {
    try {
      await _userDataSource.setUserPreference(
          userId, 'notificationsEnabled', enabled);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> getNotificationPreference(String userId) async {
    try {
      final enabled = await _userDataSource.getUserPreference(
          userId, 'notificationsEnabled', true);
      return Success(enabled);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}
