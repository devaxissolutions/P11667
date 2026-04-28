import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/data/datasources/category_data_source.dart';
import 'package:dev_quotes/data/mappers/category_mapper.dart';
import 'package:dev_quotes/domain/entities/category.dart';
import 'package:dev_quotes/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryDataSource _categoryDataSource;

  CategoryRepositoryImpl({required CategoryDataSource categoryDataSource})
      : _categoryDataSource = categoryDataSource;

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      final dtos = await _categoryDataSource.getCategories();
      if (dtos.isEmpty) {
        return const Success([
          Category(id: '1', name: 'Wisdom'),
          Category(id: '2', name: 'Success'),
          Category(id: '3', name: 'Life'),
          Category(id: '4', name: 'Mindset'),
          Category(id: '5', name: 'Happiness'),
          Category(id: '6', name: 'Growth'),
          Category(id: '7', name: 'Inspiration'),
          Category(id: '8', name: 'Productivity'),
        ]);
      }
      return Success(dtos.map((dto) => CategoryMapper.toDomain(dto)).toList());
    } catch (e) {
      return const Success([
        Category(id: '1', name: 'Wisdom'),
        Category(id: '2', name: 'Success'),
        Category(id: '3', name: 'Life'),
        Category(id: '4', name: 'Mindset'),
        Category(id: '5', name: 'Happiness'),
        Category(id: '6', name: 'Growth'),
        Category(id: '7', name: 'Inspiration'),
        Category(id: '8', name: 'Productivity'),
      ]);
    }
  }
}
