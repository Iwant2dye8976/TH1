import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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

  bool get isEditing => widget.document != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document?.title ?? '');
    _descriptionController = TextEditingController(text: widget.document?.description ?? '');
    _authorController = TextEditingController(text: widget.document?.author ?? '');
    _subjectController = TextEditingController(text: widget.document?.subjectId ?? '');
    _fileController = TextEditingController(text: widget.document?.filePath ?? '');
    _urlController = TextEditingController(text: widget.document?.externalUrl ?? '');
    _tagsController = TextEditingController(text: widget.document?.tags.join(', ') ?? '');
    _selectedType = DocumentType.fromValue(widget.document?.type ?? 'lecture').value;
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
    if (!_formKey.currentState!.validate()) return;
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    try {
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
          tags: tags,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('ArgumentError: ', ''))),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Chọn tệp tài liệu',
        type: FileType.any,
      );
      if (!mounted || file == null) return;
      final path = file.path;
      if (path == null || path.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy đường dẫn của tệp đã chọn.')),
        );
        return;
      }
      _fileController.text = path;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn tệp: $error')),
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
            icon: const Icon(Icons.check),
            onPressed: () => _saveDocument(),
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
                  decoration: InputDecoration(
                    labelText: 'Đường dẫn tệp',
                    hintText: 'Ví dụ: /Documents/lecture.pdf',
                    prefixIcon: Icon(Icons.attach_file),
                    suffixIcon: IconButton(
                      tooltip: 'Chọn tệp',
                      onPressed: _pickFile,
                      icon: Icon(Icons.folder_open),
                    ),
                  ),
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
                    if (url.isNotEmpty && Uri.tryParse(url)?.hasScheme != true) {
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
