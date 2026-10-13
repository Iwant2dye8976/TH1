import '../entities/document_permission.dart';
import '../repositories/document_repository.dart';

class GetDocumentPermissions {
  const GetDocumentPermissions(this._repository);

  final DocumentRepository _repository;

  Future<List<DocumentPermission>> call(String documentId) {
    return _repository.getPermissions(documentId);
  }
}

