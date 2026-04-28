import 'dart:io';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<Result<User>> getUserProfile(String userId);
  Future<Result<void>> updateProfile(User user);
  Future<Result<String>> uploadAvatar(String userId, File imageFile);
  Future<Result<void>> updateFCMToken(String userId, String token);
  Future<Result<void>> updateNotificationPreference(String userId, bool enabled);
  Future<Result<bool>> getNotificationPreference(String userId);
}
