import '../repositories/document_repository.dart';

class DeleteDocument {
	DeleteDocument(this.repository);

	final DocumentRepository repository;

	Future<void> call(String id) => repository.delete(id);
}
