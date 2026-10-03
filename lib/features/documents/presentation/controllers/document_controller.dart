import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../../core/search/search_query.dart';
import '../../domain/entities/document.dart';
import '../../domain/usecases/create_document.dart';
import '../../domain/usecases/delete_document.dart';
import '../../domain/usecases/list_documents.dart';
import '../../domain/usecases/search_documents.dart';
import '../../domain/usecases/update_document.dart';

class DocumentController extends ChangeNotifier {
	DocumentController(
		this._listDocuments,
		this._createDocument,
		this._updateDocument,
		this._deleteDocument,
		this._searchDocuments,
	);

	final ListDocuments _listDocuments;
	final CreateDocument _createDocument;
	final UpdateDocument _updateDocument;
	final DeleteDocument _deleteDocument;
	final SearchDocuments _searchDocuments;

	List<Document> documents = [];
	List<Document> searchResults = [];
	bool isLoading = false;
	String? errorMessage;

	Document? documentById(String id) {
		for (final document in documents) {
			if (document.id == id) return document;
		}
		return null;
	}

	Future<void> load() async {
		isLoading = true;
		errorMessage = null;
		notifyListeners();
		try {
			documents = await _listDocuments();
			searchResults = documents;
		} catch (error) {
			errorMessage = error.toString();
		} finally {
			isLoading = false;
			notifyListeners();
		}
	}

	Future<void> create({
		required String title,
		required String type,
		String? description,
		String? subject,
		String? author,
		String? filePath,
		String? externalUrl,
		List<String> tags = const [],
	}) async {
		final now = DateTime.now();
		final document = Document(
			id: '${now.microsecondsSinceEpoch}-${Random.secure().nextInt(0x7fffffff)}',
			title: title.trim(),
			type: type,
			description: _clean(description),
			subjectId: _clean(subject),
			author: _clean(author),
			filePath: _clean(filePath),
			externalUrl: _clean(externalUrl),
			tags: tags,
			createdAt: now,
			updatedAt: now,
		);
		await _createDocument(document);
		await load();
	}

	Future<void> update({
		required Document original,
		required String title,
		required String type,
		String? description,
		String? subject,
		String? author,
		String? filePath,
		String? externalUrl,
		List<String> tags = const [],
	}) async {
		final document = Document(
			id: original.id,
			title: title.trim(),
			type: type,
			description: _clean(description),
			subjectId: _clean(subject),
			author: _clean(author),
			filePath: _clean(filePath),
			externalUrl: _clean(externalUrl),
			tags: tags,
			createdAt: original.createdAt,
			updatedAt: DateTime.now(),
		);
		await _updateDocument(document);
		await load();
	}

	Future<void> delete(String id) async {
		await _deleteDocument(id);
		await load();
	}

	Future<void> search(DocumentSearchQuery query) async {
		errorMessage = null;
		try {
			searchResults = await _searchDocuments(query);
		} catch (error) {
			errorMessage = error.toString();
			searchResults = [];
		}
		notifyListeners();
	}

	static String? _clean(String? value) {
		final cleaned = value?.trim();
		return cleaned == null || cleaned.isEmpty ? null : cleaned;
	}
}
