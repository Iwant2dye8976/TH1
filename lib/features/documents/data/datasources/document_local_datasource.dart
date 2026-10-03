import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/document.dart';
import '../models/document_model.dart';

abstract class DocumentLocalDataSource {
  Future<List<Document>> getAll();
  Future<void> saveAll(List<Document> documents);
}

class PreferencesDocumentLocalDataSource implements DocumentLocalDataSource {
  PreferencesDocumentLocalDataSource(this.preferences);

  static const _storageKey = 'learning_docs.documents.v1';
  final SharedPreferences preferences;

  @override
  Future<List<Document>> getAll() async {
    final encoded = preferences.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return [];

    final values = jsonDecode(encoded) as List<dynamic>;
    return values
        .map(
          (value) =>
              DocumentModel.fromJson(value as Map<String, dynamic>).document,
        )
        .toList();
  }

  @override
  Future<void> saveAll(List<Document> documents) async {
    final encoded = jsonEncode(
      documents.map((document) => DocumentModel(document).toJson()).toList(),
    );
    await preferences.setString(_storageKey, encoded);
  }
}