import '../../domain/entities/user_profile.dart';

class UserProfileModel {
  const UserProfileModel(this.profile);

  final UserProfile profile;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      UserProfile(
        id: json['auth_uid'] as String? ?? json['id'] as String,
        email: json['email'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        photoUrl: json['photo_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auth_uid': profile.id,
      'email': profile.email,
      'display_name': profile.displayName,
      'photo_url': profile.photoUrl,
      'created_at': profile.createdAt?.toIso8601String(),
    };
  }
}

