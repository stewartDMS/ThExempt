import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/categorized_skill_picker.dart';
import '../../widgets/common/loading_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

// ── Dark palette ──────────────────────────────────────────────────────────────
const _kBg            = Color(0xFF14141A);
const _kCardBg        = Color(0xFF1C1C1E);
const _kBorder        = Color(0xFF3A3A3C);
const _kInputFill     = Color(0xFF252528);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

class EditProfileScreen extends StatefulWidget {
  final UserProfile user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _githubController;
  late TextEditingController _linkedinController;
  late TextEditingController _websiteController;

  String _availabilityStatus = 'available';
  List<String> _skills = [];
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _previewAvatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController     = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username ?? '');
    _bioController      = TextEditingController(text: widget.user.bio ?? '');
    _locationController = TextEditingController(text: widget.user.location ?? '');
    _githubController   = TextEditingController(text: widget.user.githubUrl ?? '');
    _linkedinController = TextEditingController(text: widget.user.linkedinUrl ?? '');
    _websiteController  = TextEditingController(text: widget.user.websiteUrl ?? '');
    _availabilityStatus = widget.user.availabilityStatus;
    _skills             = List<String>.from(widget.user.skills);
    _previewAvatarUrl   = widget.user.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes       = await File(file.path!).readAsBytes();
      final base64Image =
          'data:image/${file.extension ?? 'png'};base64,${base64Encode(bytes)}';
      final fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}.${file.extension ?? 'png'}';
      final avatarUrl = await UserService.uploadAvatar(
          base64Image: base64Image, fileName: fileName);
      if (mounted) {
        setState(() {
          _previewAvatarUrl = avatarUrl;
          _isUploadingAvatar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload avatar: $e'),
            backgroundColor: AppColors.deepRed,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updatedUser = await UserService.updateProfile(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : null,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        githubUrl: _githubController.text.trim().isNotEmpty
            ? _githubController.text.trim()
            : null,
        linkedinUrl: _linkedinController.text.trim().isNotEmpty
            ? _linkedinController.text.trim()
            : null,
        websiteUrl: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        availabilityStatus: _availabilityStatus,
        skills: _skills,
        avatarUrl: _previewAvatarUrl,
      );
      if (mounted) Navigator.of(context).pop(updatedUser);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppColors.deepRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kTextSecondary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brightCyan,
                backgroundColor:
                    AppColors.brightCyan.withOpacity(0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      AppSpacing.radiusFull),
                  side: BorderSide(
                    color: AppColors.brightCyan.withOpacity(0.4),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brightCyan),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ──────────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.electricBlue.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.electricBlue.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            AppColors.electricBlue.withOpacity(0.3),
                        backgroundImage: _previewAvatarUrl != null
                            ? NetworkImage(_previewAvatarUrl!)
                            : null,
                        child: _previewAvatarUrl == null
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingAvatar
                            ? null
                            : _pickAndUploadAvatar,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            border: Border.all(color: _kBg, width: 2),
                          ),
                          child: _isUploadingAvatar
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Basic Info ──────────────────────────────────────────
              _buildSectionHeader('Basic Info', Icons.person_outline),
              const SizedBox(height: 12),
              _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Name is required'
                      : null),
              const SizedBox(height: 12),
              _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.alternate_email),
              const SizedBox(height: 12),
              _buildTextField(
                  controller: _bioController,
                  label: 'Bio',
                  icon: Icons.info_outline,
                  maxLines: 3,
                  maxLength: 500),
              const SizedBox(height: 12),
              _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on_outlined),
              const SizedBox(height: 24),

              // ── Availability ────────────────────────────────────────
              _buildSectionHeader('Availability', Icons.schedule_outlined),
              const SizedBox(height: 12),
              _buildAvailabilitySelector(),
              const SizedBox(height: 24),

              // ── Social Links ────────────────────────────────────────
              _buildSectionHeader('Social Links', Icons.link),
              const SizedBox(height: 12),
              _buildTextField(
                  controller: _githubController,
                  label: 'GitHub URL',
                  icon: Icons.code,
                  keyboardType: TextInputType.url),
              const SizedBox(height: 12),
              _buildTextField(
                  controller: _linkedinController,
                  label: 'LinkedIn URL',
                  icon: Icons.business_center,
                  keyboardType: TextInputType.url),
              const SizedBox(height: 12),
              _buildTextField(
                  controller: _websiteController,
                  label: 'Website URL',
                  icon: Icons.language,
                  keyboardType: TextInputType.url),
              const SizedBox(height: 24),

              // ── Skills ──────────────────────────────────────────────
              _buildSectionHeader('Skills', Icons.psychology_outlined),
              const SizedBox(height: 12),
              CategorizedSkillPicker(
                selectedSkills: _skills,
                onSkillsChanged: (newSkills) =>
                    setState(() => _skills = newSkills),
              ),
              const SizedBox(height: 32),

              // ── Save button ─────────────────────────────────────────
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: LoadingButton(
                    label: 'Save Profile',
                    icon: Icons.save_outlined,
                    isLoading: _isSaving,
                    onPressed: _saveProfile,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.brightCyan),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.brightCyan,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: _kTextPrimary, fontSize: 14),
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: _kTextSecondary.withOpacity(0.8), fontSize: 13),
        prefixIcon: Icon(icon, color: _kTextSecondary, size: 20),
        filled: true,
        fillColor: _kInputFill,
        counterStyle: const TextStyle(color: _kTextSecondary),
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
          borderSide: const BorderSide(color: AppColors.deepRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              const BorderSide(color: AppColors.deepRed, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildAvailabilitySelector() {
    final options = [
      ('available', 'Available', AppColors.forestGreen),
      ('busy', 'Busy', AppColors.rebellionOrange),
      ('not_looking', 'Not Looking', AppColors.deepRed),
    ];

    return Row(
      children: options.map((option) {
        final isSelected = _availabilityStatus == option.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () =>
                setState(() => _availabilityStatus = option.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? option.$3.withOpacity(0.15)
                    : _kCardBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected
                      ? option.$3.withOpacity(0.5)
                      : _kBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isSelected ? option.$3 : _kTextSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.$2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? option.$3
                          : _kTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
