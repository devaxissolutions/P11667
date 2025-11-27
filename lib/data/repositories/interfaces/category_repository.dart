import 'package:dev_quotes/core/error/failures.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/data/models/category_model.dart';

abstract class CategoryRepository {
  Future<Result<List<Category>>> getCategories();
}
