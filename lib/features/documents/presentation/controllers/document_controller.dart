import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../../../core/search/search_query.dart';
import '../../../../core/storage/file_storage.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_permission.dart';
import '../../domain/usecases/create_document.dart';
import '../../domain/usecases/delete_document.dart';
import '../../domain/usecases/get_document_permissions.dart';
import '../../domain/usecases/list_documents.dart';
import '../../domain/usecases/revoke_document_permission.dart';
import '../../domain/usecases/search_documents.dart';
import '../../domain/usecases/share_document.dart';
import '../../domain/usecases/update_document.dart';

class DocumentController extends ChangeNotifier {
  DocumentController(
    this._listDocuments,
    this._createDocument,
    this._updateDocument,
    this._deleteDocument,
    this._searchDocuments, {
    this.shareDocument,
    this.getDocumentPermissions,
    this.revokeDocumentPermission,
    this.fileStorage,
    this.authRepository,
  });

  final ListDocuments _listDocuments;
  final CreateDocument _createDocument;
  final UpdateDocument _updateDocument;
  final DeleteDocument _deleteDocument;
  final SearchDocuments _searchDocuments;
  final ShareDocument? shareDocument;
  final GetDocumentPermissions? getDocumentPermissions;
  final RevokeDocumentPermission? revokeDocumentPermission;
  final FileStorage? fileStorage;
  final AuthRepository? authRepository;

  List<Document> documents = [];
  List<Document> searchResults = [];
  bool isLoading = false;
  Object? errorMessage;

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
      errorMessage = error;
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
    String? storagePath,
    int? fileSize,
    String? mimeType,
    String? uploadFileName,
    Uint8List? uploadFileBytes,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final id = _newUuidV4();
    final uploadedFile = await _uploadSelectedFile(
      documentId: id,
      fileName: uploadFileName,
      fileBytes: uploadFileBytes,
    );
    final document = Document(
      id: id,
      title: title.trim(),
      type: type,
      description: _clean(description),
      subjectId: _clean(subject),
      author: _clean(author),
      filePath: uploadedFile?.fileName ?? _clean(filePath),
      externalUrl: _clean(externalUrl),
      storagePath: uploadedFile?.storagePath ?? _clean(storagePath),
      fileSize: uploadedFile?.fileSize ?? fileSize,
      mimeType: uploadedFile?.mimeType ?? mimeType,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _createDocument(document);
    } catch (error, stackTrace) {
      if (uploadedFile != null) {
        await fileStorage!.deleteFile(uploadedFile.storagePath);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
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
    String? storagePath,
    int? fileSize,
    String? mimeType,
    String? uploadFileName,
    Uint8List? uploadFileBytes,
    List<String> tags = const [],
  }) async {
    final uploadedFile = await _uploadSelectedFile(
      documentId: original.id,
      fileName: uploadFileName,
      fileBytes: uploadFileBytes,
    );
    final document = Document(
      id: original.id,
      title: title.trim(),
      type: type,
      description: _clean(description),
      subjectId: _clean(subject),
      author: _clean(author),
      filePath: uploadedFile?.fileName ?? _clean(filePath),
      externalUrl: _clean(externalUrl),
      storagePath: uploadedFile?.storagePath ?? storagePath ?? original.storagePath,
      fileSize: uploadedFile?.fileSize ?? fileSize ?? original.fileSize,
      mimeType: uploadedFile?.mimeType ?? mimeType ?? original.mimeType,
      tags: tags,
      ownerId: original.ownerId,
      ownerEmail: original.ownerEmail,
      currentUserRole: original.currentUserRole,
      createdAt: original.createdAt,
      updatedAt: DateTime.now(),
    );
    try {
      await _updateDocument(document);
    } catch (error, stackTrace) {
      if (uploadedFile != null) {
        await fileStorage!.deleteFile(uploadedFile.storagePath);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (uploadedFile != null &&
        original.storagePath != null &&
        original.storagePath != uploadedFile.storagePath) {
      await fileStorage!.deleteFile(original.storagePath!);
    }
    await load();
  }

  Future<void> delete(String id, {String? storagePath}) async {
    final oldPath = storagePath ?? documentById(id)?.storagePath;
    await _deleteDocument(id);
    if (oldPath != null && fileStorage != null) {
      await fileStorage!.deleteFile(oldPath);
    }
    await load();
  }

  Future<String> getFileDownloadUrl(String storagePath) {
    final storage = fileStorage;
    if (storage == null) {
      throw StateError('Chưa cấu hình dịch vụ lưu trữ tệp.');
    }
    return storage.getDownloadUrl(storagePath);
  }

  Future<UploadedFileInfo?> _uploadSelectedFile({
    required String documentId,
    required String? fileName,
    required Uint8List? fileBytes,
  }) async {
    if (fileName == null && fileBytes == null) return null;
    if (fileName == null || fileName.isEmpty || fileBytes == null) {
      throw ArgumentError('Không đọc được nội dung tệp đã chọn.');
    }
    final storage = fileStorage;
    if (storage == null) {
      throw StateError('Ứng dụng chưa được cấu hình tải tệp lên Supabase.');
    }
    final ownerId = authRepository?.currentUser?.id;
    if (ownerId == null || ownerId.isEmpty) {
      throw StateError('Bạn cần đăng nhập Firebase trước khi tải tệp lên.');
    }
    return storage.uploadFile(
      ownerId: ownerId,
      documentId: documentId,
      fileName: fileName,
      fileBytes: fileBytes,
    );
  }

  static String _newUuidV4() {
    final bytes = List<int>.generate(
      16,
      (_) => Random.secure().nextInt(256),
    );
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> search(DocumentSearchQuery query) async {
    errorMessage = null;
    try {
      searchResults = await _searchDocuments(query);
    } catch (error) {
      errorMessage = error;
      searchResults = [];
    }
    notifyListeners();
  }

  Future<DocumentPermission?> share({
    required String documentId,
    required String targetEmail,
    required PermissionRole role,
  }) async {
    if (shareDocument == null) return null;
    final perm = await shareDocument!(
      documentId: documentId,
      targetEmail: targetEmail,
      role: role,
    );
    await load();
    return perm;
  }

  Future<List<DocumentPermission>> fetchPermissions(String documentId) async {
    if (getDocumentPermissions == null) return [];
    return getDocumentPermissions!(documentId);
  }

  Future<void> revoke({
    required String documentId,
    required String permissionId,
  }) async {
    if (revokeDocumentPermission == null) return;
    await revokeDocumentPermission!(permissionId);
    await load();
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

}
