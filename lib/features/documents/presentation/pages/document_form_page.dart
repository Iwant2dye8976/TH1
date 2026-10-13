import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../domain/entities/document.dart';
import '../controllers/document_controller.dart';

class DocumentFormPage extends StatefulWidget {
  const DocumentFormPage({super.key, required this.controller, this.document});

  final DocumentController controller;
  final Document? document;

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _authorController;
  late TextEditingController _subjectController;
  late TextEditingController _fileController;
  late TextEditingController _urlController;
  late TextEditingController _tagsController;
  late String _selectedType;
  PlatformFile? _selectedFile;
  bool _isSaving = false;

  bool get isEditing => widget.document != null;

  String get _selectedFileSizeLabel {
    final size = _selectedFile?.lengthSync();
    if (size == null) return 'Dung lượng sẽ được kiểm tra khi tải lên.';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.document?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.document?.description ?? '',
    );
    _authorController = TextEditingController(
      text: widget.document?.author ?? '',
    );
    _subjectController = TextEditingController(
      text: widget.document?.subjectId ?? '',
    );
    _fileController = TextEditingController(
      text: widget.document?.filePath ?? '',
    );
    _urlController = TextEditingController(
      text: widget.document?.externalUrl ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.document?.tags.join(', ') ?? '',
    );
    _selectedType = DocumentType.fromValue(widget.document?.type ?? 'lecture')
        .value;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _subjectController.dispose();
    _fileController.dispose();
    _urlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveDocument() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    setState(() => _isSaving = true);
    try {
      final selectedFileBytes = await _selectedFile?.readAsBytes();
      final document = widget.document;
      if (document == null) {
        await widget.controller.create(
          title: _titleController.text,
          type: _selectedType,
          description: _descriptionController.text,
          subject: _subjectController.text,
          author: _authorController.text,
          filePath: _fileController.text,
          externalUrl: _urlController.text,
          uploadFileName: _selectedFile?.name,
          uploadFileBytes: selectedFileBytes,
          tags: tags,
        );
      } else {
        await widget.controller.update(
          original: document,
          title: _titleController.text,
          type: _selectedType,
          description: _descriptionController.text,
          subject: _subjectController.text,
          author: _authorController.text,
          filePath: _fileController.text,
          externalUrl: _urlController.text,
          uploadFileName: _selectedFile?.name,
          uploadFileBytes: selectedFileBytes,
          tags: tags,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(UserErrorMessage.from(error)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Chọn tệp tài liệu',
        type: FileType.any,
      );
      if (!mounted || file == null) return;
      setState(() {
        _selectedFile = file;
        _fileController.text = file.name;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Không thể chọn tệp: ${UserErrorMessage.from(error)}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa tài liệu' : 'Thêm tài liệu'),
        actions: [
          IconButton(
            tooltip: 'Lưu tài liệu',
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveDocument,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: !isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Tiêu đề *'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tiêu đề.'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Loại tài liệu'),
                  items: DocumentType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type.value,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Môn học / danh mục',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  validator: (value) => value != null && value.trim().isEmpty
                      ? 'Vui lòng nhập môn học hoặc danh mục.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Tác giả',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _fileController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Tệp đính kèm',
                    hintText: 'Chọn tệp để tải lên Supabase',
                    prefixIcon: Icon(Icons.attach_file),
                    suffixIcon: IconButton(
                      tooltip: 'Chọn tệp',
                      onPressed: _isSaving ? null : _pickFile,
                      icon: Icon(Icons.folder_open),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedFile != null
                      ? 'Tệp sẽ được tải lên Supabase khi lưu ($_selectedFileSizeLabel).'
                      : widget.document?.storagePath != null
                      ? 'Tệp hiện có được giữ nguyên nếu không chọn tệp mới.'
                      : 'Tối đa 50 MB cho mỗi tệp.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL tài liệu (không bắt buộc)',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (value) {
                    final url = value?.trim() ?? '';
                    if (url.isNotEmpty &&
                        Uri.tryParse(url)?.hasScheme != true) {
                      return 'URL cần có giao thức, ví dụ https://.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    hintText: 'đại số, ôn thi, tuần 1',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  validator: (value) =>
                      value != null &&
                          value.split(',').any((tag) => tag.trim().isEmpty)
                      ? 'Các thẻ không được để trống.'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
