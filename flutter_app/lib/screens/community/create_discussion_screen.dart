import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../services/discussions_service.dart';

class CreateDiscussionScreen extends StatefulWidget {
  final String? initialCategory;

  const CreateDiscussionScreen({super.key, this.initialCategory});

  @override
  State<CreateDiscussionScreen> createState() => _CreateDiscussionScreenState();
}

class _CreateDiscussionScreenState extends State<CreateDiscussionScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedCategory;
  final List<String> _tags = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? DiscussionCategory.values.first.value;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim().replaceAll('#', '');
    if (tag.isEmpty || _tags.contains(tag) || _tags.length >= 5) return;
    setState(() => _tags.add(tag));
    _tagController.clear();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;
    setState(() => _isSubmitting = true);

    try {
      await DiscussionsService.createDiscussion(
        category: _selectedCategory!,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tags.isEmpty ? null : _tags,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discussion created!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Discussion'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category selector
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: DiscussionCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'What do you want to discuss?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLength: 200,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                if (v.trim().length < 5) return 'Title must be at least 5 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Content
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                hintText: 'Share your thoughts, questions, or ideas...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                alignLabelWithHint: true,
              ),
              minLines: 5,
              maxLines: 15,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Content is required';
                if (v.trim().length < 10) return 'Content must be at least 10 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Tags
            const Text('Tags (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _tags.map((tag) => Chip(
                    label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                  )).toList(),
                ),
              ),
            if (_tags.length < 5)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Add a tag...',
                        prefixText: '#',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addTag,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
