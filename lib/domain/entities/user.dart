import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String username;
  final String? photoUrl;
  final String? bio;
  final int favoritesCount;
  final int quotesCount;

  const User({
    required this.id,
    required this.email,
    required this.username,
    this.photoUrl,
    this.bio,
    this.favoritesCount = 0,
    this.quotesCount = 0,
  });

  @override
  List<Object?> get props => [id, email, username, photoUrl, bio, favoritesCount, quotesCount];
}
