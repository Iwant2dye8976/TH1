import '../entities/document.dart';
import '../repositories/document_repository.dart';

class ListDocuments {
	ListDocuments(this.repository);

	final DocumentRepository repository;

	Future<List<Document>> call() => repository.watchAll().first;
}
