class ProjectContribution {
  final String id;
  final String projectId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String contributionType;
  final int amount;
  final String description;
  final DateTime createdAt;

  ProjectContribution({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.contributionType,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory ProjectContribution.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return ProjectContribution(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: profiles?['username'] as String? ?? json['user_name'] as String? ?? 'Unknown',
      userAvatarUrl: profiles?['avatar_url'] as String? ?? json['user_avatar_url'] as String?,
      contributionType: json['contribution_type'] as String? ?? 'credits',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'user_id': userId,
        'contribution_type': contributionType,
        'amount': amount,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };
}
