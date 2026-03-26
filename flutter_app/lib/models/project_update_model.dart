class ProjectUpdate {
  final String id;
  final String projectId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String title;
  final String content;
  final ProjectUpdateType updateType;
  final bool isPinned;
  final int likesCount;
  final bool isLikedByUser;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectUpdate({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.title,
    required this.content,
    required this.updateType,
    this.isPinned = false,
    this.likesCount = 0,
    this.isLikedByUser = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectUpdate.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return ProjectUpdate(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: profiles?['username'] ?? 'Unknown',
      userAvatarUrl: profiles?['avatar_url'] as String?,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      updateType:
          ProjectUpdateType.fromValue(json['update_type'] as String? ?? 'general'),
      isPinned: json['is_pinned'] == true,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isLikedByUser: json['is_liked_by_user'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'user_id': userId,
        'title': title,
        'content': content,
        'update_type': updateType.value,
        'is_pinned': isPinned,
        'likes_count': likesCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

enum ProjectUpdateType {
  milestone('milestone', '🏁 Milestone', 'Milestone reached'),
  funding('funding', '💰 Funding', 'Funding update'),
  team('team', '👥 Team', 'Team update'),
  media('media', '📸 Media', 'New media added'),
  general('general', '📢 General', 'General announcement');

  const ProjectUpdateType(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;

  static ProjectUpdateType fromValue(String value) {
    for (final type in ProjectUpdateType.values) {
      if (type.value == value) return type;
    }
    return ProjectUpdateType.general;
  }
}
