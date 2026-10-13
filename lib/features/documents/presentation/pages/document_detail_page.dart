import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_permission.dart';
import '../controllers/document_controller.dart';
import '../widgets/share_document_dialog.dart';

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
        content: const Text(
          'Bạn có chắc chắn muốn xóa tài liệu này không? Hành động này sẽ xóa dữ liệu trên Supabase và file liên kết.',
        ),
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
    try {
      await controller.delete(document.id, storagePath: document.storagePath);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Xóa thất bại: ${UserErrorMessage.from(e)}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _openShareDialog(BuildContext context, Document doc) {
    showDialog(
      context: context,
      builder: (context) =>
          ShareDocumentDialog(document: doc, controller: controller),
    );
  }

  Future<void> _openFile(BuildContext context, Document document) async {
    try {
      if (document.storagePath != null) {
        final signedUrl = await controller.getFileDownloadUrl(
          document.storagePath!,
        );
        final opened = await launchUrl(
          Uri.parse(signedUrl),
          mode: LaunchMode.externalApplication,
        );
        if (opened || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Không thể mở liên kết tải tệp.'),
          ),
        );
        return;
      }
      final path = document.filePath;
      if (path == null || path.isEmpty) return;
      final result = await OpenFilex.open(path);
      if (!context.mounted || result.type == ResultType.done) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở tệp: ${result.message}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Không thể mở tệp: ${UserErrorMessage.from(error)}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentDocument =
            controller.documentById(document.id) ?? document;
        final role = currentDocument.currentUserRole ?? PermissionRole.owner;

        return Scaffold(
          appBar: AppBar(
            title: Text(currentDocument.title),
            actions: [
              // Nút chia sẻ: CHỈ hiển thị nếu là Owner (theo RLS policy)
              if (currentDocument.canShare)
                IconButton(
                  tooltip: 'Chia sẻ tài liệu',
                  icon: const Icon(Icons.share),
                  onPressed: () => _openShareDialog(context, currentDocument),
                ),
              // Nút sửa: Hiển thị nếu là Owner hoặc Editor
              if (currentDocument.canEdit)
                IconButton(
                  tooltip: 'Sửa tài liệu',
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.editDocument(currentDocument.id),
                  ),
                ),
              // Nút xóa: CHỈ hiển thị nếu là Owner
              if (currentDocument.canDelete)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DocumentType.fromValue(currentDocument.type).label
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.green,
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _RoleBadge(role: role),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentDocument.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 18,
                    runSpacing: 10,
                    children: [
                      if (currentDocument.subjectId != null)
                        _Metadata(
                          icon: Icons.class_outlined,
                          label: currentDocument.subjectId!,
                        ),
                      if (currentDocument.author != null)
                        _Metadata(
                          icon: Icons.person_outline,
                          label: currentDocument.author!,
                        ),
                      if (currentDocument.ownerEmail != null)
                        _Metadata(
                          icon: Icons.verified_user_outlined,
                          label: 'Chủ sở hữu: ${currentDocument.ownerEmail}',
                        ),
                      _Metadata(
                        icon: Icons.calendar_today_outlined,
                        label: _formatDate(currentDocument.updatedAt),
                      ),
                    ],
                  ),
                  const Divider(height: 36),
                  if (currentDocument.description?.isNotEmpty ?? false) ...[
                    Text(
                      'Mô tả',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(currentDocument.description!),
                    const SizedBox(height: 22),
                  ],
                  if (currentDocument.tags.isNotEmpty) ...[
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentDocument.tags
                          .map((tag) => Chip(label: Text(tag)))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (currentDocument.storagePath != null ||
                      currentDocument.filePath != null)
                    Card(
                      elevation: 0,
                      color: Colors.blue.shade50.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.blue.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tệp lưu trữ (Supabase Storage)',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (currentDocument.filePath != null)
                              Text('Tên tệp: ${currentDocument.filePath}'),
                            if (currentDocument.storagePath != null)
                              Text(
                                'Đường dẫn Storage: ${currentDocument.storagePath}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            if (currentDocument.fileSize != null)
                              Text(
                                'Kích thước: ${(currentDocument.fileSize! / 1024).toStringAsFixed(1)} KB',
                                style: const TextStyle(fontSize: 12),
                              ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _openFile(context, currentDocument),
                              icon: const Icon(Icons.download),
                              label: const Text('Mở / Tải tệp'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (currentDocument.externalUrl != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link, color: AppColors.green),
                      title: const Text('URL liên quan'),
                      subtitle: SelectableText(currentDocument.externalUrl!),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final PermissionRole role;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (role) {
      case PermissionRole.owner:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1976D2);
        icon = Icons.star;
        break;
      case PermissionRole.editor:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFF57C00);
        icon = Icons.edit;
        break;
      case PermissionRole.viewer:
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF616161);
        icon = Icons.visibility;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: fg),
      label: Text(
        role.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
      backgroundColor: bg,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
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
