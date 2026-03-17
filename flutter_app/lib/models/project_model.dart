import 'project_stage.dart';

class Project {
  final String id;
  final String title;
  final String description;
  final String ownerId;
  final String ownerName;
  final List<String> requiredSkills;
  final String status;
  final ProjectStage stage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? ownerAvatarUrl;
  final int totalRolesNeeded;
  final int rolesFilled;

  /// Engagement metrics – populated from the database when available.
  final int? viewsCount;
  final int? likesCount;
  final int? applicationsCount;

  // --- Extended tracking fields ---
  /// Total number of tasks for health-score calculation.
  final int? totalTasks;

  /// Number of completed tasks.
  final int? completedTasks;

  /// Number of tasks past their due date.
  final int? overdueTasks;

  /// Task completion as a percentage (0–100).
  final double? taskProgress;

  /// How many days the project is behind schedule (negative = ahead).
  final int? daysDelayed;

  /// Week-over-week views growth as a percentage.
  final double? viewsTrend;

  /// Days since the last team activity was recorded.
  final int? daysSinceLastActivity;

  /// Total XP accumulated by the project (used for gamification level).
  final int totalXP;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.requiredSkills,
    required this.status,
    this.stage = ProjectStage.ideation,
    required this.createdAt,
    this.updatedAt,
    this.videoUrl,
    this.thumbnailUrl,
    this.ownerAvatarUrl,
    this.totalRolesNeeded = 0,
    this.rolesFilled = 0,
    this.viewsCount,
    this.likesCount,
    this.applicationsCount,
    this.totalTasks,
    this.completedTasks,
    this.overdueTasks,
    this.taskProgress,
    this.daysDelayed,
    this.viewsTrend,
    this.daysSinceLastActivity,
    this.totalXP = 0,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      ownerName: json['owner_name'] ?? json['profiles']?['name'] ?? 'Unknown',
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      status: json['status'] ?? 'open',
      stage: ProjectStage.fromString(json['stage'] ?? 'ideation'),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      ownerAvatarUrl: json['owner_avatar_url'] as String?,
      totalRolesNeeded: json['total_roles_needed'] ?? 0,
      rolesFilled: json['roles_filled'] ?? 0,
      viewsCount: (json['views_count'] as num?)?.toInt(),
      likesCount: (json['likes_count'] as num?)?.toInt(),
      applicationsCount: (json['applications_count'] as num?)?.toInt(),
      totalTasks: (json['total_tasks'] as num?)?.toInt(),
      completedTasks: (json['completed_tasks'] as num?)?.toInt(),
      overdueTasks: (json['overdue_tasks'] as num?)?.toInt(),
      taskProgress: (json['task_progress'] as num?)?.toDouble(),
      daysDelayed: (json['days_delayed'] as num?)?.toInt(),
      viewsTrend: (json['views_trend'] as num?)?.toDouble(),
      daysSinceLastActivity:
          (json['days_since_last_activity'] as num?)?.toInt(),
      totalXP: (json['total_xp'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'required_skills': requiredSkills,
      'status': status,
      'stage': stage.name,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (videoUrl != null) 'video_url': videoUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (ownerAvatarUrl != null) 'owner_avatar_url': ownerAvatarUrl,
      'total_roles_needed': totalRolesNeeded,
      'roles_filled': rolesFilled,
      if (viewsCount != null) 'views_count': viewsCount,
      if (likesCount != null) 'likes_count': likesCount,
      if (applicationsCount != null) 'applications_count': applicationsCount,
      if (totalTasks != null) 'total_tasks': totalTasks,
      if (completedTasks != null) 'completed_tasks': completedTasks,
      if (overdueTasks != null) 'overdue_tasks': overdueTasks,
      if (taskProgress != null) 'task_progress': taskProgress,
      if (daysDelayed != null) 'days_delayed': daysDelayed,
      if (viewsTrend != null) 'views_trend': viewsTrend,
      if (daysSinceLastActivity != null)
        'days_since_last_activity': daysSinceLastActivity,
      'total_xp': totalXP,
    };
  }
}
