import 'package:cloud_firestore/cloud_firestore.dart';

class QuoteDto {
  final String id;
  final String text;
  final String author;
  final String category;
  final String userId;
  final DateTime timestamp;

  const QuoteDto({
    required this.id,
    required this.text,
    required this.author,
    required this.category,
    required this.userId,
    required this.timestamp,
  });

  factory QuoteDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return QuoteDto(
      id: doc.id,
      text: data['quoteText'] ?? '',
      author: data['author'] ?? '',
      category: data['category'] ?? '',
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'quoteText': text,
      'author': author,
      'category': category,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory QuoteDto.fromJson(Map<String, dynamic> json) {
    return QuoteDto(
      id: json['id'],
      text: json['quoteText'],
      author: json['author'],
      category: json['category'],
      userId: json['userId'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quoteText': text,
      'author': author,
      'category': category,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
