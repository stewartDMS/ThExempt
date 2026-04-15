import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/discussion_resource_model.dart';
import '../../services/discussion_resources_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/time_ago.dart';

// ── Dark palette ──────────────────────────────────────────────────────────────
const _kBg            = Color(0xFF14141A);
const _kCardBg        = Color(0xFF1C1C1E);
const _kInputFill     = Color(0xFF252528);
const _kBorder        = Color(0xFF3A3A3C);
const _kDivider       = Color(0xFF2C2C2F);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

/// Phase 1 — Resource Library panel for a discussion thread.
///
/// Lists all resources attached to [discussionId] and allows authenticated
/// users to add a new link resource via an inline form.
class DiscussionResourcesPanel extends StatefulWidget {
  final String discussionId;
  final String discussionAuthorId;

  const DiscussionResourcesPanel({
    super.key,
    required this.discussionId,
    required this.discussionAuthorId,
  });

  @override
  State<DiscussionResourcesPanel> createState() =>
      _DiscussionResourcesPanelState();
}

class _DiscussionResourcesPanelState extends State<DiscussionResourcesPanel> {
  List<DiscussionResource> _resources = [];
  bool _loading = true;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resources = await DiscussionResourcesService.getResources(
        widget.discussionId,
        type: _filterType,
      );
      if (mounted) {
        setState(() {
          _resources = resources;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddResourceDialog(
        discussionId: widget.discussionId,
        onAdded: (resource) {
          setState(() => _resources.insert(0, resource));
        },
      ),
    );
  }

  Future<void> _delete(DiscussionResource resource) async {
    try {
      await DiscussionResourcesService.deleteResource(resource.id);
      setState(() => _resources.remove(resource));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool get _isAuthenticated =>
      Supabase.instance.client.auth.currentUser != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.library_books_outlined,
                  size: 18, color: AppColors.brightCyan),
              const SizedBox(width: 8),
              const Text(
                'Resource Library',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              const Spacer(),
              if (_isAuthenticated)
                GestureDetector(
                  onTap: _showAddDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: AppColors.brightCyan.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14, color: AppColors.brightCyan),
                        SizedBox(width: 4),
                        Text('Add',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brightCyan)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Type filter chips ──────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: _filterType == null,
                onTap: () {
                  setState(() => _filterType = null);
                  _load();
                },
              ),
              ...ResourceType.values.map((t) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _FilterChip(
                      label: t.label,
                      isSelected: _filterType == t.value,
                      onTap: () {
                        setState(() => _filterType = t.value);
                        _load();
                      },
                    ),
                  )),
            ],
          ),
        ),

        const Divider(height: 1, color: _kDivider),

        // ── List ────────────────────────────────────────────────────────
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.brightCyan)),
          )
        else if (_resources.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 40, horizontal: 24),
            child: Column(
              children: [
                const Icon(Icons.library_books_outlined,
                    size: 52, color: _kBorder),
                const SizedBox(height: 12),
                const Text(
                  'No resources yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Share a link, document, or reference that helps this discussion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: _kTextSecondary),
                ),
                if (_isAuthenticated) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _showAddDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 11),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.electricBlue,
                            AppColors.brightCyan,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Add Resource',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _resources.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: _kDivider),
            itemBuilder: (_, i) => _ResourceTile(
              resource: _resources[i],
              canDelete:
                  Supabase.instance.client.auth.currentUser?.id ==
                      _resources[i].uploadedBy,
              onDelete: () => _delete(_resources[i]),
            ),
          ),
      ],
    );
  }
}

// ── Resource tile ──────────────────────────────────────────────────────────

class _ResourceTile extends StatelessWidget {
  final DiscussionResource resource;
  final bool canDelete;
  final VoidCallback onDelete;

  const _ResourceTile({
    required this.resource,
    required this.canDelete,
    required this.onDelete,
  });

  IconData _typeIcon() {
    switch (resource.resourceType) {
      case ResourceType.link:
        return Icons.link;
      case ResourceType.document:
        return Icons.description_outlined;
      case ResourceType.video:
        return Icons.play_circle_outline;
      case ResourceType.image:
        return Icons.image_outlined;
      case ResourceType.dataset:
        return Icons.table_chart_outlined;
    }
  }

  Color _typeColor() {
    switch (resource.resourceType) {
      case ResourceType.link:
        return AppColors.primary;
      case ResourceType.document:
        return const Color(0xFF3F51B5);
      case ResourceType.video:
        return AppColors.error;
      case ResourceType.image:
        return const Color(0xFF9C27B0);
      case ResourceType.dataset:
        return AppColors.success;
    }
  }

  Future<void> _open() async {
    if (resource.url == null) return;
    final uri = Uri.tryParse(resource.url!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();

    return InkWell(
      onTap: resource.url != null ? _open : null,
      splashColor: color.withOpacity(0.08),
      highlightColor: color.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(_typeIcon(), size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (resource.isFeatured) ...[
                        const Icon(Icons.star,
                            size: 12, color: AppColors.warmAmber),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          resource.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (resource.description != null &&
                      resource.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      resource.description!,
                      style: const TextStyle(
                          fontSize: 12, color: _kTextSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          resource.resourceType.label,
                          style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (resource.uploaderName != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          'by ${resource.uploaderName}',
                          style: const TextStyle(
                              fontSize: 11, color: _kTextSecondary),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        timeAgo(resource.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: _kTextSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (resource.url != null)
              const Icon(Icons.open_in_new,
                  size: 16, color: _kTextSecondary),
            if (canDelete) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline,
                      size: 16, color: _kTextSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.electricBlue.withOpacity(0.2)
              : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? AppColors.brightCyan.withOpacity(0.6)
                : const Color(0xFF3A3A3C),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.brightCyan : const Color(0xFFAAAAAA),
          ),
        ),
      ),
    );
  }
}

// ── Add resource dialog ────────────────────────────────────────────────────

class _AddResourceDialog extends StatefulWidget {
  final String discussionId;
  final ValueChanged<DiscussionResource> onAdded;

  const _AddResourceDialog({
    required this.discussionId,
    required this.onAdded,
  });

  @override
  State<_AddResourceDialog> createState() => _AddResourceDialogState();
}

class _AddResourceDialogState extends State<_AddResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descController = TextEditingController();
  ResourceType _selectedType = ResourceType.link;
  bool _isFeatured = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final resource = await DiscussionResourcesService.addResource(
        discussionId: widget.discussionId,
        resourceType: _selectedType.value,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        url: _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        isFeatured: _isFeatured,
      );
      widget.onAdded(resource);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not add resource: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const dialogBg = Color(0xFF1C1C1E);
    const inputFill = Color(0xFF252528);
    const border = Color(0xFF3A3A3C);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: border),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.brightCyan, width: 1.5),
    );
    return AlertDialog(
      backgroundColor: dialogBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border)),
      title: const Text('Add Resource',
          style: TextStyle(
              color: _kTextPrimary, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector
                const Text('Type',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kTextSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ResourceType.values.map((t) {
                    final selected = _selectedType == t;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.electricBlue.withOpacity(0.2)
                              : inputFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppColors.brightCyan.withOpacity(0.6)
                                : border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? AppColors.brightCyan
                                : _kTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Title
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: _kTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    labelStyle:
                        const TextStyle(color: _kTextSecondary),
                    filled: true,
                    fillColor: inputFill,
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: focusedBorder,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                // URL
                TextFormField(
                  controller: _urlController,
                  style: const TextStyle(color: _kTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'URL (link)',
                    labelStyle:
                        const TextStyle(color: _kTextSecondary),
                    hintText: 'https://',
                    hintStyle:
                        const TextStyle(color: _kTextSecondary),
                    filled: true,
                    fillColor: inputFill,
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: focusedBorder,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                // Description
                TextFormField(
                  controller: _descController,
                  style: const TextStyle(color: _kTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle:
                        const TextStyle(color: _kTextSecondary),
                    filled: true,
                    fillColor: inputFill,
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: focusedBorder,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                // Featured toggle
                Row(
                  children: [
                    Switch(
                      value: _isFeatured,
                      onChanged: (v) =>
                          setState(() => _isFeatured = v),
                      activeColor: AppColors.brightCyan,
                    ),
                    const SizedBox(width: 8),
                    const Text('Mark as featured',
                        style: TextStyle(
                            fontSize: 13, color: _kTextSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: _kTextSecondary)),
        ),
        GestureDetector(
          onTap: _submitting ? null : _submit,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.electricBlue,
                  AppColors.brightCyan,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Add',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
          ),
        ),
      ],
    );
  }
}
