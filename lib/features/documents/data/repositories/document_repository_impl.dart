import '../../../../core/search/search_query.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_local_datasource.dart';

class DocumentRepositoryImpl implements DocumentRepository {
	DocumentRepositoryImpl(this.localDataSource);

	final DocumentLocalDataSource localDataSource;

	@override
	Future<Document> create(Document document) async {
		final documents = await localDataSource.getAll();
		documents.add(document);
		await localDataSource.saveAll(documents);
		return document;
	}

	@override
	Future<Document?> getById(String id) async {
		for (final document in await localDataSource.getAll()) {
			if (document.id == id) return document;
		}
		return null;
	}

	@override
	Stream<List<Document>> watchAll() async* {
		yield await localDataSource.getAll();
	}

	@override
	Future<Document> update(Document document) async {
		final documents = await localDataSource.getAll();
		final index = documents.indexWhere((item) => item.id == document.id);
		if (index == -1) throw StateError('Document not found: ${document.id}');
		documents[index] = document;
		await localDataSource.saveAll(documents);
		return document;
	}

	@override
	Future<void> delete(String id) async {
		final documents = await localDataSource.getAll();
		documents.removeWhere((document) => document.id == id);
		await localDataSource.saveAll(documents);
	}

	@override
	Future<List<Document>> search(DocumentSearchQuery query) async {
		final keyword = query.keyword?.trim().toLowerCase();
		final documents = await localDataSource.getAll();
		final results = documents.where((document) {
			if (keyword != null && keyword.isNotEmpty) {
				final searchableText = [
					document.title,
					document.description ?? '',
					document.author ?? '',
					document.subjectId ?? '',
					...document.tags,
				].join(' ').toLowerCase();
				if (!searchableText.contains(keyword)) return false;
			}
			if (query.categoryId != null &&
					document.subjectId != query.categoryId) {
				return false;
			}
			if (query.type != null && document.type != query.type) return false;
			if (query.tagIds.isNotEmpty &&
					!query.tagIds.any(document.tags.contains)) {
				return false;
			}
			if (query.from != null && document.createdAt.isBefore(query.from!)) {
				return false;
			}
			if (query.to != null && document.createdAt.isAfter(query.to!)) {
				return false;
			}
			return true;
		}).toList();
		results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
		return results;
	}
}
