class Document {
  final String id;
  final String title;
  final String? description;
  final String type;
  final String? subjectId;
  final String? author;
  final String? filePath;
  final String? externalUrl;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.subjectId,
    this.author,
    this.filePath,
    this.externalUrl,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
}

enum DocumentType {
  lecture('lecture', 'Bài giảng'),
  assignment('assignment', 'Bài tập'),
  reference('reference', 'Tài liệu tham khảo'),
  exam('exam', 'Đề thi'),
  note('note', 'Ghi chú'),
  other('other', 'Khác');

  const DocumentType(this.value, this.label);

  final String value;
  final String label;

  static DocumentType fromValue(String value) => DocumentType.values
      .firstWhere((type) => type.value == value, orElse: () => other);
}

