import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../models/project_stage.dart';
import '../../services/projects_service.dart';
import '../../services/video_service.dart';
import '../home/dashboard_screen.dart';
import 'widgets/skills_input_widget.dart';
import 'widgets/video_picker_widget.dart';
import '../../widgets/common/loading_button.dart';
import '../../widgets/common/upload_progress.dart';
import '../../utils/layout_constants.dart';
import '../../theme/app_colors.dart';

class CreateProjectScreen extends StatefulWidget {
  /// Optional pre-fill values when launching from a discussion thread.
  final String? initialTitle;
  final String? initialDescription;
  final String? sourceDiscussionId;

  const CreateProjectScreen({
    super.key,
    this.initialTitle,
    this.initialDescription,
    this.sourceDiscussionId,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  // Phase 3 — structured fields
  final _problemController = TextEditingController();
  final _solutionController = TextEditingController();
  final Map<String, String> _impactMetrics = {};
  List<String> _selectedSkills = [];
  ProjectStage _selectedStage = ProjectStage.ideation;
  
  html.File? _videoFile;
  String? _videoBase64;
  String? _thumbnailBase64;
  
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _problemController.dispose();
    _solutionController.dispose();
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
        stage: _selectedStage,
        problemStatement: _problemController.text.trim().isEmpty
            ? null
            : _problemController.text.trim(),
        solutionApproach: _solutionController.text.trim().isEmpty
            ? null
            : _solutionController.text.trim(),
        impactMetrics: _impactMetrics.isEmpty
            ? null
            : Map<String, dynamic>.from(_impactMetrics),
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
                backgroundColor: AppColors.rebellionOrange,
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
            backgroundColor: AppColors.forestGreen,
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
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sourceDiscussionId != null
            ? 'Turn into a Project'
            : 'Create Project'),
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
                // Source discussion banner
                if (widget.sourceDiscussionId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.forum_outlined,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Pre-filled from your discussion. Review and refine before publishing.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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

                // Phase 3 — Problem Statement field
                TextFormField(
                  controller: _problemController,
                  decoration: InputDecoration(
                    labelText: 'Problem Statement (optional)',
                    hintText: 'What systemic problem does this project address?',
                    prefixIcon: const Icon(Icons.warning_amber_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
                const SizedBox(height: 16),

                // Phase 3 — Solution Approach field
                TextFormField(
                  controller: _solutionController,
                  decoration: InputDecoration(
                    labelText: 'Solution Approach (optional)',
                    hintText: 'How does this project solve the problem?',
                    prefixIcon: const Icon(Icons.lightbulb_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  maxLength: 500,
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

                // Stage selection
                const Text(
                  'Project Stage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ProjectStage.values.map((stage) {
                    final isSelected = _selectedStage == stage;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(stage.emoji),
                          const SizedBox(width: 4),
                          Text(stage.displayName),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStage = stage;
                            // Auto-suggest first 3 skills based on stage if none selected
                            if (_selectedSkills.isEmpty) {
                              _selectedSkills =
                                  stage.suggestedSkills.take(3).toList();
                            }
                          });
                        }
                      },
                      selectedColor: stage.color.withOpacity(0.2),
                      checkmarkColor: stage.color,
                      labelStyle: TextStyle(
                        color: isSelected ? stage.color : AppColors.grey500,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? stage.color : AppColors.grey300,
                        width: isSelected ? 2 : 1,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedStage.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedStage.color.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _selectedStage.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Suggested skills for ${_selectedStage.displayName} stage:',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedStage.suggestedSkills.map((skill) {
                    final isSelected = _selectedSkills.contains(skill);
                    return FilterChip(
                      label: Text(skill),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSkills.add(skill);
                          } else {
                            _selectedSkills.remove(skill);
                          }
                        });
                      },
                      selectedColor: _selectedStage.color.withOpacity(0.2),
                      checkmarkColor: _selectedStage.color,
                      side: BorderSide(
                        color: isSelected
                            ? _selectedStage.color
                            : AppColors.grey300,
                      ),
                    );
                  }).toList(),
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
                    label: widget.sourceDiscussionId != null
                        ? 'Launch Project'
                        : 'Create Project',
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
