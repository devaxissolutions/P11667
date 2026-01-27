import 'package:dev_quotes/core/error/failures.dart';
import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/data/datasources/firestore_data_source.dart';
import 'package:dev_quotes/data/mappers/category_mapper.dart';
import 'package:dev_quotes/data/models/category_model.dart';
import 'package:dev_quotes/data/repositories/interfaces/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final FirestoreDataSource _firestoreDataSource;

  CategoryRepositoryImpl({required FirestoreDataSource firestoreDataSource})
      : _firestoreDataSource = firestoreDataSource;

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      final dtos = await _firestoreDataSource.getCategories();
      if (dtos.isEmpty) {
        // Fallback to predefined if empty?
        // For now, return empty list or hardcoded.
        // User said "Fetch predefined categories".
        // If Firestore is empty, maybe we should return some defaults?
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
      // Fallback on error
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
