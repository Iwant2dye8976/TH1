import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/search/search_query.dart';
import '../../../documents/domain/entities/document.dart';
import '../../../documents/presentation/controllers/document_controller.dart';
import '../../../documents/presentation/widgets/document_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.controller});

  final DocumentController controller;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String _selectedType = 'all';
  DateTimeRange? _dateRange;
  bool _hasSearched = false;

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: _dateRange,
    );
    if (selected == null || !mounted) return;
    setState(() => _dateRange = selected);
    _performSearch();
  }

  void _performSearch([String? _]) {
    final keyword = _searchController.text.trim();
    final subject = _subjectController.text.trim();
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    _hasSearched = keyword.isNotEmpty ||
        subject.isNotEmpty ||
        tags.isNotEmpty ||
        _selectedType != 'all' ||
        _dateRange != null;
    widget.controller.search(
      DocumentSearchQuery(
        keyword: keyword,
        categoryId: subject.isEmpty ? null : subject,
        type: _selectedType == 'all' ? null : _selectedType,
        tagIds: tags,
        from: _dateRange == null
            ? null
            : DateTime(
                _dateRange!.start.year,
                _dateRange!.start.month,
                _dateRange!.start.day,
              ),
        to: _dateRange == null
            ? null
            : DateTime(
                _dateRange!.end.year,
                _dateRange!.end.month,
                _dateRange!.end.day,
                23,
                59,
                59,
                999,
                999,
              ),
      ),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _subjectController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm tài liệu')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _performSearch,
                  decoration: InputDecoration(
                    hintText: 'Tiêu đề, nội dung, môn học, tác giả, tag',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Xóa bộ lọc',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        _subjectController.clear();
                        _tagsController.clear();
                        setState(() {
                          _selectedType = 'all';
                          _dateRange = null;
                        });
                        _performSearch();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _subjectController,
                        onChanged: _performSearch,
                        decoration: const InputDecoration(
                          labelText: 'Môn học / danh mục',
                          prefixIcon: Icon(Icons.class_outlined),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _tagsController,
                        onChanged: _performSearch,
                        decoration: const InputDecoration(
                          labelText: 'Tags, phân cách bằng dấu phẩy',
                          prefixIcon: Icon(Icons.sell_outlined),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 250,
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
                          _performSearch();
                        },
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _dateRange == null
                            ? 'Khoảng ngày'
                            : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                      ),
                    ),
                    if (_dateRange != null)
                      IconButton(
                        tooltip: 'Xóa khoảng ngày',
                        onPressed: () {
                          setState(() => _dateRange = null);
                          _performSearch();
                        },
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                if (!_hasSearched)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.manage_search, size: 40, color: AppColors.mutedInk),
                          SizedBox(height: 12),
                          Text('Nhập từ khóa hoặc chọn bộ lọc để bắt đầu.'),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: AnimatedBuilder(
                      animation: widget.controller,
                      builder: (context, _) {
                        final results = widget.controller.searchResults;
                        if (results.isEmpty) {
                          return const Center(
                            child: Text('Không tìm thấy tài liệu phù hợp.'),
                          );
                        }
                        return ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final document = results[index];
                            return DocumentCard(
                              document: document,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.document(document.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
