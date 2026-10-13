import '../../domain/entities/document.dart';
import '../../domain/entities/document_permission.dart';

class DocumentModel {
  const DocumentModel(this.document);

  final Document document;

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    final rawTags = json['tags'] ?? json['tags_json'];
    if (rawTags is List) {
      parsedTags = rawTags.map((e) => e.toString()).toList();
    }

    PermissionRole? parsedRole;
    final rawRole = json['current_user_role'] ?? json['currentUserRole'] ?? json['role'];
    if (rawRole != null) {
      parsedRole = PermissionRole.fromValue(rawRole.toString());
    }

    return DocumentModel(
      Document(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: json['description'] as String?,
        type: (json['type'] ?? 'other').toString(),
        subjectId: (json['subject_id'] ?? json['subjectId']) as String?,
        author: json['author'] as String?,
        filePath: (json['file_path'] ?? json['filePath']) as String?,
        externalUrl: (json['external_url'] ?? json['externalUrl']) as String?,
        tags: parsedTags,
        createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt'] ?? '').toString()) ??
            DateTime.now(),
        updatedAt: DateTime.tryParse((json['updated_at'] ?? json['updatedAt'] ?? '').toString()) ??
            DateTime.now(),
        ownerId: (json['owner_id'] ?? json['ownerId']) as String?,
        ownerEmail: (json['owner_email'] ?? json['ownerEmail']) as String?,
        storagePath: (json['storage_path'] ?? json['storagePath']) as String?,
        fileSize: json['file_size'] != null
            ? int.tryParse(json['file_size'].toString())
            : json['fileSize'] as int?,
        mimeType: (json['mime_type'] ?? json['mimeType']) as String?,
        currentUserRole: parsedRole,
      ),
    );
  }

  Map<String, Object?> toJson() => {
        'id': document.id,
        'title': document.title,
        'description': document.description,
        'type': document.type,
        'subjectId': document.subjectId,
        'subject_id': document.subjectId,
        'author': document.author,
        'filePath': document.filePath,
        'file_path': document.filePath,
        'storage_path': document.storagePath,
        'externalUrl': document.externalUrl,
        'external_url': document.externalUrl,
        'file_size': document.fileSize,
        'mime_type': document.mimeType,
        'tags': document.tags,
        'createdAt': document.createdAt.toIso8601String(),
        'created_at': document.createdAt.toIso8601String(),
        'updatedAt': document.updatedAt.toIso8601String(),
        'updated_at': document.updatedAt.toIso8601String(),
        'owner_id': document.ownerId,
        'owner_email': document.ownerEmail,
        'current_user_role': document.currentUserRole?.value,
      };

  /// Chuyển đổi sang format lưu trữ Supabase Table (snake_case chuẩn SQL)
  Map<String, dynamic> toSupabaseMap() => {
        'id': document.id,
        'owner_id': document.ownerId,
        'owner_email': document.ownerEmail ?? '',
        'title': document.title,
        'description': document.description,
        'type': document.type,
        'subject_id': document.subjectId,
        'author': document.author,
        'file_path': document.filePath,
        'storage_path': document.storagePath,
        'external_url': document.externalUrl,
        'file_size': document.fileSize,
        'mime_type': document.mimeType,
        'tags': document.tags,
        'created_at': document.createdAt.toIso8601String(),
        'updated_at': document.updatedAt.toIso8601String(),
      };
}
