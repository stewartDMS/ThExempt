import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/discussion_model.dart';
import '../../services/discussions_service.dart';
import '../../services/media_upload_service.dart';

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

  // ── Media state ────────────────────────────────────────────────────────────
  final List<XFile> _selectedFiles = [];
  double _uploadProgress = 0.0;

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

  // ── Media picking ──────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    final remaining = MediaUploadService.maxFiles - _selectedFiles.length;
    if (remaining <= 0) {
      _showMaxFilesSnackBar();
      return;
    }
    try {
      final files = await MediaUploadService.pickImages(limit: remaining);
      if (files.isNotEmpty) setState(() => _selectedFiles.addAll(files));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_selectedFiles.length >= MediaUploadService.maxFiles) {
      _showMaxFilesSnackBar();
      return;
    }
    try {
      final file = await MediaUploadService.pickVideo();
      if (file != null) setState(() => _selectedFiles.add(file));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeFile(int index) => setState(() => _selectedFiles.removeAt(index));

  void _showMaxFilesSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maximum ${MediaUploadService.maxFiles} files allowed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ── Submission ─────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;
    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    Discussion? discussion;
    try {
      // 1. Create the discussion first.
      discussion = await DiscussionsService.createDiscussion(
        category: _selectedCategory!,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tags.isEmpty ? null : _tags,
      );

      // 2. Upload any selected media files.
      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        final isVideo = MediaUploadService.isVideoFile(file);

        final result = await MediaUploadService.uploadFile(file, isVideo: isVideo);

        await MediaUploadService.insertMediaRecord(
          discussionId: discussion.id,
          mediaType: isVideo ? 'video' : 'image',
          fileUrl: result.fileUrl,
          fileName: file.name,
          fileSize: result.fileSize,
          displayOrder: i,
        );

        if (mounted) {
          setState(() => _uploadProgress = (i + 1) / _selectedFiles.length);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discussion posted!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // If the discussion was created but media upload failed, delete the
      // discussion so the user doesn't end up with a partially posted item.
      if (discussion != null && _selectedFiles.isNotEmpty) {
        try {
          await DiscussionsService.deleteDiscussion(discussion.id);
        } catch (_) {
          // Best-effort cleanup; ignore secondary errors.
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  // ── Media upload section widget ────────────────────────────────────────────

  Widget _buildMediaUploadSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Media (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),

        // Upload buttons
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _pickImages,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: const Text('Add Photos'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _pickVideo,
              icon: const Icon(Icons.videocam_outlined, size: 18),
              label: const Text('Add Video'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),

        // Selected file previews
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Selected (${_selectedFiles.length}/${MediaUploadService.maxFiles})',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              final isVideo = MediaUploadService.isVideoFile(file);
              return Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isVideo
                          ? Container(
                              color: Colors.black87,
                              child: const Center(
                                child: Icon(Icons.play_circle_outline,
                                    size: 40, color: Colors.white),
                              ),
                            )
                          : Image.file(
                              File(file.path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image_outlined,
                                    color: Colors.grey),
                              ),
                            ),
                    ),
                  ),
                  // Remove button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: _isSubmitting ? null : () => _removeFile(index),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  // Video badge
                  if (isVideo)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('VIDEO',
                            style: TextStyle(color: Colors.white, fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ],

        // Upload progress bar
        if (_isSubmitting && _selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Uploading media… ${(_uploadProgress * 100).toInt()}%',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
    );
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
            const SizedBox(height: 20),
            // Media upload section
            _buildMediaUploadSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
