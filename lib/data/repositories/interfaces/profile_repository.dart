import 'dart:io';
import 'package:dev_quotes/core/error/failures.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/data/models/user_model.dart';

abstract class ProfileRepository {
  Future<Result<User>> getUserProfile(String userId);
  Future<Result<void>> updateProfile(User user);
  Future<Result<String>> uploadAvatar(String userId, File imageFile);
}
