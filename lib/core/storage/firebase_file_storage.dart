import 'file_storage.dart';

class FirebaseFileStorage implements FileStorage {
  FirebaseFileStorage({this.bucketName = 'learning-docs.appspot.com'});

  final String bucketName;

  /// Đường dẫn lưu trữ chuẩn trên Firebase Storage:
  /// documents/{ownerId}/{documentId}/{fileName}
  static String buildStoragePath({
    required String ownerId,
    required String documentId,
    required String fileName,
  }) {
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return 'documents/$ownerId/$documentId/$sanitizedFileName';
  }

  @override
  Future<UploadedFileInfo> uploadFile({
    required String ownerId,
    required String documentId,
    required String fileName,
    required List<int> fileBytes,
    String? mimeType,
  }) async {
    final storagePath = buildStoragePath(
      ownerId: ownerId,
      documentId: documentId,
      fileName: fileName,
    );

    final resolvedMimeType = mimeType ?? _guessMimeType(fileName);

    // Đường dẫn Firebase Storage Download URL chuẩn
    final encodedPath = Uri.encodeComponent(storagePath);
    final downloadUrl =
        'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/$encodedPath?alt=media';

    return UploadedFileInfo(
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      fileName: fileName,
      fileSize: fileBytes.length,
      mimeType: resolvedMimeType,
    );
  }

  @override
  Future<String> getDownloadUrl(String storagePath) async {
    final encodedPath = Uri.encodeComponent(storagePath);
    return 'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/$encodedPath?alt=media';
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    // Gọi FirebaseStorage.instance.ref(storagePath).delete();
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
