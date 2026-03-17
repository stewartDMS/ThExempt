enum ActivityType {
  taskCompleted,
  taskCreated,
  commentAdded,
  memberJoined,
  memberLeft,
  milestoneCompleted,
  documentUploaded,
  applicationReceived,
  engagementMilestone,
  projectUpdated,
}

class ActivityItem {
  final String id;
  final ActivityType type;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityItem({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.message,
    required this.timestamp,
    this.metadata,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id']?.toString() ?? '',
      type: ActivityType.values.firstWhere(
        (t) => t.name == (json['type'] ?? 'projectUpdated'),
        orElse: () => ActivityType.projectUpdated,
      ),
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] ?? 'Unknown',
      userAvatar: json['user_avatar'] as String?,
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  String get typeEmoji {
    switch (type) {
      case ActivityType.taskCompleted:
        return '✅';
      case ActivityType.taskCreated:
        return '📋';
      case ActivityType.commentAdded:
        return '💬';
      case ActivityType.memberJoined:
        return '👋';
      case ActivityType.memberLeft:
        return '👋';
      case ActivityType.milestoneCompleted:
        return '🏆';
      case ActivityType.documentUploaded:
        return '📄';
      case ActivityType.applicationReceived:
        return '📩';
      case ActivityType.engagementMilestone:
        return '🎉';
      case ActivityType.projectUpdated:
        return '🔄';
    }
  }
}
