import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../services/projects_service.dart';
import '../../services/video_service.dart';
import 'widgets/skills_input_widget.dart';
import 'widgets/video_picker_widget.dart';

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
        try {
          await VideoService.uploadVideo(
            projectId: project.id,
            base64Video: _videoBase64!,
            fileName: _videoFile!.name,
            thumbnailBase64: _thumbnailBase64!,
          );
        } catch (e) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedSkills = [];
          _videoFile = null;
          _videoBase64 = null;
          _thumbnailBase64 = null;
        });

        // Navigate to home feed (index 0)
        // The parent DashboardScreen will handle this
        Navigator.of(context).pop();
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
          padding: const EdgeInsets.all(24),
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

                // Submit button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createProject,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Project',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
