import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/document.dart';

class DocumentCard extends StatelessWidget {
	const DocumentCard({super.key, required this.document, required this.onTap});

	final Document document;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final type = DocumentType.fromValue(document.type);
		return Card(
			child: InkWell(
				borderRadius: BorderRadius.circular(8),
				onTap: onTap,
				child: Padding(
					padding: const EdgeInsets.all(16),
					child: Row(
						children: [
							Container(
								width: 44,
								height: 44,
								decoration: BoxDecoration(
									color: AppColors.greenTint,
									borderRadius: BorderRadius.circular(8),
								),
								child: Icon(_iconFor(type), color: AppColors.green),
							),
							const SizedBox(width: 14),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											document.title,
											maxLines: 2,
											overflow: TextOverflow.ellipsis,
											style: Theme.of(context).textTheme.titleMedium,
										),
										const SizedBox(height: 5),
										Text(
											[
												type.label,
												?document.subjectId,
												?document.author,
											].join('  ·  '),
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
											style: Theme.of(context).textTheme.bodySmall,
										),
										if (document.tags.isNotEmpty) ...[
											const SizedBox(height: 9),
											Wrap(
												spacing: 6,
												runSpacing: 6,
												children: document.tags.take(4).map((tag) {
													return DecoratedBox(
														decoration: BoxDecoration(
															color: AppColors.canvas,
															borderRadius: BorderRadius.circular(4),
														),
														child: Padding(
															padding: const EdgeInsets.symmetric(
																horizontal: 8,
																vertical: 4,
															),
															child: Text(
																tag,
																style: Theme.of(context).textTheme.bodySmall,
															),
														),
													);
												}).toList(),
											),
										],
									],
								),
							),
							const SizedBox(width: 8),
							const Icon(Icons.chevron_right, color: AppColors.mutedInk),
						],
					),
				),
			),
		);
	}

	IconData _iconFor(DocumentType type) => switch (type) {
		DocumentType.lecture => Icons.menu_book_outlined,
		DocumentType.assignment => Icons.assignment_outlined,
		DocumentType.reference => Icons.library_books_outlined,
		DocumentType.exam => Icons.fact_check_outlined,
		DocumentType.note => Icons.sticky_note_2_outlined,
		DocumentType.other => Icons.description_outlined,
	};
}
