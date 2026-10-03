import '../../domain/entities/document.dart';

class DocumentModel {
	const DocumentModel(this.document);

	final Document document;

	factory DocumentModel.fromJson(Map<String, dynamic> json) {
		return DocumentModel(
			Document(
				id: json['id'] as String,
				title: json['title'] as String,
				description: json['description'] as String?,
				type: json['type'] as String? ?? 'other',
				subjectId: json['subjectId'] as String?,
				author: json['author'] as String?,
				filePath: json['filePath'] as String?,
				externalUrl: json['externalUrl'] as String?,
				tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
				createdAt: DateTime.parse(json['createdAt'] as String),
				updatedAt: DateTime.parse(json['updatedAt'] as String),
			),
		);
	}

	Map<String, Object?> toJson() => {
		'id': document.id,
		'title': document.title,
		'description': document.description,
		'type': document.type,
		'subjectId': document.subjectId,
		'author': document.author,
		'filePath': document.filePath,
		'externalUrl': document.externalUrl,
		'tags': document.tags,
		'createdAt': document.createdAt.toIso8601String(),
		'updatedAt': document.updatedAt.toIso8601String(),
	};
}
