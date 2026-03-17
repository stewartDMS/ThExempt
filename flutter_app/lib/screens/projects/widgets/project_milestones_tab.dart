import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../models/milestone.dart';
import '../../../models/project_stage.dart';

class ProjectMilestonesTab extends StatelessWidget {
  final Project project;

  const ProjectMilestonesTab({super.key, required this.project});

  /// Build placeholder milestones derived from the project's stage progression.
  List<Milestone> _buildDefaultMilestones() {
    final stages = ProjectStage.values;
    final currentIndex = stages.indexOf(project.stage);
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

  @override
  Widget build(BuildContext context) {
    final milestones = _buildDefaultMilestones();
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: milestones.length,
        itemBuilder: (context, index) {
          final milestone = milestones[index];
          final isLast = index == milestones.length - 1;
          return _MilestoneRow(
            milestone: milestone,
            isLast: isLast,
            isCurrent: milestone.stage == project.stage,
          );
        },
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
