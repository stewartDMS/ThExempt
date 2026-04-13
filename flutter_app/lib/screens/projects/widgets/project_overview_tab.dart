import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../models/project_health.dart';
import '../../../models/project_achievements.dart';
import '../../../models/project_stage.dart';
import '../../../theme/app_colors.dart';

// ─── Dark surface constants ────────────────────────────────────────────────
const _cardColor = Color(0xFF2C2C2C);
const _cardBorder = Color(0xFF3A3A3A);

// ─── Layout constants ──────────────────────────────────────────────────────
const _kWideScreenBreakpoint = 500.0;

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
      color: AppColors.electricBlue,
      backgroundColor: _cardColor,
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _buildQuickStats(context),
          const SizedBox(height: 20),
          // Phase 3 — Problem / Solution / Impact cards
          if (project.hasProblemStatement) ...[
            _buildStructuredCard(
              context,
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.deepRed,
              title: 'Problem',
              content: project.problemStatement!,
            ),
            const SizedBox(height: 14),
          ],
          if (project.hasSolutionApproach) ...[
            _buildStructuredCard(
              context,
              icon: Icons.lightbulb_outline,
              iconColor: AppColors.warmAmber,
              title: 'Solution Approach',
              content: project.solutionApproach!,
            ),
            const SizedBox(height: 14),
          ],
          if (project.hasImpactMetrics) ...[
            _buildImpactMetricsCard(context),
            const SizedBox(height: 14),
          ],
          _buildHealthBreakdown(context),
          if (health.warnings.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildWarnings(context),
          ],
          if (health.recommendations.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildRecommendations(context),
          ],
          const SizedBox(height: 20),
          _buildAchievementsSection(context),
        ],
      ),
    );
  }

  // ─── Quick Stats ───────────────────────────────────────────────────────────

  Widget _buildQuickStats(BuildContext context) {
    final openRoles = project.totalRolesNeeded - project.rolesFilled;
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.bar_chart_rounded,
            iconColor: AppColors.brightCyan,
            title: 'Quick Stats',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final stats = [
              _statCell(Icons.people_outline,
                  '${project.rolesFilled}/${project.totalRolesNeeded}',
                  'Team', AppColors.electricBlue),
              _statCell(Icons.assignment_outlined, '$openRoles', 'Open Roles',
                  AppColors.rebellionOrange),
              _statCell(Icons.visibility_outlined,
                  '${project.viewsCount ?? 0}', 'Views', AppColors.brightCyan),
              _statCell(Icons.thumb_up_alt_outlined,
                  '${project.endorsementsCount}', 'Endorsed',
                  AppColors.forestGreen),
            ];
            if (constraints.maxWidth >= _kWideScreenBreakpoint) {
              // Wide: all four side-by-side
              return Row(
                  children: stats.map((s) => Expanded(child: s)).toList());
            }
            // Narrow: two rows of two, with equal column width and a gap
            const rowSpacing = 16.0;
            return Column(
              children: [
                Row(
                  children: stats
                      .sublist(0, 2)
                      .map((s) => Expanded(child: s))
                      .toList(),
                ),
                const SizedBox(height: rowSpacing),
                Row(
                  children: stats
                      .sublist(2, 4)
                      .map((s) => Expanded(child: s))
                      .toList(),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _statCell(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.25), color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Structured content card (Problem / Solution) ─────────────────────────

  Widget _buildStructuredCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return _DarkCard(
      accentColor: iconColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: icon, iconColor: iconColor, title: title),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Impact Metrics ────────────────────────────────────────────────────────

  Widget _buildImpactMetricsCard(BuildContext context) {
    return _DarkCard(
      accentColor: AppColors.forestGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.auto_graph,
            iconColor: AppColors.forestGreen,
            title: 'Impact Metrics',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: project.impactMetrics.entries.map((e) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: AppColors.forestGreen.withOpacity(0.4)),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12),
                    children: [
                      TextSpan(
                        text: '${e.key}: ',
                        style: const TextStyle(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: e.value.toString(),
                        style: TextStyle(
                          color: AppColors.forestGreen.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Health Breakdown ──────────────────────────────────────────────────────

  Widget _buildHealthBreakdown(BuildContext context) {
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.monitor_heart_outlined,
            iconColor: AppColors.electricBlue,
            title: 'Health Breakdown',
          ),
          const SizedBox(height: 16),
          _healthRow('Team', health.teamScore, AppColors.electricBlue),
          const SizedBox(height: 12),
          _healthRow('Tasks', health.taskScore, AppColors.forestGreen),
          const SizedBox(height: 12),
          _healthRow(
              'Timeline', health.timelineScore, AppColors.rebellionOrange),
          const SizedBox(height: 12),
          _healthRow(
              'Engagement', health.engagementScore, AppColors.brightCyan),
          const SizedBox(height: 12),
          _healthRow(
              'Activity', health.activityScore, AppColors.expertiseOperations),
        ],
      ),
    );
  }

  Widget _healthRow(String label, double score, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: score / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 38,
              child: Text(
                '${score.toInt()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Warnings ─────────────────────────────────────────────────────────────

  Widget _buildWarnings(BuildContext context) {
    return _DarkCard(
      accentColor: AppColors.warmAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warmAmber,
            title: 'Warnings',
          ),
          const SizedBox(height: 14),
          ...health.warnings.map((w) => _warningTile(w)),
        ],
      ),
    );
  }

  Widget _warningTile(HealthWarning warning) {
    final severityColor = _severityColor(warning.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 3, right: 10),
            decoration: BoxDecoration(
              color: severityColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: severityColor.withOpacity(0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning.message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  warning.action,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    height: 1.4,
                  ),
                ),
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
        return AppColors.deepRed;
      case WarningSeverity.high:
        return AppColors.rebellionOrange;
      case WarningSeverity.medium:
        return AppColors.warmAmber;
      case WarningSeverity.low:
        return AppColors.electricBlue;
    }
  }

  // ─── Recommendations ──────────────────────────────────────────────────────

  Widget _buildRecommendations(BuildContext context) {
    return _DarkCard(
      accentColor: AppColors.warmAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.lightbulb_outline,
            iconColor: AppColors.warmAmber,
            title: 'Recommendations',
          ),
          const SizedBox(height: 14),
          ...health.recommendations.map((r) => _recommendationTile(r)),
        ],
      ),
    );
  }

  Widget _recommendationTile(HealthRecommendation rec) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(rec.icon, size: 16, color: AppColors.electricBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rec.action,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Achievements ──────────────────────────────────────────────────────────

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
    final unlocked = achievements.where((a) => a.unlocked).toList();

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + level badge
          Row(
            children: [
              _SectionHeader(
                icon: Icons.emoji_events_rounded,
                iconColor: AppColors.warmAmber,
                title: 'Achievements',
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.electricBlue, AppColors.brightCyan],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Level ${level.level}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // XP progress bar
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 16, color: AppColors.warmAmber),
              const SizedBox(width: 6),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: level.progress),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.warmAmber),
                        minHeight: 10,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${level.currentXP}/${level.xpForNextLevel} XP',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (unlocked.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      size: 18, color: Colors.white38),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Complete milestones to earn achievements!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unlocked.map((a) => _achievementChip(a)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _achievementChip(Achievement achievement) {
    return Tooltip(
      message: '${achievement.description}\n+${achievement.xp} XP',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: achievement.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: achievement.color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: achievement.color.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(achievement.icon, size: 15, color: achievement.color),
            const SizedBox(width: 6),
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: 12,
                color: achievement.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared dark card container ────────────────────────────────────────────

class _DarkCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;

  const _DarkCard({required this.child, this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor != null
              ? accentColor!.withOpacity(0.2)
              : _cardBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Shared section header row ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
