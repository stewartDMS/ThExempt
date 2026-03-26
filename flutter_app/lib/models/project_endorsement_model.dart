class ProjectEndorsement {
  final String id;
  final String projectId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String? message;
  final DateTime createdAt;

  ProjectEndorsement({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.message,
    required this.createdAt,
  });

  factory ProjectEndorsement.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return ProjectEndorsement(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: profiles?['username'] ?? json['user_name'] ?? 'Unknown',
      userAvatarUrl:
          profiles?['avatar_url'] as String? ?? json['user_avatar_url'] as String?,
      message: json['message'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'user_id': userId,
        if (message != null) 'message': message,
        'created_at': createdAt.toIso8601String(),
      };
}
