import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AchievementType {
  firstTeamMember,
  fullTeam,
  firstMilestone,
  halfwayPoint,
  launched,
  hundredViews,
  thousandViews,
  tenThousandViews,
  tenLikes,
  fiftyLikes,
  firstApplication,
  tenApplications,
  weekStreak,
  monthStreak,
}

class Achievement {
  final AchievementType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int xp;
  final bool unlocked;
  final double progress; // 0.0 - 1.0

  const Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.xp,
    this.unlocked = false,
    this.progress = 0.0,
  });

  Achievement copyWith({bool? unlocked, double? progress}) {
    return Achievement(
      type: type,
      title: title,
      description: description,
      icon: icon,
      color: color,
      xp: xp,
      unlocked: unlocked ?? this.unlocked,
      progress: progress ?? this.progress,
    );
  }

  static const Map<AchievementType, Achievement> definitions = {
    AchievementType.firstTeamMember: Achievement(
      type: AchievementType.firstTeamMember,
      title: 'Team Player',
      description: 'Welcome your first team member',
      icon: Icons.person_add,
      color: Colors.blue,
      xp: 50,
    ),
    AchievementType.fullTeam: Achievement(
      type: AchievementType.fullTeam,
      title: 'Dream Team',
      description: 'Fill all open positions',
      icon: Icons.groups,
      color: Colors.green,
      xp: 200,
    ),
    AchievementType.firstMilestone: Achievement(
      type: AchievementType.firstMilestone,
      title: 'Milestone Maker',
      description: 'Complete your first milestone',
      icon: Icons.flag,
      color: AppColors.expertiseOperations,
      xp: 100,
    ),
    AchievementType.halfwayPoint: Achievement(
      type: AchievementType.halfwayPoint,
      title: 'Halfway There',
      description: 'Reach 50% task completion',
      icon: Icons.trending_up,
      color: AppColors.rebellionOrange,
      xp: 150,
    ),
    AchievementType.launched: Achievement(
      type: AchievementType.launched,
      title: 'Launched!',
      description: 'Move your project to the Launch stage',
      icon: Icons.rocket_launch,
      color: Colors.red,
      xp: 500,
    ),
    AchievementType.hundredViews: Achievement(
      type: AchievementType.hundredViews,
      title: '100 Views',
      description: 'Reach 100 project views',
      icon: Icons.visibility,
      color: AppColors.brightCyan,
      xp: 50,
    ),
    AchievementType.thousandViews: Achievement(
      type: AchievementType.thousandViews,
      title: '1K Views',
      description: 'Reach 1,000 project views',
      icon: Icons.visibility,
      color: AppColors.brightCyan,
      xp: 200,
    ),
    AchievementType.tenThousandViews: Achievement(
      type: AchievementType.tenThousandViews,
      title: '10K Views',
      description: 'Reach 10,000 project views',
      icon: Icons.star,
      color: Colors.amber,
      xp: 500,
    ),
    AchievementType.tenLikes: Achievement(
      type: AchievementType.tenLikes,
      title: '10 Likes',
      description: 'Receive 10 likes on your project',
      icon: Icons.thumb_up,
      color: AppColors.expertiseCreative,
      xp: 50,
    ),
    AchievementType.fiftyLikes: Achievement(
      type: AchievementType.fiftyLikes,
      title: '50 Likes',
      description: 'Receive 50 likes on your project',
      icon: Icons.favorite,
      color: AppColors.expertiseCreative,
      xp: 200,
    ),
    AchievementType.firstApplication: Achievement(
      type: AchievementType.firstApplication,
      title: 'First Applicant',
      description: 'Receive your first application',
      icon: Icons.inbox,
      color: AppColors.electricBlue,
      xp: 50,
    ),
    AchievementType.tenApplications: Achievement(
      type: AchievementType.tenApplications,
      title: 'Popular Project',
      description: 'Receive 10 applications',
      icon: Icons.inbox,
      color: AppColors.electricBlue,
      xp: 150,
    ),
    AchievementType.weekStreak: Achievement(
      type: AchievementType.weekStreak,
      title: 'Week Streak',
      description: 'Stay active for 7 days in a row',
      icon: Icons.local_fire_department,
      color: Colors.deepOrange,
      xp: 100,
    ),
    AchievementType.monthStreak: Achievement(
      type: AchievementType.monthStreak,
      title: 'Month Streak',
      description: 'Stay active for 30 days in a row',
      icon: Icons.local_fire_department,
      color: Colors.deepOrange,
      xp: 400,
    ),
  };

  /// Compute achievements with unlock state for a project.
  static List<Achievement> computeForProject({
    required int teamMemberCount,
    required int totalRolesNeeded,
    required int viewsCount,
    required int likesCount,
    required int applicationsCount,
    required int completedMilestones,
    required double taskProgress,
    required bool isLaunched,
    List<AchievementType> alreadyUnlocked = const [],
  }) {
    return definitions.entries.map((entry) {
      final def = entry.value;
      final type = entry.key;
      bool unlocked = alreadyUnlocked.contains(type);
      double progress = 0.0;

      switch (type) {
        case AchievementType.firstTeamMember:
          progress = (teamMemberCount >= 1) ? 1.0 : 0.0;
          unlocked = unlocked || teamMemberCount >= 1;
          break;
        case AchievementType.fullTeam:
          progress = totalRolesNeeded > 0
              ? (teamMemberCount / totalRolesNeeded).clamp(0.0, 1.0)
              : 0.0;
          unlocked = unlocked ||
              (totalRolesNeeded > 0 &&
                  teamMemberCount >= totalRolesNeeded);
          break;
        case AchievementType.firstMilestone:
          progress = completedMilestones >= 1 ? 1.0 : 0.0;
          unlocked = unlocked || completedMilestones >= 1;
          break;
        case AchievementType.halfwayPoint:
          progress = (taskProgress / 100).clamp(0.0, 1.0);
          unlocked = unlocked || taskProgress >= 50;
          break;
        case AchievementType.launched:
          progress = isLaunched ? 1.0 : 0.0;
          unlocked = unlocked || isLaunched;
          break;
        case AchievementType.hundredViews:
          progress = (viewsCount / 100).clamp(0.0, 1.0);
          unlocked = unlocked || viewsCount >= 100;
          break;
        case AchievementType.thousandViews:
          progress = (viewsCount / 1000).clamp(0.0, 1.0);
          unlocked = unlocked || viewsCount >= 1000;
          break;
        case AchievementType.tenThousandViews:
          progress = (viewsCount / 10000).clamp(0.0, 1.0);
          unlocked = unlocked || viewsCount >= 10000;
          break;
        case AchievementType.tenLikes:
          progress = (likesCount / 10).clamp(0.0, 1.0);
          unlocked = unlocked || likesCount >= 10;
          break;
        case AchievementType.fiftyLikes:
          progress = (likesCount / 50).clamp(0.0, 1.0);
          unlocked = unlocked || likesCount >= 50;
          break;
        case AchievementType.firstApplication:
          progress = applicationsCount >= 1 ? 1.0 : 0.0;
          unlocked = unlocked || applicationsCount >= 1;
          break;
        case AchievementType.tenApplications:
          progress = (applicationsCount / 10).clamp(0.0, 1.0);
          unlocked = unlocked || applicationsCount >= 10;
          break;
        case AchievementType.weekStreak:
        case AchievementType.monthStreak:
          // These require server-side streak data; keep as-is
          break;
      }

      return def.copyWith(unlocked: unlocked, progress: progress);
    }).toList();
  }
}

class ProjectLevel {
  final int level;
  final int currentXP;
  final int xpForNextLevel;

  const ProjectLevel({
    required this.level,
    required this.currentXP,
    required this.xpForNextLevel,
  });

  double get progress =>
      xpForNextLevel > 0 ? currentXP / xpForNextLevel : 0.0;

  static ProjectLevel calculate(int totalXP) {
    const xpPerLevel = 500;
    int level = (totalXP / xpPerLevel).floor() + 1;
    int currentXP = totalXP % xpPerLevel;
    return ProjectLevel(
      level: level,
      currentXP: currentXP,
      xpForNextLevel: xpPerLevel,
    );
  }
}
