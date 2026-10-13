import '../entities/document_permission.dart';
import '../repositories/document_repository.dart';

class ShareDocument {
  const ShareDocument(this._repository);

  final DocumentRepository _repository;

  Future<DocumentPermission> call({
    required String documentId,
    required String targetEmail,
    required PermissionRole role,
  }) {
    if (targetEmail.trim().isEmpty) {
      throw ArgumentError('Email người nhận không được để trống.');
    }
    return _repository.shareDocument(
      documentId: documentId,
      targetEmail: targetEmail.trim(),
      role: role,
    );
  }
}

