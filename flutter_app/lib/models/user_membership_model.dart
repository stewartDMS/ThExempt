class UserMembership {
  final String id;
  final String userId;
  final String tierId;
  final String tierName;
  final String tierSlug;
  final String status;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  UserMembership({
    required this.id,
    required this.userId,
    required this.tierId,
    required this.tierName,
    required this.tierSlug,
    required this.status,
    required this.startedAt,
    this.expiresAt,
    required this.createdAt,
  });

  factory UserMembership.fromJson(Map<String, dynamic> json) {
    final tier = json['membership_tiers'] as Map<String, dynamic>?;
    return UserMembership(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      tierId: json['tier_id']?.toString() ?? '',
      tierName: tier?['name'] as String? ?? '',
      tierSlug: tier?['slug'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'tier_id': tierId,
        'status': status,
        'started_at': startedAt.toIso8601String(),
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  bool get isActive => status == 'active';
}
