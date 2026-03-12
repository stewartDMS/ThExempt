import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../services/projects_service.dart';
import '../../services/video_service.dart';
import '../home/dashboard_screen.dart';
import 'widgets/skills_input_widget.dart';
import 'widgets/video_picker_widget.dart';
import '../../widgets/common/loading_button.dart';
import '../../widgets/common/upload_progress.dart';
import '../../utils/layout_constants.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _selectedSkills = [];
  
  html.File? _videoFile;
  String? _videoBase64;
  String? _thumbnailBase64;
  
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSkills.isEmpty) {
      _showError('Please add at least one skill');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create project first
      final project = await ProjectsService.createProject(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        skills: _selectedSkills,
      );

      // Upload video if selected
      if (_videoFile != null && _videoBase64 != null && _thumbnailBase64 != null) {
        setState(() => _uploadProgress = 0.1);
        try {
          await VideoService.uploadVideo(
            projectId: project.id,
            base64Video: _videoBase64!,
            fileName: _videoFile!.name,
            thumbnailBase64: _thumbnailBase64!,
          );
          setState(() => _uploadProgress = 1.0);
        } catch (e) {
          setState(() => _uploadProgress = 0.0);
          // Video upload failed, but project was created
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Project created, but video upload failed: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(initialIndex: 0),
          ),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to create project: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, LayoutConstants.bottomContentPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Project Title',
                    hintText: 'Enter a descriptive title',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.trim().length < 5) {
                      return 'Title must be at least 5 characters';
                    }
                    return null;
                  },
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your project in detail',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.trim().length < 20) {
                      return 'Description must be at least 20 characters';
                    }
                    return null;
                  },
                  maxLines: 5,
                  maxLength: 1000,
                ),
                const SizedBox(height: 16),

                // Skills input
                SkillsInputWidget(
                  selectedSkills: _selectedSkills,
                  onSkillsChanged: (skills) {
                    setState(() => _selectedSkills = skills);
                  },
                ),
                const SizedBox(height: 24),

                // Video upload
                VideoPickerWidget(
                  onVideoSelected: (file, base64Video, thumbnailBase64) {
                    setState(() {
                      _videoFile = file;
                      _videoBase64 = base64Video;
                      _thumbnailBase64 = thumbnailBase64;
                    });
                  },
                  onVideoRemoved: () {
                    setState(() {
                      _videoFile = null;
                      _videoBase64 = null;
                      _thumbnailBase64 = null;
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Upload progress (shown when uploading video)
                if (_isLoading && _videoFile != null && _uploadProgress > 0) ...[
                  Center(
                    child: UploadProgress(
                      progress: _uploadProgress,
                      label: 'Uploading video...',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: LoadingButton(
                    label: 'Create Project',
                    icon: Icons.add_circle_outline,
                    isLoading: _isLoading,
                    onPressed: _createProject,
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
