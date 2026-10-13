import 'document_permission.dart';

class Document {
  final String id;
  final String title;
  final String? description;
  final String type;
  final String? subjectId;
  final String? author;
  final String? filePath;
  final String? externalUrl;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Thuộc tính phục vụ liên kết Firebase Storage & Supabase & phân quyền
  final String? ownerId;
  final String? ownerEmail;
  final String? storagePath;
  final int? fileSize;
  final String? mimeType;
  final PermissionRole? currentUserRole;

  Document({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.subjectId,
    this.author,
    this.filePath,
    this.externalUrl,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.ownerId,
    this.ownerEmail,
    this.storagePath,
    this.fileSize,
    this.mimeType,
    this.currentUserRole,
  });

  Document copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? subjectId,
    String? author,
    String? filePath,
    String? externalUrl,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerId,
    String? ownerEmail,
    String? storagePath,
    int? fileSize,
    String? mimeType,
    PermissionRole? currentUserRole,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      subjectId: subjectId ?? this.subjectId,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      externalUrl: externalUrl ?? this.externalUrl,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      storagePath: storagePath ?? this.storagePath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      currentUserRole: currentUserRole ?? this.currentUserRole,
    );
  }

  bool get isOwner => currentUserRole == PermissionRole.owner;
  bool get canEdit => currentUserRole?.canEdit ?? false;
  bool get canDelete => currentUserRole?.canDelete ?? false;
  bool get canShare => currentUserRole?.canShare ?? false;
}

enum DocumentType {
  lecture('lecture', 'Bài giảng'),
  assignment('assignment', 'Bài tập'),
  reference('reference', 'Tài liệu tham khảo'),
  exam('exam', 'Đề thi'),
  note('note', 'Ghi chú'),
  other('other', 'Khác');

  const DocumentType(this.value, this.label);

  final String value;
  final String label;

  static DocumentType fromValue(String value) => DocumentType.values
      .firstWhere((type) => type.value == value, orElse: () => other);
}
