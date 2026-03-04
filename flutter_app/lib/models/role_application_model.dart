class RoleApplication {
  final String id;
  final String projectId;
  final String roleId;
  final String? userId;
  final String message;
  final int matchScore;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // For "my applications" view
  final String? projectTitle;
  final String? roleTitle;
  final String? roleCategory;

  // For "inbox" view
  final String? applicantName;
  final String? applicantAvatarUrl;
  final String? applicantId;
  final int reputationPoints;

  RoleApplication({
    required this.id,
    required this.projectId,
    required this.roleId,
    this.userId,
    required this.message,
    required this.matchScore,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.projectTitle,
    this.roleTitle,
    this.roleCategory,
    this.applicantName,
    this.applicantAvatarUrl,
    this.applicantId,
    this.reputationPoints = 0,
  });

  factory RoleApplication.fromJson(Map<String, dynamic> json) {
    return RoleApplication(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      roleId: json['role_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      message: json['message'] ?? '',
      matchScore: json['match_score'] ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      projectTitle: json['project_title'] as String?,
      roleTitle: json['role_title'] as String?,
      roleCategory: json['role_category'] as String?,
      applicantName: json['applicant_name'] as String?,
      applicantAvatarUrl: json['applicant_avatar_url'] as String?,
      applicantId: json['applicant_id']?.toString(),
      reputationPoints: json['reputation_points'] ?? 0,
    );
  }
}

class RoleApplicationGroup {
  final String roleId;
  final String roleTitle;
  final String roleCategory;
  final List<String> skillsRequired;
  final List<RoleApplication> applications;

  RoleApplicationGroup({
    required this.roleId,
    required this.roleTitle,
    required this.roleCategory,
    required this.skillsRequired,
    required this.applications,
  });

  factory RoleApplicationGroup.fromJson(Map<String, dynamic> json) {
    return RoleApplicationGroup(
      roleId: json['role_id']?.toString() ?? '',
      roleTitle: json['role_title'] ?? '',
      roleCategory: json['role_category'] ?? '',
      skillsRequired: List<String>.from(json['skills_required'] ?? []),
      applications: (json['applications'] as List<dynamic>? ?? [])
          .map((a) => RoleApplication.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
