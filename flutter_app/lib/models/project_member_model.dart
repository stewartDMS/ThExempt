class ProjectMember {
  final String id;
  final String projectId;
  final String userId;
  final String? roleId;
  final String roleTitle;
  final String roleCategory;
  final DateTime joinedAt;
  final String name;
  final String? avatarUrl;
  final String? bio;

  ProjectMember({
    required this.id,
    required this.projectId,
    required this.userId,
    this.roleId,
    required this.roleTitle,
    required this.roleCategory,
    required this.joinedAt,
    required this.name,
    this.avatarUrl,
    this.bio,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      roleId: json['role_id']?.toString(),
      roleTitle: json['role_title'] ?? '',
      roleCategory: json['role_category'] ?? '',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
      name: json['name'] ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
    );
  }
}
