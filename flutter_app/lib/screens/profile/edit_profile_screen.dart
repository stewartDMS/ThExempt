import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

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
  late TextEditingController _skillsController;

  String _availabilityStatus = 'available';
  List<String> _skills = [];
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _previewAvatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController =
        TextEditingController(text: widget.user.username ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _locationController =
        TextEditingController(text: widget.user.location ?? '');
    _githubController =
        TextEditingController(text: widget.user.githubUrl ?? '');
    _linkedinController =
        TextEditingController(text: widget.user.linkedinUrl ?? '');
    _websiteController =
        TextEditingController(text: widget.user.websiteUrl ?? '');
    _skillsController = TextEditingController();
    _availabilityStatus = widget.user.availabilityStatus;
    _skills = List<String>.from(widget.user.skills);
    _previewAvatarUrl = widget.user.avatarUrl;
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
    _skillsController.dispose();
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
      final bytes = await File(file.path!).readAsBytes();
      final base64Image =
          'data:image/${file.extension ?? 'png'};base64,${base64Encode(bytes)}';
      final fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}.${file.extension ?? 'png'}';

      final avatarUrl = await UserService.uploadAvatar(
        base64Image: base64Image,
        fileName: fileName,
      );

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
          SnackBar(content: Text('Failed to upload avatar: $e')),
        );
      }
    }
  }

  void _addSkill() {
    final skill = _skillsController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillsController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
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

      if (mounted) {
        Navigator.of(context).pop(updatedUser);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
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
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
              // Avatar section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: _previewAvatarUrl != null
                          ? NetworkImage(_previewAvatarUrl!)
                          : null,
                      child: _previewAvatarUrl == null
                          ? Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Tooltip(
                        message: 'Upload profile picture',
                        child: GestureDetector(
                          onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF6366F1),
                            child: _isUploadingAvatar
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Info
              _buildSectionHeader('Basic Info'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Full Name', Icons.person_outline),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration:
                    _inputDecoration('Username', Icons.alternate_email),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                decoration: _inputDecoration('Bio', Icons.info_outline),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Location', Icons.location_on_outlined),
              ),
              const SizedBox(height: 24),

              // Availability
              _buildSectionHeader('Availability'),
              const SizedBox(height: 12),
              _buildAvailabilitySelector(),
              const SizedBox(height: 24),

              // Social Links
              _buildSectionHeader('Social Links'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _githubController,
                decoration: _inputDecoration('GitHub URL', Icons.code),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkedinController,
                decoration:
                    _inputDecoration('LinkedIn URL', Icons.business_center),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteController,
                decoration: _inputDecoration('Website URL', Icons.language),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),

              // Skills
              _buildSectionHeader('Skills'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillsController,
                      decoration:
                          _inputDecoration('Add a skill', Icons.psychology_outlined),
                      onFieldSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSkill,
                    child: const Text('Add'),
                  ),
                ],
              ),
              if (_skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeSkill(skill),
                      backgroundColor:
                          const Color(0xFF6366F1).withOpacity(0.1),
                      labelStyle:
                          const TextStyle(color: Color(0xFF6366F1)),
                      deleteIconColor: const Color(0xFF6366F1),
                      side: BorderSide(
                          color: const Color(0xFF6366F1).withOpacity(0.3)),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6366F1),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildAvailabilitySelector() {
    final options = [
      ('available', 'Available', Colors.green),
      ('busy', 'Busy', Colors.orange),
      ('not_looking', 'Not Looking', Colors.red),
    ];

    return Row(
      children: options.map((option) {
        final isSelected = _availabilityStatus == option.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _availabilityStatus = option.$1),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? option.$3.withOpacity(0.15)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? option.$3 : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isSelected ? option.$3 : Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.$2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? option.$3 : Colors.grey[600],
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
