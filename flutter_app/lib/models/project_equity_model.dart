class ProjectEquity {
  final String id;
  final String projectId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final double equityPercentage;
  final String? description;
  final DateTime grantedAt;

  ProjectEquity({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.equityPercentage,
    this.description,
    required this.grantedAt,
  });

  factory ProjectEquity.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return ProjectEquity(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: profiles?['username'] as String? ?? json['user_name'] as String? ?? 'Unknown',
      userAvatarUrl: profiles?['avatar_url'] as String? ?? json['user_avatar_url'] as String?,
      equityPercentage: (json['equity_percentage'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      grantedAt: json['granted_at'] != null
          ? DateTime.parse(json['granted_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'user_id': userId,
        'equity_percentage': equityPercentage,
        if (description != null) 'description': description,
        'granted_at': grantedAt.toIso8601String(),
      };
}
