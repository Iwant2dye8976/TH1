import '../entities/document.dart';
import '../entities/document_permission.dart';
import '../../../../core/search/search_query.dart';

abstract class DocumentRepository {
  Future<Document> create(Document document);
  Future<Document?> getById(String id);
  Stream<List<Document>> watchAll();
  Future<Document> update(Document document);
  Future<void> delete(String id);
  Future<List<Document>> search(DocumentSearchQuery query);

  // Phân quyền & chia sẻ
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetEmail,
    required PermissionRole role,
  });

  Future<List<DocumentPermission>> getPermissions(String documentId);
  Future<void> revokePermission(String permissionId);
}
