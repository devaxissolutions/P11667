import 'package:dev_quotes/data/dto/user_dto.dart';
import 'package:dev_quotes/data/models/user_model.dart';

class UserMapper {
  static User toDomain(UserDto dto) {
    return User(
      id: dto.id,
      email: dto.email,
      username: dto.username,
      photoUrl: dto.photoUrl,
      bio: dto.bio,
      favoritesCount: dto.favoritesCount,
      quotesCount: dto.quotesCount,
    );
  }

  static UserDto fromDomain(User model) {
    return UserDto(
      id: model.id,
      email: model.email,
      username: model.username,
      photoUrl: model.photoUrl,
      bio: model.bio,
      favoritesCount: model.favoritesCount,
      quotesCount: model.quotesCount,
    );
  }
}
