import '../repositories/document_repository.dart';

class RevokeDocumentPermission {
  const RevokeDocumentPermission(this._repository);

  final DocumentRepository _repository;

  Future<void> call(String permissionId) {
    return _repository.revokePermission(permissionId);
  }
}

