import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/domain/entities/category.dart';

abstract class CategoryRepository {
  Future<Result<List<Category>>> getCategories();
}
