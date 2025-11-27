import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryDto {
  final String id;
  final String name;

  const CategoryDto({
    required this.id,
    required this.name,
  });

  factory CategoryDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryDto(
      id: doc.id,
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
    };
  }
}
