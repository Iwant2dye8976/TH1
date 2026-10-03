import '../entities/document.dart';

class DocumentValidator {
  const DocumentValidator();

  void validate(Document document) {
    if (document.title.trim().isEmpty) {
      throw ArgumentError('Tiêu đề tài liệu không được để trống.');
    }
    if (!DocumentType.values.any((type) => type.value == document.type)) {
      throw ArgumentError('Loại tài liệu không hợp lệ.');
    }
    final hasFile = document.filePath?.trim().isNotEmpty ?? false;
    final url = document.externalUrl?.trim();
    final hasUrl = url != null && Uri.tryParse(url)?.hasScheme == true;
    if (!hasFile && !hasUrl) {
      throw ArgumentError('Tài liệu cần có đường dẫn tệp hoặc URL hợp lệ.');
    }
  }
}