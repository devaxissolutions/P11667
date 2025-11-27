import 'package:equatable/equatable.dart';

class Quote extends Equatable {
  final String id;
  final String text;
  final String author;
  final String category;
  final String userId;
  final DateTime timestamp;
  final bool isFavorite;

  const Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.category,
    required this.userId,
    required this.timestamp,
    this.isFavorite = false,
  });

  @override
  List<Object?> get props => [id, text, author, category, userId, timestamp, isFavorite];
}
