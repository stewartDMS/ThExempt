import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../models/task.dart';
import '../../../theme/app_colors.dart';

class ProjectTasksTab extends StatefulWidget {
  final Project project;
  final bool isTeamMember;

  const ProjectTasksTab({
    super.key,
    required this.project,
    this.isTeamMember = false,
  });

  @override
  State<ProjectTasksTab> createState() => _ProjectTasksTabState();
}

class _ProjectTasksTabState extends State<ProjectTasksTab> {
  TaskPriority? _filterPriority;
  // Placeholder task list (real implementation would fetch from backend)
  final List<Task> _tasks = [];

  @override
  Widget build(BuildContext context) {
    final filtered = _filterPriority == null
        ? _tasks
        : _tasks
            .where((t) => t.priority == _filterPriority)
            .toList();

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {},
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _TaskCard(task: filtered[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Priority:',
              style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          _filterChip('All', null),
          const SizedBox(width: 6),
          _filterChip('High', TaskPriority.high),
          const SizedBox(width: 6),
          _filterChip('Medium', TaskPriority.medium),
          const SizedBox(width: 6),
          _filterChip('Low', TaskPriority.low),
        ],
      ),
    );
  }

  Widget _filterChip(String label, TaskPriority? priority) {
    final selected = _filterPriority == priority;
    return GestureDetector(
      onTap: () => setState(() => _filterPriority = priority),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.electricBlue
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : Colors.grey[700],
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                _tasks.isEmpty
                    ? 'No tasks yet'
                    : 'No tasks for this priority',
                style: TextStyle(
                    fontSize: 16, color: Colors.grey[600]),
              ),
              if (_tasks.isEmpty && widget.isTeamMember) ...[
                const SizedBox(height: 8),
                Text(
                  'Add a task to get started',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority indicator
            Container(
              width: 4,
              height: 40,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: task.priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration:
                                task.status == TaskStatus.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                            color:
                                task.status == TaskStatus.completed
                                    ? Colors.grey
                                    : null,
                          ),
                        ),
                      ),
                      if (task.isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Overdue',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: task.priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.priorityLabel,
                          style: TextStyle(
                              fontSize: 10,
                              color: task.priorityColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.statusLabel,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700]),
                        ),
                      ),
                      if (task.assignedToName != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.person_outline,
                            size: 12,
                            color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text(task.assignedToName!,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600])),
                      ],
                      if (task.dueDate != null) ...[
                        const Spacer(),
                        Icon(Icons.calendar_today_outlined,
                            size: 11,
                            color: task.isOverdue
                                ? Colors.red
                                : Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text(
                          _formatDate(task.dueDate!),
                          style: TextStyle(
                              fontSize: 11,
                              color: task.isOverdue
                                  ? Colors.red
                                  : Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
