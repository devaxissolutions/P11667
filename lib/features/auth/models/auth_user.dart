class AuthUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          photoUrl == other.photoUrl;

  @override
  int get hashCode =>
      id.hashCode ^ email.hashCode ^ name.hashCode ^ photoUrl.hashCode;
}
