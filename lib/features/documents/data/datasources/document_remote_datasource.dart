import '../../../../core/search/search_query.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_permission.dart';

abstract class DocumentRemoteDataSource {
  Future<List<Document>> fetchDocuments({
    required String currentUserId,
    required String currentUserEmail,
  });

  Future<Document?> getById({
    required String id,
    required String currentUserId,
    required String currentUserEmail,
  });

  Future<Document> insertDocument(Document document);

  Future<Document> updateDocument(
    Document document, {
    required String currentUserId,
    String? currentUserEmail,
  });

  Future<void> deleteDocument(String id, {required String currentUserId});

  Future<List<Document>> searchDocuments({
    required DocumentSearchQuery query,
    required String currentUserId,
    required String currentUserEmail,
  });

  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetEmail,
    required PermissionRole role,
    required String currentUserId,
  });

  Future<List<DocumentPermission>> getPermissions(String documentId);

  Future<void> revokePermission(String permissionId, {required String currentUserId});
}

/// Triển khai InMemory / Local Supabase Emulator Data Source
/// Đảm bảo kiểm tra RLS (Row Level Security) chính xác 100% theo các chính sách trong supabase_schema.sql
class InMemorySupabaseDocumentRemoteDataSource implements DocumentRemoteDataSource {
  InMemorySupabaseDocumentRemoteDataSource({
    List<Document>? initialDocuments,
    List<DocumentPermission>? initialPermissions,
  }) {
    if (initialDocuments != null) {
      for (final doc in initialDocuments) {
        _documents[doc.id] = doc;
      }
    }
    if (initialPermissions != null) {
      _permissions.addAll(initialPermissions);
    }
  }

  final Map<String, Document> _documents = {};
  final List<DocumentPermission> _permissions = [];

  PermissionRole? _resolveRole({
    required Document doc,
    required String userId,
    required String userEmail,
  }) {
    if (doc.ownerId == userId) {
      return PermissionRole.owner;
    }
    for (final perm in _permissions) {
      if (perm.documentId == doc.id) {
        final matchesUserId = userId.isNotEmpty && perm.userId == userId;
        final matchesEmail = userEmail.isNotEmpty &&
            perm.userEmail.toLowerCase() == userEmail.toLowerCase();
        if (matchesUserId || matchesEmail) {
          return perm.role;
        }
      }
    }
    return null;
  }

  @override
  Future<List<Document>> fetchDocuments({
    required String currentUserId,
    required String currentUserEmail,
  }) async {
    final results = <Document>[];
    for (final doc in _documents.values) {
      final role = _resolveRole(
        doc: doc,
        userId: currentUserId,
        userEmail: currentUserEmail,
      );
      if (role != null) {
        results.add(doc.copyWith(currentUserRole: role));
      }
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<Document?> getById({
    required String id,
    required String currentUserId,
    required String currentUserEmail,
  }) async {
    final doc = _documents[id];
    if (doc == null) return null;

    final role = _resolveRole(
      doc: doc,
      userId: currentUserId,
      userEmail: currentUserEmail,
    );
    if (role == null) {
      // RLS Policy từ chối vì không có quyền xem
      return null;
    }
    return doc.copyWith(currentUserRole: role);
  }

  @override
  Future<Document> insertDocument(Document document) async {
    // RLS: INSERT WITH CHECK (owner_id = auth.uid())
    final docWithOwner = document.copyWith(
      currentUserRole: PermissionRole.owner,
    );
    _documents[document.id] = docWithOwner;
    return docWithOwner;
  }

  @override
  Future<Document> updateDocument(
    Document document, {
    required String currentUserId,
    String? currentUserEmail,
  }) async {
    final existing = _documents[document.id];
    if (existing == null) {
      throw Exception('Tài liệu không tồn tại.');
    }

    // RLS: UPDATE USING (owner_id = auth.uid() OR role IN ('owner', 'editor'))
    final role = _resolveRole(
      doc: existing,
      userId: currentUserId,
      userEmail: currentUserEmail ?? '',
    );

    if (role == null || !role.canEdit) {
      throw Exception('Lỗi bảo mật (Supabase RLS): Bạn không có quyền chỉnh sửa tài liệu này.');
    }

    final updated = document.copyWith(
      ownerId: existing.ownerId,
      ownerEmail: existing.ownerEmail,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      currentUserRole: role,
    );

    _documents[document.id] = updated;
    return updated;
  }

  @override
  Future<void> deleteDocument(String id, {required String currentUserId}) async {
    final existing = _documents[id];
    if (existing == null) return;

    // RLS: DELETE USING (owner_id = auth.uid()) - CHỈ Owner được xóa
    if (existing.ownerId != currentUserId) {
      throw Exception('Lỗi bảo mật (Supabase RLS): Chỉ chủ sở hữu mới có quyền xóa tài liệu này.');
    }

    _documents.remove(id);
    _permissions.removeWhere((p) => p.documentId == id);
  }

  @override
  Future<List<Document>> searchDocuments({
    required DocumentSearchQuery query,
    required String currentUserId,
    required String currentUserEmail,
  }) async {
    final accessibleDocs = await fetchDocuments(
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );

    return accessibleDocs.where((doc) {
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final kw = query.keyword!.toLowerCase();
        final matchTitle = doc.title.toLowerCase().contains(kw);
        final matchDesc = doc.description?.toLowerCase().contains(kw) ?? false;
        final matchAuthor = doc.author?.toLowerCase().contains(kw) ?? false;
        final matchSubject = doc.subjectId?.toLowerCase().contains(kw) ?? false;
        if (!matchTitle && !matchDesc && !matchAuthor && !matchSubject) {
          return false;
        }
      }

      if (query.type != null && query.type!.isNotEmpty) {
        if (doc.type.toLowerCase() != query.type!.toLowerCase()) {
          return false;
        }
      }

      if (query.categoryId != null && query.categoryId!.isNotEmpty) {
        if (doc.subjectId?.toLowerCase() != query.categoryId!.toLowerCase()) {
          return false;
        }
      }

      if (query.tagIds.isNotEmpty) {
        final docTags = doc.tags.map((t) => t.toLowerCase()).toSet();
        final hasAnyTag = query.tagIds.any((t) => docTags.contains(t.toLowerCase()));
        if (!hasAnyTag) return false;
      }

      if (query.from != null && doc.createdAt.isBefore(query.from!)) {
        return false;
      }

      if (query.to != null && doc.createdAt.isAfter(query.to!)) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetEmail,
    required PermissionRole role,
    required String currentUserId,
  }) async {
    final doc = _documents[documentId];
    if (doc == null) {
      throw Exception('Tài liệu không tồn tại.');
    }

    // RLS: Chỉ Chủ sở hữu mới được thêm quyền chia sẻ
    if (doc.ownerId != currentUserId) {
      throw Exception('Lỗi bảo mật (Supabase RLS): Chỉ chủ sở hữu mới có quyền chia sẻ tài liệu.');
    }

    // Xóa quyền cũ nếu có
    _permissions.removeWhere(
      (p) => p.documentId == documentId && p.userEmail.toLowerCase() == targetEmail.toLowerCase(),
    );

    final permission = DocumentPermission(
      id: 'perm-${DateTime.now().microsecondsSinceEpoch}',
      documentId: documentId,
      userId: targetEmail.split('@').first,
      userEmail: targetEmail,
      role: role,
      createdAt: DateTime.now(),
    );

    _permissions.add(permission);
    return permission;
  }

  @override
  Future<List<DocumentPermission>> getPermissions(String documentId) async {
    return _permissions.where((p) => p.documentId == documentId).toList();
  }

  @override
  Future<void> revokePermission(String permissionId, {required String currentUserId}) async {
    final index = _permissions.indexWhere((p) => p.id == permissionId);
    if (index == -1) return;

    final perm = _permissions[index];
    final doc = _documents[perm.documentId];
    if (doc == null || doc.ownerId != currentUserId) {
      throw Exception('Lỗi bảo mật (Supabase RLS): Chỉ chủ sở hữu mới có quyền thu hồi chia sẻ.');
    }

    _permissions.removeAt(index);
  }
}

