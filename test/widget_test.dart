// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:learning_docs/core/search/search_query.dart';
import 'package:learning_docs/features/documents/data/datasources/document_local_datasource.dart';
import 'package:learning_docs/features/documents/data/repositories/document_repository_impl.dart';
import 'package:learning_docs/features/documents/domain/entities/document.dart';
import 'package:learning_docs/features/documents/domain/usecases/create_document.dart';
import 'package:learning_docs/features/documents/domain/usecases/delete_document.dart';
import 'package:learning_docs/features/documents/domain/usecases/list_documents.dart';
import 'package:learning_docs/features/documents/domain/usecases/search_documents.dart';
import 'package:learning_docs/features/documents/domain/usecases/update_document.dart';
import 'package:learning_docs/features/documents/presentation/controllers/document_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('document CRUD and search persist through the local repository', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = DocumentRepositoryImpl(
      PreferencesDocumentLocalDataSource(preferences),
    );
    final now = DateTime(2026, 10, 3);
    final document = Document(
      id: 'document-1',
      title: 'Linear algebra notes',
      description: 'Lecture notes',
      type: 'lecture',
      subjectId: 'Mathematics',
      author: 'A. Student',
      tags: const ['algebra', 'exam'],
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(document);
    expect((await repository.getById(document.id))?.title, document.title);
    expect(
      (await repository.search(
        DocumentSearchQuery(keyword: 'mathematics', tagIds: ['exam']),
      )).map((item) => item.id),
      [document.id],
    );
    expect(
      (await repository.search(
        DocumentSearchQuery(
          from: DateTime(2026, 10, 3),
          to: DateTime(2026, 10, 3, 23, 59, 59, 999, 999),
        ),
      )).map((item) => item.id),
      [document.id],
    );

    final updated = Document(
      id: document.id,
      title: 'Linear algebra review',
      type: document.type,
      subjectId: document.subjectId,
      tags: document.tags,
      createdAt: document.createdAt,
      updatedAt: now.add(const Duration(days: 1)),
    );
    await repository.update(updated);
    expect((await repository.watchAll().first).single.title, updated.title);

    await repository.delete(document.id);
    expect(await repository.getById(document.id), isNull);
  });

  test('controller creates a document with a non-empty ID', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = DocumentRepositoryImpl(
      PreferencesDocumentLocalDataSource(preferences),
    );
    final controller = DocumentController(
      ListDocuments(repository),
      CreateDocument(repository),
      UpdateDocument(repository),
      DeleteDocument(repository),
      SearchDocuments(repository),
    );

    await controller.create(
      title: 'New document',
      type: 'lecture',
      externalUrl: 'https://example.com/notes',
    );

    expect(controller.documents, hasLength(1));
    expect(controller.documents.single.id, isNotEmpty);
    controller.dispose();
  });
}
