enum PermissionRole {
  owner('owner', 'Chủ sở hữu'),
  editor('editor', 'Người chỉnh sửa'),
  viewer('viewer', 'Người xem');

  const PermissionRole(this.value, this.label);
  final String value;
  final String label;

  static PermissionRole fromValue(String value) {
    return PermissionRole.values.firstWhere(
      (role) => role.value.toLowerCase() == value.toLowerCase(),
      orElse: () => PermissionRole.viewer,
    );
  }

  bool get canEdit =>
      this == PermissionRole.owner || this == PermissionRole.editor;
  bool get canDelete => this == PermissionRole.owner;
  bool get canShare => this == PermissionRole.owner;
}

class DocumentPermission {
  const DocumentPermission({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.userEmail,
    this.userName,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String documentId;
  final String userId;
  final String userEmail;
  final String? userName;
  final PermissionRole role;
  final DateTime createdAt;

  DocumentPermission copyWith({
    String? id,
    String? documentId,
    String? userId,
    String? userEmail,
    String? userName,
    PermissionRole? role,
    DateTime? createdAt,
  }) {
    return DocumentPermission(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'role': role.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DocumentPermission.fromJson(Map<String, dynamic> json) {
    return DocumentPermission(
      id: json['id'] as String,
      documentId: json['document_id'] as String,
      userId: json['user_id'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? '',
      userName: json['user_name'] as String?,
      role: PermissionRole.fromValue(json['role'] as String? ?? 'viewer'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
