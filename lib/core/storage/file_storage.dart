class UploadedFileInfo {
  const UploadedFileInfo({
    required this.storagePath,
    required this.downloadUrl,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
  });

  final String storagePath;
  final String? downloadUrl;
  final String fileName;
  final int fileSize;
  final String mimeType;
}

abstract class FileStorage {
  Future<UploadedFileInfo> uploadFile({
    required String ownerId,
    required String documentId,
    required String fileName,
    required List<int> fileBytes,
    String? mimeType,
  });

  Future<String> getDownloadUrl(String storagePath);

  Future<void> deleteFile(String storagePath);
}
