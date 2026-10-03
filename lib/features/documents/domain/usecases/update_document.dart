import '../entities/document.dart';
import '../repositories/document_repository.dart';
import '../validators/document_validator.dart';

class UpdateDocument {
	UpdateDocument(this.repository);

	final DocumentRepository repository;
	final DocumentValidator validator = const DocumentValidator();

	Future<Document> call(Document document) {
		validator.validate(document);
		return repository.update(document);
	}
}
