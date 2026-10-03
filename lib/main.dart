import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/documents/data/datasources/document_local_datasource.dart';
import 'features/documents/data/repositories/document_repository_impl.dart';
import 'features/documents/domain/usecases/create_document.dart';
import 'features/documents/domain/usecases/delete_document.dart';
import 'features/documents/domain/usecases/list_documents.dart';
import 'features/documents/domain/usecases/search_documents.dart';
import 'features/documents/domain/usecases/update_document.dart';
import 'features/documents/presentation/controllers/document_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  await controller.load();
  runApp(App(controller: controller));
}
