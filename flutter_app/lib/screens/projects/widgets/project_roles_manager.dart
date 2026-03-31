import 'package:flutter/material.dart';
import '../../../models/project_role_model.dart';
import '../../../services/projects_service.dart';
import '../../../theme/app_colors.dart';

/// Displays project roles grouped by category.
/// - When [isOwner] is true, shows add/edit/delete controls.
/// - When [isOwner] is false, shows Apply buttons for open roles.
class ProjectRolesManager extends StatefulWidget {
  final String projectId;
  final bool isOwner;
  final VoidCallback? onRolesChanged;

  const ProjectRolesManager({
    super.key,
    required this.projectId,
    required this.isOwner,
    this.onRolesChanged,
  });

  @override
  State<ProjectRolesManager> createState() => _ProjectRolesManagerState();
}

class _ProjectRolesManagerState extends State<ProjectRolesManager> {
  Map<String, List<ProjectRole>> _rolesByCategory = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Category color map — aligned with ThExempt brand palette
  static const Map<String, Color> _categoryColors = {
    'Technical': AppColors.electricBlue,
    'Business': AppColors.forestGreen,
    'Marketing': AppColors.rebellionOrange,
    'Operations': AppColors.expertiseOperations,
    'Creative': AppColors.expertiseCreative,
    'Legal': AppColors.electricBlue,
    'Domain': AppColors.deepRed,
    'Soft Skills': AppColors.brightCyan,
  };

  static const List<String> _categories = [
    'Technical',
    'Business',
    'Marketing',
    'Operations',
    'Creative',
    'Legal',
    'Domain',
    'Soft Skills',
  ];

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final roles = await ProjectsService.getProjectRoles(widget.projectId);
      if (mounted) {
        setState(() {
          _rolesByCategory = roles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Color _colorForCategory(String category) =>
      _categoryColors[category] ?? AppColors.primary;

  int get _totalRoles =>
      _rolesByCategory.values.fold(0, (sum, list) => sum + list.length);

  int get _openRoles => _rolesByCategory.values
      .fold(0, (sum, list) => sum + list.where((r) => !r.isFilled).length);

  // ── Add / Edit dialog ──────────────────────────────────────────────────────

  Future<void> _showAddEditDialog({ProjectRole? existing}) async {
    final categoryCtrl = ValueNotifier<String>(
        existing?.roleCategory ?? _categories.first);
    final titleCtrl =
        TextEditingController(text: existing?.roleTitle ?? '');
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    final skillsCtrl = TextEditingController(
        text: (existing?.skillsRequired ?? []).join(', '));
    bool isFilled = existing?.isFilled ?? false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Role' : 'Edit Role'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category picker
                const Text('Category',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ValueListenableBuilder<String>(
                  valueListenable: categoryCtrl,
                  builder: (_, val, __) => DropdownButtonFormField<String>(
                    value: val,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) categoryCtrl.value = v;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text('Role Title *',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Marketing Manager',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                const Text('Description',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'What does this role involve?',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // Skills
                const Text('Skills Required',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: skillsCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Comma-separated, e.g. React, TypeScript',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                if (existing != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isFilled,
                        onChanged: (v) =>
                            setDialogState(() => isFilled = v ?? false),
                      ),
                      const Text('Mark as Filled'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final skills = skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    try {
      if (existing == null) {
        await ProjectsService.addProjectRole(
          projectId: widget.projectId,
          roleCategory: categoryCtrl.value,
          roleTitle: titleCtrl.text.trim(),
          description: descCtrl.text.trim().isEmpty
              ? null
              : descCtrl.text.trim(),
          skillsRequired: skills,
        );
      } else {
        await ProjectsService.updateProjectRole(
          projectId: widget.projectId,
          roleId: existing.id,
          roleCategory: categoryCtrl.value,
          roleTitle: titleCtrl.text.trim(),
          description: descCtrl.text.trim().isEmpty
              ? null
              : descCtrl.text.trim(),
          skillsRequired: skills,
          isFilled: isFilled,
        );
      }
      await _loadRoles();
      widget.onRolesChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteRole(ProjectRole role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text(
            'Are you sure you want to delete "${role.roleTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ProjectsService.deleteProjectRole(
        projectId: widget.projectId,
        roleId: role.id,
      );
      await _loadRoles();
      widget.onRolesChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ── Apply button handler ───────────────────────────────────────────────────

  Future<void> _applyForRole(ProjectRole role) async {
    final msgCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apply for ${role.roleTitle}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category: ${role.roleCategory}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            if (role.skillsRequired.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Skills Required: ${role.skillsRequired.join(', ')}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Message *',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Why are you a good fit for this role?',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (msgCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ProjectsService.applyForRole(
        projectId: widget.projectId,
        roleId: role.id,
        message: msgCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted!'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Expanded(
              child: Text(
                'Team Roles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.isOwner)
              TextButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Role'),
              ),
          ],
        ),

        // Summary chips (only show when there are roles)
        if (_totalRoles > 0 && !_isLoading) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _SummaryChip(
                label: '$_totalRoles Total',
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: '$_openRoles Open',
                color: AppColors.forestGreen,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: '${_totalRoles - _openRoles} Filled',
                color: Colors.grey[500]!,
              ),
            ],
          ),
        ],

        const SizedBox(height: 12),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Could not load roles.',
              style: TextStyle(color: AppColors.error),
            ),
          )
        else if (_rolesByCategory.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              widget.isOwner
                  ? 'No roles added yet. Tap "Add Role" to define what your project needs.'
                  : 'No specific roles defined for this project.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          )
        else
          ..._rolesByCategory.entries.map(
            (entry) => _CategorySection(
              category: entry.key,
              roles: entry.value,
              categoryColor: _colorForCategory(entry.key),
              isOwner: widget.isOwner,
              onEdit: (role) => _showAddEditDialog(existing: role),
              onDelete: _deleteRole,
              onApply: _applyForRole,
            ),
          ),
      ],
    );
  }
}

// ── Summary chip ──────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Category section ──────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final String category;
  final List<ProjectRole> roles;
  final Color categoryColor;
  final bool isOwner;
  final void Function(ProjectRole) onEdit;
  final void Function(ProjectRole) onDelete;
  final void Function(ProjectRole) onApply;

  const _CategorySection({
    required this.category,
    required this.roles,
    required this.categoryColor,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${roles.length} role${roles.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),

        // Role tiles
        ...roles.map(
          (role) => _RoleTile(
            role: role,
            categoryColor: categoryColor,
            isOwner: isOwner,
            onEdit: () => onEdit(role),
            onDelete: () => onDelete(role),
            onApply: () => onApply(role),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Role tile ─────────────────────────────────────────────────────────────────

class _RoleTile extends StatelessWidget {
  final ProjectRole role;
  final Color categoryColor;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApply;

  const _RoleTile({
    required this.role,
    required this.categoryColor,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: role.isFilled
            ? Colors.grey[100]
            : categoryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: role.isFilled
              ? Colors.grey[300]!
              : categoryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: role.isFilled ? Colors.grey[400] : AppColors.forestGreen,
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        role.roleTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: role.isFilled
                              ? Colors.grey[500]
                              : Colors.black87,
                          decoration: role.isFilled
                              ? TextDecoration.none
                              : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: role.isFilled
                            ? Colors.grey[200]
                            : AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        role.isFilled ? 'Filled' : 'Open',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: role.isFilled
                              ? Colors.grey[600]
                              : AppColors.forestGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                if (role.description != null &&
                    role.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    role.description!,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                if (role.skillsRequired.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: role.skillsRequired.take(4).map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 11,
                            color: categoryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          if (isOwner) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 18, color: Colors.grey[500]),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.error))),
              ],
            ),
          ] else if (!role.isFilled) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
                backgroundColor: categoryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Apply'),
            ),
          ],
        ],
      ),
    );
  }
}
