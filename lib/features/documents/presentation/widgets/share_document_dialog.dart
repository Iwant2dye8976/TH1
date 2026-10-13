import 'package:flutter/material.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_permission.dart';
import '../controllers/document_controller.dart';

class ShareDocumentDialog extends StatefulWidget {
  const ShareDocumentDialog({
    super.key,
    required this.document,
    required this.controller,
  });

  final Document document;
  final DocumentController controller;

  @override
  State<ShareDocumentDialog> createState() => _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends State<ShareDocumentDialog> {
  final _emailController = TextEditingController();
  PermissionRole _selectedRole = PermissionRole.viewer;
  bool _isLoading = false;
  List<DocumentPermission> _permissions = [];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.controller.fetchPermissions(widget.document.id);
      if (mounted) {
        setState(() {
          _permissions = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Lỗi tải danh sách quyền: ${UserErrorMessage.from(e)}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _share() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập địa chỉ email người nhận.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.controller.share(
        documentId: widget.document.id,
        targetEmail: email,
        role: _selectedRole,
      );
      _emailController.clear();
      await _loadPermissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã chia sẻ tài liệu cho $email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Chia sẻ thất bại: ${UserErrorMessage.from(e)}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revoke(String permissionId, String email) async {
    setState(() => _isLoading = true);
    try {
      await widget.controller.revoke(
        documentId: widget.document.id,
        permissionId: permissionId,
      );
      await _loadPermissions();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã thu hồi quyền của $email')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Thu hồi thất bại: ${UserErrorMessage.from(e)}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.share, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chia sẻ: ${widget.document.title}',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Thêm người nhận:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Nhập email (vd: user@example.com)',
                        isDense: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<PermissionRole>(
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(
                        value: PermissionRole.viewer,
                        child: Text('Xem'),
                      ),
                      DropdownMenuItem(
                        value: PermissionRole.editor,
                        child: Text('Sửa'),
                      ),
                    ],
                    onChanged: (role) {
                      if (role != null) setState(() => _selectedRole = role);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _share,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Chia sẻ'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Những người có quyền truy cập:',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Thông tin chủ sở hữu
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(widget.document.ownerEmail ?? 'Chủ sở hữu'),
                subtitle: const Text('Chủ sở hữu tài liệu'),
                trailing: const Chip(
                  label: Text('Owner', style: TextStyle(fontSize: 12)),
                  backgroundColor: Color(0xFFE3F2FD),
                ),
              ),
              const Divider(),
              Expanded(
                child: _isLoading && _permissions.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _permissions.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có người dùng nào được chia sẻ thêm.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _permissions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final perm = _permissions[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor:
                                  perm.role == PermissionRole.editor
                                  ? Colors.orange.shade100
                                  : Colors.grey.shade200,
                              child: Icon(
                                perm.role == PermissionRole.editor
                                    ? Icons.edit
                                    : Icons.visibility,
                                size: 18,
                                color: perm.role == PermissionRole.editor
                                    ? Colors.orange.shade800
                                    : Colors.grey.shade700,
                              ),
                            ),
                            title: Text(perm.userEmail),
                            subtitle: Text(perm.role.label),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              tooltip: 'Thu hồi quyền',
                              onPressed: () => _revoke(perm.id, perm.userEmail),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
