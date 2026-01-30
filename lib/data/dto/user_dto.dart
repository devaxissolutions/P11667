import 'package:cloud_firestore/cloud_firestore.dart';

class UserDto {
  final String id;
  final String email;
  final String username;
  final String? photoUrl;
  final String? bio;
  final int favoritesCount;
  final int quotesCount;

  const UserDto({
    required this.id,
    required this.email,
    required this.username,
    this.photoUrl,
    this.bio,
    this.favoritesCount = 0,
    this.quotesCount = 0,
  });

  factory UserDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserDto(
      id: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      photoUrl: data['photoURL'],
      bio: data['bio'],
      favoritesCount: data['favoritesCount'] ?? 0,
      quotesCount: data['quotesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    // MEDIUM SECURITY FIX: Validate fields before saving
    if (username.length > 50) {
      throw ArgumentError('Username must be 50 characters or less');
    }
    
    if (bio != null && bio!.length > 500) {
      throw ArgumentError('Bio must be 500 characters or less');
    }
    
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      final uri = Uri.tryParse(photoUrl!);
      if (uri == null || !uri.isAbsolute) {
        throw ArgumentError('Invalid photo URL');
      }
    }

    return {
      'email': email.trim(),
      'username': username.trim(),
      'photoURL': photoUrl?.trim(),
      'bio': bio?.trim(),
      'favoritesCount': favoritesCount,
      'quotesCount': quotesCount,
    };
  }

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      photoUrl: json['photoURL'],
      bio: json['bio'],
      favoritesCount: json['favoritesCount'] ?? 0,
      quotesCount: json['quotesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'photoURL': photoUrl,
      'bio': bio,
      'favoritesCount': favoritesCount,
      'quotesCount': quotesCount,
    };
  }

  UserDto copyWith({
    String? id,
    String? email,
    String? username,
    String? photoUrl,
    String? bio,
    int? favoritesCount,
    int? quotesCount,
  }) {
    return UserDto(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      quotesCount: quotesCount ?? this.quotesCount,
    );
  }
}
