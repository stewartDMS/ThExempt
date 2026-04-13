import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../models/project_stage.dart';
import '../../services/projects_service.dart';
import '../../services/video_service.dart';
import '../home/dashboard_screen.dart';
import 'widgets/skills_input_widget.dart';
import 'widgets/video_picker_widget.dart';
import '../../widgets/common/upload_progress.dart';
import '../../utils/layout_constants.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

// ── Dark surface palette ──────────────────────────────────────────────────────
const _kBg = Color(0xFF14141A);
const _kCardBg = Color(0xFF1C1C1E);
const _kInputFill = Color(0xFF252528);
const _kBorder = Color(0xFF3A3A3C);
const _kTextPrimary = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);
const _kDivider = Color(0xFF2C2C2F);

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

  // Track which optional sections are expanded
  bool _showProblemSolution = false;

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
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      _showError('Please add at least one skill');
      return;
    }

    setState(() => _isLoading = true);

    try {
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Project created, but video upload failed: $e'),
              backgroundColor: AppColors.rebellionOrange,
            ));
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                LayoutConstants.bottomContentPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Source discussion banner
                  if (widget.sourceDiscussionId != null) ...[
                    _buildDiscussionBanner(),
                    const SizedBox(height: 16),
                  ],

                  // ── Section 1: Basic Info ────────────────────────────
                  _SectionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Project Info',
                    subtitle: 'Give your project a compelling identity',
                    child: Column(
                      children: [
                        _darkField(
                          controller: _titleController,
                          label: 'Project Title',
                          hint: 'A bold, memorable name',
                          icon: Icons.title_rounded,
                          maxLength: 100,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            if (v.trim().length < 5) {
                              return 'Title must be at least 5 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _darkField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'What is this project about? Who does it help?',
                          icon: Icons.article_outlined,
                          maxLines: 5,
                          maxLength: 1000,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            if (v.trim().length < 20) {
                              return 'Description must be at least 20 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Section 2: Stage ─────────────────────────────────
                  _SectionCard(
                    icon: Icons.timeline_rounded,
                    title: 'Project Stage',
                    subtitle: 'Where are you in the journey?',
                    child: _buildStageSelector(),
                  ),
                  const SizedBox(height: 14),

                  // ── Section 3: Skills ────────────────────────────────
                  _SectionCard(
                    icon: Icons.code_rounded,
                    title: 'Skills Needed',
                    subtitle: 'What expertise is required to build this?',
                    child: SkillsInputWidget(
                      selectedSkills: _selectedSkills,
                      onSkillsChanged: (skills) =>
                          setState(() => _selectedSkills = skills),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Section 4: Media (video) ─────────────────────────
                  _SectionCard(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Project Media',
                    subtitle: 'Add a video pitch — projects with video get 3× more views',
                    child: VideoPickerWidget(
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
                  ),
                  const SizedBox(height: 14),

                  // ── Section 5: Problem & Solution (expandable) ────────
                  _ExpandableSection(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Problem & Solution',
                    subtitle: 'Optional but recommended for deeper impact',
                    isExpanded: _showProblemSolution,
                    onToggle: () => setState(
                        () => _showProblemSolution = !_showProblemSolution),
                    child: Column(
                      children: [
                        _darkField(
                          controller: _problemController,
                          label: 'Problem Statement',
                          hint: 'What systemic issue does this address?',
                          icon: Icons.warning_amber_outlined,
                          maxLines: 3,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 14),
                        _darkField(
                          controller: _solutionController,
                          label: 'Solution Approach',
                          hint: 'How does this project solve the problem?',
                          icon: Icons.lightbulb_outline,
                          maxLines: 3,
                          maxLength: 500,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Upload progress
                  if (_isLoading && _videoFile != null && _uploadProgress > 0) ...[
                    Center(
                      child: UploadProgress(
                        progress: _uploadProgress,
                        label: 'Uploading video...',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Submit button ────────────────────────────────────
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver AppBar ──────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    final isFromDiscussion = widget.sourceDiscussionId != null;
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      backgroundColor: _kBg,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _kTextPrimary, size: 20),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _createProject,
          child: const Text(
            'Publish',
            style: TextStyle(
              color: AppColors.brightCyan,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0D1B2A),
                AppColors.electricBlue.withOpacity(0.35),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isFromDiscussion
                          ? Icons.forum_rounded
                          : Icons.add_circle_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFromDiscussion
                            ? 'Turn Into a Project'
                            : 'Create Project',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _kTextPrimary,
                        ),
                      ),
                      Text(
                        isFromDiscussion
                            ? 'Review and refine your idea'
                            : 'Share your vision with the community',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Discussion banner ──────────────────────────────────────────────────────

  Widget _buildDiscussionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.electricBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.forum_outlined,
              color: AppColors.brightCyan, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Pre-filled from your discussion — review and refine before publishing.',
              style: TextStyle(
                  fontSize: 13,
                  color: _kTextSecondary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stage selector ─────────────────────────────────────────────────────────

  Widget _buildStageSelector() {
    return Column(
      children: [
        // Stage tiles
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ProjectStage.values.map((stage) {
            final isSelected = _selectedStage == stage;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStage = stage;
                  if (_selectedSkills.isEmpty) {
                    _selectedSkills =
                        stage.suggestedSkills.take(3).toList();
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? stage.color.withOpacity(0.18)
                      : _kInputFill,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? stage.color.withOpacity(0.6)
                        : _kBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(stage.emoji,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      stage.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? stage.color
                            : _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Selected stage description
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _selectedStage.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: _selectedStage.color.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              Text(_selectedStage.emoji,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                _selectedStage.description,
                style: TextStyle(
                  fontSize: 12,
                  color: _selectedStage.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Suggested skills for this stage
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Suggested for ${_selectedStage.displayName}:',
            style: const TextStyle(
                fontSize: 12,
                color: _kTextSecondary,
                fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _selectedStage.suggestedSkills.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSkills.remove(skill);
                  } else {
                    _selectedSkills.add(skill);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _selectedStage.color.withOpacity(0.18)
                      : _kInputFill,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? _selectedStage.color.withOpacity(0.6)
                        : _kBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(Icons.check,
                          size: 12,
                          color: _selectedStage.color),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      skill,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? _selectedStage.color
                            : _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Submit button ──────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    final label = widget.sourceDiscussionId != null
        ? 'Launch Project'
        : 'Create Project';
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _isLoading
            ? LinearGradient(
                colors: [
                  AppColors.electricBlue.withOpacity(0.5),
                  AppColors.brightCyan.withOpacity(0.5),
                ],
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: AppColors.electricBlue.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createProject,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rocket_launch_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Shared dark text field ─────────────────────────────────────────────────

  Widget _darkField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(color: _kTextPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _kTextSecondary, size: 20),
        labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 14),
        hintStyle:
            TextStyle(color: _kTextSecondary.withOpacity(0.5), fontSize: 13),
        counterStyle:
            const TextStyle(color: _kTextSecondary, fontSize: 11),
        filled: true,
        fillColor: _kInputFill,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: maxLines > 1 ? 14 : 0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(
              color: AppColors.brightCyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: _kBorder.withOpacity(0.6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon,
                      color: AppColors.brightCyan, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: _kTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kDivider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Expandable section card ───────────────────────────────────────────────────

class _ExpandableSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandableSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: _kBorder.withOpacity(0.6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (tappable)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppSpacing.radiusLg),
              bottom: Radius.circular(
                  isExpanded ? 0 : AppSpacing.radiusLg),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.warmAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon,
                        color: AppColors.warmAmber, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: _kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _kTextSecondary, size: 22),
                  ),
                ],
              ),
            ),
          ),
          // Body
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    children: [
                      const Divider(height: 1, color: _kDivider),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: child,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
