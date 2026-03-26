/// Phase 2 — Skill Offer model
///
/// A user advertising their skill availability to projects and collaborators.
class SkillOffer {
  final String id;
  final String userId;
  final String? userName;
  final String? userAvatarUrl;
  final String? userLocation;
  final String title;
  final String description;
  final List<String> skillCategories;
  final int? rateCreditsPerHour;
  final bool equityPreferred;
  final int? availableHoursPerWeek;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SkillOffer({
    required this.id,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
    this.userLocation,
    required this.title,
    required this.description,
    required this.skillCategories,
    this.rateCreditsPerHour,
    this.equityPreferred = false,
    this.availableHoursPerWeek,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SkillOffer.fromJson(Map<String, dynamic> json) {
    // Handle nested profile join (profiles aliased as user_*)
    final profile = json['profiles'] as Map<String, dynamic>?;
    return SkillOffer(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: profile?['name'] as String? ?? json['user_name'] as String?,
      userAvatarUrl: profile?['avatar_url'] as String? ??
          json['user_avatar_url'] as String?,
      userLocation:
          profile?['location'] as String? ?? json['user_location'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      skillCategories:
          List<String>.from(json['skill_categories'] as List? ?? []),
      rateCreditsPerHour: json['rate_credits_per_hour'] as int?,
      equityPreferred: json['equity_preferred'] as bool? ?? false,
      availableHoursPerWeek: json['available_hours_per_week'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Phase 2 — Skill Request model
///
/// A project/user advertising a skill gap they need filled.
class SkillRequest {
  final String id;
  final String requesterId;
  final String? requesterName;
  final String? requesterAvatarUrl;
  final String? projectId;
  final String? projectTitle;
  final String title;
  final String description;
  final List<String> skillCategories;
  final int? budgetCredits;
  final double? equityOffered;
  final SkillRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SkillRequest({
    required this.id,
    required this.requesterId,
    this.requesterName,
    this.requesterAvatarUrl,
    this.projectId,
    this.projectTitle,
    required this.title,
    required this.description,
    required this.skillCategories,
    this.budgetCredits,
    this.equityOffered,
    this.status = SkillRequestStatus.open,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SkillRequest.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final project = json['projects'] as Map<String, dynamic>?;
    return SkillRequest(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      requesterName:
          profile?['name'] as String? ?? json['requester_name'] as String?,
      requesterAvatarUrl: profile?['avatar_url'] as String? ??
          json['requester_avatar_url'] as String?,
      projectId: json['project_id'] as String?,
      projectTitle:
          project?['title'] as String? ?? json['project_title'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      skillCategories:
          List<String>.from(json['skill_categories'] as List? ?? []),
      budgetCredits: json['budget_credits'] as int?,
      equityOffered: (json['equity_offered'] as num?)?.toDouble(),
      status: SkillRequestStatus.fromValue(
          json['status'] as String? ?? 'open'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

enum SkillRequestStatus {
  open('open', 'Open'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const SkillRequestStatus(this.value, this.label);
  final String value;
  final String label;

  static SkillRequestStatus fromValue(String value) =>
      SkillRequestStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => SkillRequestStatus.open,
      );
}
