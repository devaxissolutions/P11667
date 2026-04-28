import 'package:dev_quotes/data/dto/category_dto.dart';
import 'package:dev_quotes/domain/entities/category.dart';

class CategoryMapper {
  static Category toDomain(CategoryDto dto) {
    return Category(
      id: dto.id,
      name: dto.name,
    );
  }

  static CategoryDto fromDomain(Category model) {
    return CategoryDto(
      id: model.id,
      name: model.name,
    );
  }
}
