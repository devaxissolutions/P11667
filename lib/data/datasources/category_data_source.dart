import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dev_quotes/data/dto/category_dto.dart';

abstract class CategoryDataSource {
  Future<List<CategoryDto>> getCategories();
}

class CategoryDataSourceImpl implements CategoryDataSource {
  final FirebaseFirestore _firestore;

  CategoryDataSourceImpl(this._firestore);

  @override
  Future<List<CategoryDto>> getCategories() async {
    final query = await _firestore.collection('categories').get();
    return query.docs.map((doc) => CategoryDto.fromFirestore(doc)).toList();
  }
}
