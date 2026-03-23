/// Phase 1 — Expert badges & trust system
///
/// Dart models for [UserExpertise] and [ExpertVerification],
/// matching the user_expertise and expert_verifications tables.

enum ExpertiseLevel {
  selfDeclared('self_declared', 'Self-Declared'),
  communityVerified('community_verified', 'Community Verified'),
  expertVerified('expert_verified', 'Expert Verified'),
  platformVerified('platform_verified', 'Platform Verified');

  const ExpertiseLevel(this.value, this.label);
  final String value;
  final String label;

  static ExpertiseLevel fromValue(String value) {
    for (final level in ExpertiseLevel.values) {
      if (level.value == value) return level;
    }
    return ExpertiseLevel.selfDeclared;
  }
}

class UserExpertise {
  final String id;
  final String userId;
  final String area;
  final ExpertiseLevel level;
  final String? evidenceUrl;
  final bool isPrimary;
  final List<ExpertVerification> verifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserExpertise({
    required this.id,
    required this.userId,
    required this.area,
    required this.level,
    this.evidenceUrl,
    required this.isPrimary,
    this.verifications = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserExpertise.fromJson(Map<String, dynamic> json) {
    final rawVerifications =
        json['expert_verifications'] as List<dynamic>? ?? [];
    return UserExpertise(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      area: json['area'] as String,
      level: ExpertiseLevel.fromValue(json['level'] as String? ?? 'self_declared'),
      evidenceUrl: json['evidence_url'] as String?,
      isPrimary: json['is_primary'] == true,
      verifications: rawVerifications
          .map((v) => ExpertVerification.fromJson(v as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'area': area,
        'level': level.value,
        if (evidenceUrl != null) 'evidence_url': evidenceUrl,
        'is_primary': isPrimary,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

enum VerificationType {
  community('community', 'Community'),
  admin('admin', 'Admin'),
  credential('credential', 'Credential');

  const VerificationType(this.value, this.label);
  final String value;
  final String label;

  static VerificationType fromValue(String value) {
    for (final type in VerificationType.values) {
      if (type.value == value) return type;
    }
    return VerificationType.community;
  }
}

class ExpertVerification {
  final String id;
  final String userExpertiseId;
  final String? verifiedBy;
  final VerificationType verificationType;
  final String? notes;
  final DateTime createdAt;

  const ExpertVerification({
    required this.id,
    required this.userExpertiseId,
    this.verifiedBy,
    required this.verificationType,
    this.notes,
    required this.createdAt,
  });

  factory ExpertVerification.fromJson(Map<String, dynamic> json) {
    return ExpertVerification(
      id: json['id'] as String,
      userExpertiseId: json['user_expertise_id'] as String,
      verifiedBy: json['verified_by'] as String?,
      verificationType:
          VerificationType.fromValue(json['verification_type'] as String? ?? 'community'),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class UserBadges {
  final String userId;
  final List<String> badges;
  final int trustScore;

  const UserBadges({
    required this.userId,
    required this.badges,
    required this.trustScore,
  });

  factory UserBadges.fromJson(Map<String, dynamic> json) {
    return UserBadges(
      userId: json['user_id'] as String,
      badges: List<String>.from(json['badges'] as List? ?? []),
      trustScore: (json['trust_score'] as num?)?.toInt() ?? 0,
    );
  }
}
