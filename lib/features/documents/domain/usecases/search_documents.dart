import '../../../../core/search/search_query.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';

class SearchDocuments {
	SearchDocuments(this.repository);

	final DocumentRepository repository;

	Future<List<Document>> call(DocumentSearchQuery query) =>
			repository.search(query);
}
