import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../models/project_update_model.dart';
import '../../../services/projects_service.dart';
import '../../../utils/time_ago.dart';
import '../../../theme/app_colors.dart';

class ProjectUpdatesTab extends StatefulWidget {
  final Project project;
  final bool isOwner;

  const ProjectUpdatesTab({
    super.key,
    required this.project,
    required this.isOwner,
  });

  @override
  State<ProjectUpdatesTab> createState() => _ProjectUpdatesTabState();
}

class _ProjectUpdatesTabState extends State<ProjectUpdatesTab> {
  List<ProjectUpdate> _updates = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final updates =
          await ProjectsService.getProjectUpdates(widget.project.id);
      if (mounted) {
        setState(() {
          _updates = updates;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _showAddUpdateDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    ProjectUpdateType selectedType = ProjectUpdateType.general;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Post Progress Update'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ProjectUpdateType>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Update Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ProjectUpdateType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDlgState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final title = titleController.text.trim();
    final content = contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    try {
      await ProjectsService.addProjectUpdate(
        projectId: widget.project.id,
        title: title,
        content: content,
        updateType: selectedType,
      );
      await _loadUpdates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update posted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Failed to load updates'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadUpdates,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUpdates,
      child: Stack(
        children: [
          _updates.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _updates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _UpdateCard(
                    update: _updates[i],
                    isOwner: widget.isOwner,
                    onDelete: () async {
                      await ProjectsService.deleteProjectUpdate(_updates[i].id);
                      await _loadUpdates();
                    },
                  ),
                ),
          if (widget.isOwner)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: _showAddUpdateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Post Update'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No updates yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isOwner
                ? 'Share progress with your community!'
                : 'The project owner hasn\'t posted any updates yet.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final ProjectUpdate update;
  final bool isOwner;
  final VoidCallback? onDelete;

  const _UpdateCard({
    required this.update,
    required this.isOwner,
    this.onDelete,
  });

  Color _typeColor(ProjectUpdateType type) {
    switch (type) {
      case ProjectUpdateType.milestone:
        return Colors.green;
      case ProjectUpdateType.funding:
        return Colors.amber;
      case ProjectUpdateType.team:
        return Colors.blue;
      case ProjectUpdateType.media:
        return Colors.purple;
      case ProjectUpdateType.general:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(update.updateType);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    update.updateType.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (update.isPinned) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.push_pin, size: 14, color: Colors.grey[500]),
                ],
                const Spacer(),
                Text(
                  timeAgo(update.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    iconSize: 18,
                    onSelected: (v) {
                      if (v == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              update.title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              update.content,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: update.userAvatarUrl != null &&
                          update.userAvatarUrl!.isNotEmpty
                      ? NetworkImage(update.userAvatarUrl!)
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: update.userAvatarUrl == null ||
                          update.userAvatarUrl!.isEmpty
                      ? Text(
                          update.userName.isNotEmpty
                              ? update.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(fontSize: 10),
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                Text(
                  update.userName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
