class ProjectInvestment {
  final String id;
  final String projectId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int creditsAmount;
  final String? message;
  final DateTime createdAt;

  ProjectInvestment({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.creditsAmount,
    this.message,
    required this.createdAt,
  });

  factory ProjectInvestment.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return ProjectInvestment(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: profiles?['username'] as String? ?? json['user_name'] as String? ?? 'Unknown',
      userAvatarUrl: profiles?['avatar_url'] as String? ?? json['user_avatar_url'] as String?,
      creditsAmount: (json['credits_amount'] as num?)?.toInt() ?? 0,
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
        'credits_amount': creditsAmount,
        if (message != null) 'message': message,
        'created_at': createdAt.toIso8601String(),
      };
}
