import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/search/search_query.dart';
import '../../domain/entities/document.dart';
import '../controllers/document_controller.dart';
import '../widgets/document_card.dart';

class DocumentListPage extends StatefulWidget {
  const DocumentListPage({super.key, required this.controller});

  final DocumentController controller;

  @override
  State<DocumentListPage> createState() => _DocumentListPageState();
}

class _DocumentListPageState extends State<DocumentListPage> {
  String _selectedType = 'all';
  String _keyword = '';

  void _applyFilters([String? keyword]) {
    if (keyword != null) _keyword = keyword;
    widget.controller.search(
      DocumentSearchQuery(
        keyword: _keyword,
        type: _selectedType == 'all' ? null : _selectedType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư viện học tập'),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm nâng cao',
            icon: const Icon(Icons.manage_search),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kho tài liệu',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.controller.documents.length} tài liệu đã lưu',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    onChanged: _applyFilters,
                    decoration: const InputDecoration(
                      hintText: 'Tìm tiêu đề, môn học, tác giả hoặc tag',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Loại tài liệu',
                        prefixIcon: Icon(Icons.tune),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('Tất cả loại'),
                        ),
                        ...DocumentType.values.map(
                          (type) => DropdownMenuItem(
                            value: type.value,
                            child: Text(type.label),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedType = value);
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.controller.errorMessage != null)
                    Expanded(
                      child: _MessageState(
                        icon: Icons.error_outline,
                        message:
                            'Không thể tải dữ liệu: ${widget.controller.errorMessage}',
                      ),
                    )
                  else if (widget.controller.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (widget.controller.searchResults.isEmpty)
                    Expanded(
                      child: _MessageState(
                        icon: widget.controller.documents.isEmpty
                            ? Icons.auto_stories_outlined
                            : Icons.search_off,
                        message: widget.controller.documents.isEmpty
                            ? 'Chưa có tài liệu. Thêm tài liệu đầu tiên để bắt đầu thư viện.'
                            : 'Không tìm thấy tài liệu phù hợp.',
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: widget.controller.searchResults.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final document =
                              widget.controller.searchResults[index];
                          return DocumentCard(
                            document: document,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.document(document.id),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Thêm tài liệu',
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.createDocument),
        icon: const Icon(Icons.add),
        label: const Text('Thêm tài liệu'),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: AppColors.mutedInk),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
}
