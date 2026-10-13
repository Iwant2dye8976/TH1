import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'file_storage.dart';

class SupabaseFileStorage implements FileStorage {
  SupabaseFileStorage({
    required this._client,
    this.bucketName = 'learning-docs',
  });

  static const maxFileSizeBytes = 50 * 1024 * 1024;

  final SupabaseClient? _client;
  final String bucketName;
  final Random _random = Random.secure();

  SupabaseClient get _supabase {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase chưa được cấu hình. Không thể tải tệp lên đám mây.',
      );
    }
    return client;
  }

  @override
  Future<UploadedFileInfo> uploadFile({
    required String ownerId,
    required String documentId,
    required String fileName,
    required List<int> fileBytes,
    String? mimeType,
  }) async {
    if (fileBytes.isEmpty) throw ArgumentError('Tệp được chọn đang trống.');
    if (fileBytes.length > maxFileSizeBytes) {
      throw ArgumentError('Dung lượng tệp không được vượt quá 50 MB.');
    }

    final cleanName = fileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'^\.+' ), '');
    if (cleanName.isEmpty) throw ArgumentError('Tên tệp không hợp lệ.');

    final storagePath =
        'documents/$ownerId/$documentId/${_random.nextInt(0x7fffffff)}_$cleanName';
    final resolvedMimeType = mimeType ?? _guessMimeType(fileName);

    await _supabase.storage
        .from(bucketName)
        .uploadBinary(
          storagePath,
          Uint8List.fromList(fileBytes),
          fileOptions: FileOptions(
            contentType: resolvedMimeType,
            cacheControl: '3600',
          ),
        );

    return UploadedFileInfo(
      storagePath: storagePath,
      downloadUrl: null,
      fileName: fileName,
      fileSize: fileBytes.length,
      mimeType: resolvedMimeType,
    );
  }

  @override
  Future<String> getDownloadUrl(String storagePath) {
    return _supabase.storage
        .from(bucketName)
        .createSignedUrl(storagePath, 60 * 60);
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    await _supabase.storage.from(bucketName).remove([storagePath]);
  }

  static String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.zip')) return 'application/zip';
    return 'application/octet-stream';
  }
}
