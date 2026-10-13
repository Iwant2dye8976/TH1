class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime? createdAt;

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

