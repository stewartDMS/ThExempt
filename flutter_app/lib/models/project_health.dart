import 'package:flutter/material.dart';
import 'project_model.dart';

class HealthWarning {
  final WarningSeverity severity;
  final String message;
  final String action;

  HealthWarning({
    required this.severity,
    required this.message,
    required this.action,
  });
}

enum WarningSeverity { critical, high, medium, low }

class HealthRecommendation {
  final IconData icon;
  final String message;
  final String action;

  HealthRecommendation({
    required this.icon,
    required this.message,
    required this.action,
  });
}

class ProjectHealth {
  final double overallScore; // 0-100
  final double teamScore;
  final double taskScore;
  final double timelineScore;
  final double engagementScore;
  final double activityScore;
  final List<HealthWarning> warnings;
  final List<HealthRecommendation> recommendations;

  ProjectHealth({
    required this.overallScore,
    required this.teamScore,
    required this.taskScore,
    required this.timelineScore,
    required this.engagementScore,
    required this.activityScore,
    required this.warnings,
    required this.recommendations,
  });

  static ProjectHealth calculate(Project project) {
    double teamScore = _calculateTeamScore(project);
    double taskScore = _calculateTaskScore(project);
    double timelineScore = _calculateTimelineScore(project);
    double engagementScore = _calculateEngagementScore(project);
    double activityScore = _calculateActivityScore(project);

    double overall = teamScore * 0.25 +
        taskScore * 0.25 +
        timelineScore * 0.20 +
        engagementScore * 0.15 +
        activityScore * 0.15;

    return ProjectHealth(
      overallScore: overall.clamp(0, 100),
      teamScore: teamScore,
      taskScore: taskScore,
      timelineScore: timelineScore,
      engagementScore: engagementScore,
      activityScore: activityScore,
      warnings: _generateWarnings(project, overall),
      recommendations: _generateRecommendations(project, overall),
    );
  }

  static double _calculateTeamScore(Project project) {
    if (project.totalRolesNeeded == 0) return 100;
    return (project.rolesFilled / project.totalRolesNeeded) * 100;
  }

  static double _calculateTaskScore(Project project) {
    final total = project.totalTasks ?? 0;
    final completed = project.completedTasks ?? 0;
    if (total == 0) return 100;
    return (completed / total) * 100;
  }

  static double _calculateTimelineScore(Project project) {
    int daysLate = project.daysDelayed ?? 0;
    if (daysLate <= 0) return 100;
    if (daysLate <= 7) return 75;
    if (daysLate <= 14) return 50;
    return 25;
  }

  static double _calculateEngagementScore(Project project) {
    double trend = project.viewsTrend ?? 0;
    if (trend >= 10) return 100;
    if (trend >= 0) return 75;
    if (trend >= -10) return 50;
    return 25;
  }

  static double _calculateActivityScore(Project project) {
    int days = project.daysSinceLastActivity ?? 0;
    if (days == 0) return 100;
    if (days <= 1) return 90;
    if (days <= 3) return 75;
    if (days <= 7) return 50;
    return 25;
  }

  static List<HealthWarning> _generateWarnings(
      Project project, double score) {
    final warnings = <HealthWarning>[];

    if (score < 50) {
      warnings.add(HealthWarning(
        severity: WarningSeverity.critical,
        message: 'Project health is critical',
        action: 'Review all metrics and take immediate action',
      ));
    }

    final overdueTasks = project.overdueTasks ?? 0;
    if (overdueTasks > 0) {
      warnings.add(HealthWarning(
        severity: WarningSeverity.high,
        message: '$overdueTasks tasks are overdue',
        action: 'Review and reassign overdue tasks',
      ));
    }

    final daysSinceActivity = project.daysSinceLastActivity;
    if (daysSinceActivity != null && daysSinceActivity > 7) {
      warnings.add(HealthWarning(
        severity: WarningSeverity.medium,
        message: 'No team activity in $daysSinceActivity days',
        action: 'Schedule a team sync meeting',
      ));
    }

    final openRoles =
        project.totalRolesNeeded - project.rolesFilled;
    if (openRoles > 3) {
      warnings.add(HealthWarning(
        severity: WarningSeverity.medium,
        message: '$openRoles positions still unfilled',
        action: 'Share project on social media',
      ));
    }

    return warnings;
  }

  static List<HealthRecommendation> _generateRecommendations(
      Project project, double score) {
    final recs = <HealthRecommendation>[];

    final viewsTrend = project.viewsTrend;
    if (viewsTrend != null && viewsTrend > 15) {
      recs.add(HealthRecommendation(
        icon: Icons.trending_up,
        message: 'Your project has high engagement!',
        action: 'Post an update to maintain interest',
      ));
    }

    final taskProgress = project.taskProgress;
    if (taskProgress != null && taskProgress > 50) {
      recs.add(HealthRecommendation(
        icon: Icons.rocket_launch,
        message:
            'Development is ${taskProgress.toStringAsFixed(0)}% complete',
        action: 'Consider planning launch strategy',
      ));
    }

    final applications = project.applicationsCount ?? 0;
    if (applications > 10) {
      recs.add(HealthRecommendation(
        icon: Icons.people,
        message: 'You have $applications applications',
        action: 'Review and respond to candidates',
      ));
    }

    return recs;
  }

  Color get scoreColor {
    if (overallScore >= 80) return Colors.green;
    if (overallScore >= 60) return Colors.orange;
    return Colors.red;
  }

  String get scoreLabel {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 75) return 'Good';
    if (overallScore >= 60) return 'Fair';
    if (overallScore >= 40) return 'Poor';
    return 'Critical';
  }
}
