import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../models/milestone.dart';
import '../../../models/project_stage.dart';
import '../../../services/projects_service.dart';

class ProjectMilestonesTab extends StatefulWidget {
  final Project project;
  final bool isOwner;

  const ProjectMilestonesTab({
    super.key,
    required this.project,
    this.isOwner = false,
  });

  @override
  State<ProjectMilestonesTab> createState() => _ProjectMilestonesTabState();
}

class _ProjectMilestonesTabState extends State<ProjectMilestonesTab> {
  List<Map<String, dynamic>> _dbMilestones = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final milestones =
          await ProjectsService.getProjectMilestones(widget.project.id);
      if (mounted) {
        setState(() {
          _dbMilestones = milestones;
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

  /// Fallback: stage-derived milestones used when no DB milestones exist.
  List<Milestone> _buildDefaultMilestones() {
    final stages = ProjectStage.values;
    final currentIndex = stages.indexOf(widget.project.stage);
    return stages.asMap().entries.map((entry) {
      final i = entry.key;
      final stage = entry.value;
      return Milestone(
        id: 'stage_$i',
        title: stage.displayName,
        description: stage.description,
        stage: stage,
        isComplete: i < currentIndex,
        progress: i < currentIndex
            ? 1.0
            : i == currentIndex
                ? 0.5
                : 0.0,
        tasks: const [],
      );
    }).toList();
  }

  Future<void> _showAddMilestoneDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? dueDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Milestone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Milestone Title',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          DateTime.now().add(const Duration(days: 14)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked != null) {
                      setDlgState(() => dueDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(dueDate == null
                      ? 'Set Due Date (optional)'
                      : 'Due: ${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}'),
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;

    try {
      await ProjectsService.addMilestone(
        projectId: widget.project.id,
        title: title,
        description: descController.text.trim(),
        dueDate: dueDate,
        displayOrder: _dbMilestones.length,
      );
      await _loadMilestones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Milestone added!'),
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

    // If the DB has real milestones, show them; otherwise fall back to stages.
    if (_dbMilestones.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMilestones,
        child: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 80),
              itemCount: _dbMilestones.length,
              itemBuilder: (context, index) {
                final m = _dbMilestones[index];
                return _DbMilestoneRow(
                  data: m,
                  isLast: index == _dbMilestones.length - 1,
                  isOwner: widget.isOwner,
                  onToggle: () async {
                    final isComplete = m['completed_at'] != null;
                    if (isComplete) {
                      await ProjectsService.reopenMilestone(m['id']);
                    } else {
                      await ProjectsService.completeMilestone(m['id']);
                    }
                    await _loadMilestones();
                  },
                  onDelete: () async {
                    await ProjectsService.deleteMilestone(m['id']);
                    await _loadMilestones();
                  },
                );
              },
            ),
            if (widget.isOwner)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: _showAddMilestoneDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Milestone'),
                ),
              ),
          ],
        ),
      );
    }

    // Fallback to stage-derived milestones
    final milestones = _buildDefaultMilestones();
    return RefreshIndicator(
      onRefresh: _loadMilestones,
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 80),
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              final milestone = milestones[index];
              final isLast = index == milestones.length - 1;
              return _MilestoneRow(
                milestone: milestone,
                isLast: isLast,
                isCurrent: milestone.stage == widget.project.stage,
              );
            },
          ),
          if (widget.isOwner)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: _showAddMilestoneDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Milestone'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Row for a DB-backed milestone record.
class _DbMilestoneRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLast;
  final bool isOwner;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const _DbMilestoneRow({
    required this.data,
    required this.isLast,
    required this.isOwner,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = data['completed_at'] != null;
    final title = data['title'] as String? ?? '';
    final description = data['description'] as String?;
    final dueDate = data['due_date'] != null
        ? DateTime.tryParse(data['due_date'])
        : null;
    final dotColor = isComplete ? Colors.green : Colors.grey[300]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin:
                      const EdgeInsets.only(top: 12, left: 12, right: 12),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                  child: isComplete
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 14)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 23),
                      color: isComplete ? Colors.green : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Card(
              margin:
                  const EdgeInsets.only(right: 16, bottom: 12, top: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isComplete
                                  ? Colors.green[700]
                                  : Colors.grey[800],
                              decoration: isComplete
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (isComplete)
                          _badge('Done', Colors.green)
                        else if (dueDate != null &&
                            dueDate.isBefore(DateTime.now()))
                          _badge('Overdue', Colors.red),
                        if (isOwner)
                          PopupMenuButton<String>(
                            iconSize: 18,
                            onSelected: (v) {
                              if (v == 'toggle') onToggle?.call();
                              if (v == 'delete') onDelete?.call();
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(isComplete
                                    ? 'Mark Incomplete'
                                    : 'Mark Complete'),
                              ),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Delete')),
                            ],
                          ),
                      ],
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(description,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600])),
                    ],
                    if (dueDate != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final Milestone milestone;
  final bool isLast;
  final bool isCurrent;

  const _MilestoneRow({
    required this.milestone,
    required this.isLast,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = milestone.isComplete
        ? Colors.green
        : isCurrent
            ? Colors.blue
            : Colors.grey[300]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: Colors.blue, width: 3)
                        : null,
                  ),
                  child: milestone.isComplete
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 23),
                      color: milestone.isComplete
                          ? Colors.green
                          : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          // Card content
          Expanded(
            child: Card(
              margin:
                  const EdgeInsets.only(right: 16, bottom: 12, top: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isCurrent
                    ? const BorderSide(color: Colors.blue, width: 1.5)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${milestone.stage.emoji} ${milestone.title}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: milestone.isComplete
                                ? Colors.green[700]
                                : isCurrent
                                    ? Colors.blue[700]
                                    : Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                        if (milestone.isComplete)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Done',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600),
                            ),
                          )
                        else if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Current',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    if (milestone.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        milestone.description!,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                    if (isCurrent) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: milestone.progress,
                        backgroundColor: Colors.blue[100],
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.blue),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(milestone.progress * 100).toInt()}% complete',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final Milestone milestone;
  final bool isLast;
  final bool isCurrent;

  const _MilestoneRow({
    required this.milestone,
    required this.isLast,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = milestone.isComplete
        ? Colors.green
        : isCurrent
            ? Colors.blue
            : Colors.grey[300]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: Colors.blue, width: 3)
                        : null,
                  ),
                  child: milestone.isComplete
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 23),
                      color: milestone.isComplete
                          ? Colors.green
                          : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          // Card content
          Expanded(
            child: Card(
              margin:
                  const EdgeInsets.only(right: 16, bottom: 12, top: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isCurrent
                    ? const BorderSide(color: Colors.blue, width: 1.5)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${milestone.stage.emoji} ${milestone.title}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: milestone.isComplete
                                ? Colors.green[700]
                                : isCurrent
                                    ? Colors.blue[700]
                                    : Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                        if (milestone.isComplete)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Done',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600),
                            ),
                          )
                        else if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Current',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    if (milestone.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        milestone.description!,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                    if (isCurrent) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: milestone.progress,
                        backgroundColor: Colors.blue[100],
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.blue),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(milestone.progress * 100).toInt()}% complete',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
