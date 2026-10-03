class DocumentSearchQuery {
  final String? keyword;
  final String? categoryId;
  final String? type;
  final List<String> tagIds;
  final DateTime? from;
  final DateTime? to;

  DocumentSearchQuery({
    this.keyword,
    this.categoryId,
    this.type,
    this.tagIds = const [],
    this.from,
    this.to,
  });
}

