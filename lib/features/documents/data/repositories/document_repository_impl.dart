import '../../../../core/search/search_query.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_permission.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_local_datasource.dart';
import '../datasources/document_remote_datasource.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl(
    this.localDataSource, {
    this.remoteDataSource,
    this.authRepository,
  });

  final DocumentLocalDataSource localDataSource;
  final DocumentRemoteDataSource? remoteDataSource;
  final AuthRepository? authRepository;

  String get _currentUserId =>
      authRepository?.currentUser?.id ?? 'default-user-id';
  String get _currentUserEmail =>
      authRepository?.currentUser?.email ?? 'user@example.com';

  @override
  Future<Document> create(Document document) async {
    final currentUser = authRepository?.currentUser;
    if (remoteDataSource != null && currentUser == null) {
      throw StateError(
        'Bạn cần đăng nhập Firebase trước khi lưu tài liệu lên Supabase.',
      );
    }

    final docWithOwner = document.copyWith(
      ownerId: document.ownerId ?? currentUser?.id ?? _currentUserId,
      ownerEmail:
          document.ownerEmail ?? currentUser?.email ?? _currentUserEmail,
      currentUserRole: PermissionRole.owner,
    );

    if (remoteDataSource != null) {
      final savedRemote = await remoteDataSource!.insertDocument(docWithOwner);
      // Cập nhật local cache
      final localList = await localDataSource.getAll();
      localList.removeWhere((d) => d.id == savedRemote.id);
      localList.add(savedRemote);
      await localDataSource.saveAll(localList);
      return savedRemote;
    }

    final documents = await localDataSource.getAll();
    documents.add(docWithOwner);
    await localDataSource.saveAll(documents);
    return docWithOwner;
  }

  @override
  Future<Document?> getById(String id) async {
    if (remoteDataSource != null) {
      return remoteDataSource!.getById(
        id: id,
        currentUserId: _currentUserId,
        currentUserEmail: _currentUserEmail,
      );
    }

    for (final document in await localDataSource.getAll()) {
      if (document.id == id) return document;
    }
    return null;
  }

  @override
  Stream<List<Document>> watchAll() async* {
    if (remoteDataSource != null) {
      final remoteDocs = await remoteDataSource!.fetchDocuments(
        currentUserId: _currentUserId,
        currentUserEmail: _currentUserEmail,
      );
      yield remoteDocs;
      return;
    }

    yield await localDataSource.getAll();
  }

  @override
  Future<Document> update(Document document) async {
    if (remoteDataSource != null) {
      final updated = await remoteDataSource!.updateDocument(
        document,
        currentUserId: _currentUserId,
        currentUserEmail: _currentUserEmail,
      );
      final localList = await localDataSource.getAll();
      final idx = localList.indexWhere((d) => d.id == updated.id);
      if (idx != -1) {
        localList[idx] = updated;
        await localDataSource.saveAll(localList);
      }
      return updated;
    }

    final documents = await localDataSource.getAll();
    final index = documents.indexWhere((item) => item.id == document.id);
    if (index == -1) throw StateError('Document not found: ${document.id}');
    documents[index] = document;
    await localDataSource.saveAll(documents);
    return document;
  }

  @override
  Future<void> delete(String id) async {
    if (remoteDataSource != null) {
      await remoteDataSource!.deleteDocument(id, currentUserId: _currentUserId);
      final localList = await localDataSource.getAll();
      localList.removeWhere((d) => d.id == id);
      await localDataSource.saveAll(localList);
      return;
    }

    final documents = await localDataSource.getAll();
    documents.removeWhere((document) => document.id == id);
    await localDataSource.saveAll(documents);
  }

  @override
  Future<List<Document>> search(DocumentSearchQuery query) async {
    if (remoteDataSource != null) {
      return remoteDataSource!.searchDocuments(
        query: query,
        currentUserId: _currentUserId,
        currentUserEmail: _currentUserEmail,
      );
    }

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
      if (query.categoryId != null && document.subjectId != query.categoryId) {
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

  @override
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetEmail,
    required PermissionRole role,
  }) async {
    if (remoteDataSource == null) {
      return DocumentPermission(
        id: 'local-perm-${DateTime.now().microsecondsSinceEpoch}',
        documentId: documentId,
        userId: targetEmail,
        userEmail: targetEmail,
        role: role,
        createdAt: DateTime.now(),
      );
    }

    return remoteDataSource!.shareDocument(
      documentId: documentId,
      targetEmail: targetEmail,
      role: role,
      currentUserId: _currentUserId,
    );
  }

  @override
  Future<List<DocumentPermission>> getPermissions(String documentId) async {
    if (remoteDataSource == null) return [];
    return remoteDataSource!.getPermissions(documentId);
  }

  @override
  Future<void> revokePermission(String permissionId) async {
    if (remoteDataSource == null) return;
    return remoteDataSource!.revokePermission(
      permissionId,
      currentUserId: _currentUserId,
    );
  }
}
