import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../models/project_health.dart';
import '../../../models/project_achievements.dart';
import '../../../models/project_stage.dart';
import '../../../theme/app_colors.dart';

class ProjectOverviewTab extends StatelessWidget {
  final Project project;
  final ProjectHealth health;

  const ProjectOverviewTab({
    super.key,
    required this.project,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickStats(context),
          const SizedBox(height: 16),
          // Phase 3 — Problem / Solution / Impact cards
          if (project.hasProblemStatement) ...[
            _buildStructuredCard(
              context,
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.red[600]!,
              title: 'Problem',
              content: project.problemStatement!,
            ),
            const SizedBox(height: 12),
          ],
          if (project.hasSolutionApproach) ...[
            _buildStructuredCard(
              context,
              icon: Icons.lightbulb_outline,
              iconColor: Colors.amber[700]!,
              title: 'Solution Approach',
              content: project.solutionApproach!,
            ),
            const SizedBox(height: 12),
          ],
          if (project.hasImpactMetrics) ...[
            _buildImpactMetricsCard(context),
            const SizedBox(height: 12),
          ],
          _buildHealthBreakdown(context),
          if (health.warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildWarnings(context),
          ],
          if (health.recommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildRecommendations(context),
          ],
          const SizedBox(height: 16),
          _buildAchievementsSection(context),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final openRoles = project.totalRolesNeeded - project.rolesFilled;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Stats',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statItem(
                  Icons.people_outline,
                  '${project.rolesFilled}/${project.totalRolesNeeded}',
                  'Team',
                  Colors.blue,
                ),
                _statItem(
                  Icons.assignment_outlined,
                  '$openRoles',
                  'Open Roles',
                  AppColors.rebellionOrange,
                ),
                _statItem(
                  Icons.visibility_outlined,
                  '${project.viewsCount ?? 0}',
                  'Views',
                  AppColors.brightCyan,
                ),
                _statItem(
                  Icons.thumb_up_alt_outlined,
                  '${project.endorsementsCount}',
                  'Endorsed',
                  AppColors.electricBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style:
                TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// Phase 3 — generic structured content card (Problem / Solution).
  Widget _buildStructuredCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[700], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Phase 3 — Impact Metrics card.
  Widget _buildImpactMetricsCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_graph, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Impact Metrics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: project.impactMetrics.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.green[200]!),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12),
                      children: [
                        TextSpan(
                          text: '${e.key}: ',
                          style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: e.value.toString(),
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBreakdown(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _healthRow('Team', health.teamScore, Colors.blue),
            const SizedBox(height: 8),
            _healthRow('Tasks', health.taskScore, Colors.green),
            const SizedBox(height: 8),
            _healthRow('Timeline', health.timelineScore, AppColors.rebellionOrange),
            const SizedBox(height: 8),
            _healthRow(
                'Engagement', health.engagementScore, AppColors.brightCyan),
            const SizedBox(height: 8),
            _healthRow(
                'Activity', health.activityScore, AppColors.expertiseOperations),
          ],
        ),
      ),
    );
  }

  Widget _healthRow(String label, double score, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${score.toInt()}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildWarnings(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.warmAmber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Warnings',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...health.warnings.map((w) => _warningTile(w)),
          ],
        ),
      ),
    );
  }

  Widget _warningTile(HealthWarning warning) {
    final severityColor = _severityColor(warning.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, right: 8),
            decoration: BoxDecoration(
              color: severityColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(warning.message,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(warning.action,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.critical:
        return Colors.red;
      case WarningSeverity.high:
        return AppColors.rebellionOrange;
      case WarningSeverity.medium:
        return Colors.amber;
      case WarningSeverity.low:
        return Colors.blue;
    }
  }

  Widget _buildRecommendations(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recommendations',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...health.recommendations.map((r) => _recommendationTile(r)),
          ],
        ),
      ),
    );
  }

  Widget _recommendationTile(HealthRecommendation rec) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(rec.icon, size: 18, color: AppColors.electricBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.message,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(rec.action,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    final achievements = Achievement.computeForProject(
      teamMemberCount: project.rolesFilled,
      totalRolesNeeded: project.totalRolesNeeded,
      viewsCount: project.viewsCount ?? 0,
      likesCount: project.likesCount ?? 0,
      applicationsCount: project.applicationsCount ?? 0,
      completedMilestones: 0,
      taskProgress: project.taskProgress ?? 0,
      isLaunched: project.stage == ProjectStage.launch,
    );
    final level = ProjectLevel.calculate(project.totalXP);
    final unlocked =
        achievements.where((a) => a.unlocked).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events,
                    color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Achievements',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text('Level ${level.level}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.electricBlue)),
              ],
            ),
            const SizedBox(height: 8),
            // XP progress bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: level.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Colors.amber),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${level.currentXP}/${level.xpForNextLevel} XP',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (unlocked.isEmpty)
              Text(
                'Complete milestones to earn achievements!',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[600]),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unlocked.map((a) => _achievementChip(a)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _achievementChip(Achievement achievement) {
    return Tooltip(
      message: '${achievement.description}\n+${achievement.xp} XP',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: achievement.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: achievement.color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(achievement.icon,
                size: 14, color: achievement.color),
            const SizedBox(width: 4),
            Text(
              achievement.title,
              style: TextStyle(
                  fontSize: 12,
                  color: achievement.color,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
