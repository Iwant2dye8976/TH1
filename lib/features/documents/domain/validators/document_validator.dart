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
    // if (document.tags.any((tag) => tag.trim().isEmpty)) {
    //   throw ArgumentError('Các thẻ tài liệu không được để trống.');
    // }
    // if (document.subjectId == null || document.subjectId!.trim().isEmpty) {
    //   throw ArgumentError('Môn học không được để trống nếu được cung cấp.');
    // }
    final url = document.externalUrl?.trim();
    if (url != null &&
        url.isNotEmpty &&
        Uri.tryParse(url)?.hasScheme != true) {
      throw ArgumentError('URL tài liệu cần có giao thức hợp lệ.');
    }
  }
}