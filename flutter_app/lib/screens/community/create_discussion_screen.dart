import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/discussion_model.dart';
import '../../services/discussions_service.dart';
import '../../theme/app_colors.dart';
import '../../services/media_upload_service.dart';

// ── Dark palette ──────────────────────────────────────────────────────────────
const _kBg            = Color(0xFF14141A);
const _kCardBg        = Color(0xFF1C1C1E);
const _kInputFill     = Color(0xFF252528);
const _kBorder        = Color(0xFF3A3A3C);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

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
        backgroundColor: AppColors.rebellionOrange,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Media (optional)',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: _kTextPrimary)),
        const SizedBox(height: 10),

        // Upload buttons
        Row(
          children: [
            _DarkOutlinedButton(
              icon: Icons.image_outlined,
              label: 'Add Photos',
              onPressed: _isSubmitting ? null : _pickImages,
            ),
            const SizedBox(width: 10),
            _DarkOutlinedButton(
              icon: Icons.videocam_outlined,
              label: 'Add Video',
              onPressed: _isSubmitting ? null : _pickVideo,
            ),
          ],
        ),

        // Selected file previews
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Selected (${_selectedFiles.length}/${MediaUploadService.maxFiles})',
            style: const TextStyle(fontSize: 13, color: _kTextSecondary),
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
                      color: _kInputFill,
                      border: Border.all(color: _kBorder),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isVideo
                          ? Container(
                              color: Colors.black,
                              child: const Center(
                                child: Icon(Icons.play_circle_outline,
                                    size: 40, color: AppColors.brightCyan),
                              ),
                            )
                          : kIsWeb
                              ? FutureBuilder<Uint8List>(
                                  future: file.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                                Icons.broken_image_outlined,
                                                color: _kTextSecondary),
                                      );
                                    }
                                    return const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.brightCyan),
                                      ),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(file.path),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image_outlined,
                                      color: _kTextSecondary),
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
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  // Video badge
                  if (isVideo)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('VIDEO',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
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
              backgroundColor: _kInputFill,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.brightCyan),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Uploading media… ${(_uploadProgress * 100).toInt()}%',
            style: const TextStyle(fontSize: 12, color: _kTextSecondary),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kBorder),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
          const BorderSide(color: AppColors.brightCyan, width: 1.5),
    );
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: _kInputFill,
      labelStyle: const TextStyle(color: _kTextSecondary),
      hintStyle: const TextStyle(color: _kTextSecondary),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: focusedBorder,
      counterStyle: const TextStyle(color: _kTextSecondary),
    );

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _kTextPrimary),
        title: const Text('New Discussion',
            style: TextStyle(
                color: _kTextPrimary, fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.brightCyan))
                  : const Text('Post',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.brightCyan)),
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
            const Text('Category',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: _kTextPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: DiscussionCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat.value;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.electricBlue.withOpacity(0.2)
                          : _kCardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brightCyan.withOpacity(0.7)
                            : _kBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? AppColors.brightCyan
                            : _kTextSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
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
              style: const TextStyle(color: _kTextPrimary),
              decoration: inputDecoration.copyWith(
                labelText: 'Title',
                hintText: 'What do you want to discuss?',
              ),
              maxLength: 200,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                if (v.trim().length < 5)
                  return 'Title must be at least 5 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Content
            TextFormField(
              controller: _contentController,
              style: const TextStyle(color: _kTextPrimary),
              decoration: inputDecoration.copyWith(
                labelText: 'Content',
                hintText: 'Share your thoughts, questions, or ideas...',
                alignLabelWithHint: true,
              ),
              minLines: 5,
              maxLines: 15,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Content is required';
                if (v.trim().length < 10)
                  return 'Content must be at least 10 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Tags
            const Text('Tags (optional)',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: _kTextPrimary)),
            const SizedBox(height: 8),
            if (_tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _tags
                      .map((tag) => Chip(
                            label: Text('#$tag',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.brightCyan)),
                            deleteIcon: const Icon(Icons.close,
                                size: 14, color: _kTextSecondary),
                            onDeleted: () =>
                                setState(() => _tags.remove(tag)),
                            backgroundColor:
                                AppColors.electricBlue.withOpacity(0.12),
                            side: BorderSide(
                                color:
                                    AppColors.electricBlue.withOpacity(0.3)),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2),
                          ))
                      .toList(),
                ),
              ),
            if (_tags.length < 5)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      style: const TextStyle(color: _kTextPrimary),
                      decoration: inputDecoration.copyWith(
                        hintText: 'Add a tag...',
                        prefixText: '#',
                        prefixStyle:
                            const TextStyle(color: _kTextSecondary),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.brightCyan),
                    onPressed: _addTag,
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

// ── Dark outlined button helper ──────────────────────────────────────────────

class _DarkOutlinedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _DarkOutlinedButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.brightCyan),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.brightCyan,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
