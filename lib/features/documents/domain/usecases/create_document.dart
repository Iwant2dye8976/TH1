import '../entities/document.dart';
import '../repositories/document_repository.dart';
import '../validators/document_validator.dart';

class CreateDocument {
  final DocumentRepository repository;
  final DocumentValidator validator = const DocumentValidator();

  CreateDocument(this.repository);

  Future<Document> call(Document document) {
    validator.validate(document);
    return repository.create(document);
  }
}

