import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/document.dart';
import '../controllers/document_controller.dart';

class DocumentDetailPage extends StatelessWidget {
  final Document document;
  final DocumentController controller;

  const DocumentDetailPage({
    super.key,
    required this.document,
    required this.controller,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài liệu?'),
        content: const Text('Bạn có chắc chắn muốn xóa tài liệu này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await controller.delete(document.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
        actions: [
          IconButton(
            tooltip: 'Sửa tài liệu',
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.editDocument(document.id),
            ),
          ),
          IconButton(
            tooltip: 'Xóa tài liệu',
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                DocumentType.fromValue(document.type).label.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.green,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(document.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 18),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  if (document.subjectId != null)
                    _Metadata(icon: Icons.class_outlined, label: document.subjectId!),
                  if (document.author != null)
                    _Metadata(icon: Icons.person_outline, label: document.author!),
                  _Metadata(
                    icon: Icons.calendar_today_outlined,
                    label: _formatDate(document.updatedAt),
                  ),
                ],
              ),
              const Divider(height: 36),
              if (document.description?.isNotEmpty ?? false) ...[
                Text('Mô tả', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(document.description!),
                const SizedBox(height: 22),
              ],
              if (document.tags.isNotEmpty) ...[
                Text('Tags', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: document.tags
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(),
                ),
                const SizedBox(height: 18),
              ],
              if (document.filePath != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_file, color: AppColors.green),
                  title: const Text('Tệp liên quan'),
                  subtitle: SelectableText(document.filePath!),
                ),
              if (document.externalUrl != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link, color: AppColors.green),
                  title: const Text('URL liên quan'),
                  subtitle: SelectableText(document.externalUrl!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: AppColors.mutedInk),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
