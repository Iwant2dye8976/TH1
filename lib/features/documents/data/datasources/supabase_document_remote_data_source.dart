import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/search/search_query.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_permission.dart';
import '../models/document_model.dart';
import 'document_remote_datasource.dart';

class SupabaseDocumentRemoteDataSource implements DocumentRemoteDataSource {
  SupabaseDocumentRemoteDataSource(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _supabase {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase chưa được cấu hình. Hãy chạy ứng dụng với '
        '--dart-define=SUPABASE_ANON_KEY=<anon-key>.',
      );
    }
    return client;
  }

  @override
  Future<List<Document>> fetchDocuments({
    required String currentUserId,
    required String currentUserEmail,
  }) async {
    final rows = await _supabase
        .from('documents')
        .select()
        .order('created_at', ascending: false);
    final permissions = await _permissionsVisibleToCurrentUser();

    return rows.map((row) {
      final document = DocumentModel.fromJson(row).document;
      final role = _roleFor(
        document: document,
        currentUserId: currentUserId,
        permissions: permissions,
      );
      return document.copyWith(currentUserRole: role);
    }).toList();
  }

  @override
  Future<Document?> getById({
    required String id,
    required String currentUserId,
    required String currentUserEmail,
  }) async {
    final row = await _supabase
        .from('documents')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;

    final document = DocumentModel.fromJson(row).document;
    final role = _roleFor(
      document: document,
      currentUserId: currentUserId,
      permissions: await _permissionsVisibleToCurrentUser(),
    );
    return document.copyWith(currentUserRole: role);
  }

  @override
  Future<Document> insertDocument(Document document) async {
    final values = DocumentModel(document).toSupabaseMap()
      ..remove('current_user_role');
    Map<String, dynamic> row;
    try {
      row = await _supabase.from('documents').insert(values).select().single();
    } on PostgrestException catch (error, stackTrace) {
      if (error.code != '42501') {
        Error.throwWithStackTrace(error, stackTrace);
      }
      await _throwInsertDiagnostics(
        targetOwnerId: values['owner_id']?.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    return DocumentModel.fromJson(row).document
        .copyWith(currentUserRole: PermissionRole.owner);
  }

  Future<Never> _throwInsertDiagnostics({
    required String? targetOwnerId,
    required PostgrestException originalError,
    required StackTrace stackTrace,
  }) async {
    try {
      final result = await _supabase.rpc(
        'document_insert_diagnostics',
        params: {'target_owner_id': targetOwnerId},
      );
      final row = result is List && result.isNotEmpty
          ? Map<String, dynamic>.from(result.first as Map)
          : <String, dynamic>{};

      String status(String key) => row[key] == true ? 'có' : 'KHÔNG có';
      final role = row['request_role']?.toString() ?? 'không xác định';

      throw StateError(
        'Supabase từ chối INSERT tài liệu (42501). '
        'Chẩn đoán: role=$role; issuer Firebase '
        '${row['firebase_issuer_matches'] == true ? 'khớp' : 'không khớp'}; '
        'audience Firebase '
        '${row['firebase_audience_matches'] == true ? 'khớp' : 'không khớp'}; '
        'có Firebase UID ${status('firebase_subject_present')}; '
        'owner_id khớp UID '
        '${row['owner_matches_firebase_subject'] == true ? 'có' : 'không'}; '
        'quyền SQL INSERT ${status('can_insert_documents')}; '
        'quyền SQL SELECT ${status('can_select_documents')}. '
        'Lỗi máy chủ: ${originalError.message}',
      );
    } on StateError {
      rethrow;
    } catch (diagnosticError) {
      Error.throwWithStackTrace(
        StateError(
          'Supabase từ chối INSERT tài liệu (42501), nhưng không lấy được '
          'chẩn đoán JWT: $diagnosticError. Lỗi gốc: ${originalError.message}',
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Document> updateDocument(
    Document document, {
    required String currentUserId,
    String? currentUserEmail,
  }) async {
    final values = DocumentModel(document).toSupabaseMap()
      ..remove('id')
      ..remove('owner_id')
      ..remove('owner_email')
      ..remove('created_at')
      ..remove('current_user_role');
    final row = await _supabase
        .from('documents')
        .update(values)
        .eq('id', document.id)
        .select()
        .single();
    return DocumentModel.fromJson(row).document;
  }

  @override
  Future<void> deleteDocument(
    String id, {
    required String currentUserId,
  }) async {
    final row = await _supabase
        .from('documents')
        .delete()
        .eq('id', id)
        .select('id')
        .maybeSingle();
    if (row == null) {
      throw StateError('Không tìm thấy tài liệu hoặc bạn không có quyền xóa.');
    }
  }

  @override
  Future<List<Document>> searchDocuments({
    required DocumentSearchQuery query,
    required String currentUserId,
    required String currentUserEmail,
  }) async {
    final documents = await fetchDocuments(
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );
    final keyword = query.keyword?.trim().toLowerCase();

    return documents.where((document) {
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
      if (query.type != null &&
          query.type!.isNotEmpty &&
          document.type.toLowerCase() != query.type!.toLowerCase()) {
        return false;
      }
      if (query.categoryId != null &&
          query.categoryId!.isNotEmpty &&
          document.subjectId?.toLowerCase() !=
              query.categoryId!.toLowerCase()) {
        return false;
      }
      if (query.tagIds.isNotEmpty &&
          !query.tagIds.any(
            (tag) => document.tags.any(
              (documentTag) => documentTag.toLowerCase() == tag.toLowerCase(),
            ),
          )) {
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
  }

  @override
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetEmail,
    required PermissionRole role,
    required String currentUserId,
  }) async {
    if (role == PermissionRole.owner) {
      throw ArgumentError(
        'Không thể cấp vai trò chủ sở hữu khi chia sẻ tài liệu.',
      );
    }

    final email = targetEmail.trim().toLowerCase();
    final matches = await _supabase.rpc(
      'find_share_recipient',
      params: {'target_email': email},
    );
    final profile = matches is List && matches.isNotEmpty
        ? Map<String, dynamic>.from(matches.first as Map)
        : null;
    if (profile == null) {
      throw StateError(
        'Người nhận cần đăng nhập ứng dụng trước khi được chia sẻ tài liệu.',
      );
    }

    final row = await _supabase
        .from('document_permissions')
        .upsert({
          'document_id': documentId,
          'user_id': profile['auth_uid'],
          'user_email': email,
          'role': role.value,
        }, onConflict: 'document_id,user_email')
        .select()
        .single();
    return DocumentPermission.fromJson({
      ...row,
      'user_name': profile['display_name'],
    });
  }

  @override
  Future<List<DocumentPermission>> getPermissions(String documentId) async {
    final rows = await _supabase
        .from('document_permissions')
        .select()
        .eq('document_id', documentId)
        .order('created_at');
    return rows.map(DocumentPermission.fromJson).toList();
  }

  @override
  Future<void> revokePermission(
    String permissionId, {
    required String currentUserId,
  }) async {
    final row = await _supabase
        .from('document_permissions')
        .delete()
        .eq('id', permissionId)
        .select('id')
        .maybeSingle();
    if (row == null) {
      throw StateError(
        'Không tìm thấy quyền chia sẻ hoặc bạn không có quyền thu hồi.',
      );
    }
  }

  Future<List<DocumentPermission>> _permissionsVisibleToCurrentUser() async {
    final rows = await _supabase.from('document_permissions').select();
    return rows.map(DocumentPermission.fromJson).toList();
  }

  PermissionRole _roleFor({
    required Document document,
    required String currentUserId,
    required List<DocumentPermission> permissions,
  }) {
    if (document.ownerId == currentUserId) return PermissionRole.owner;
    for (final permission in permissions) {
      if (permission.documentId == document.id) return permission.role;
    }
    return PermissionRole.viewer;
  }
}
