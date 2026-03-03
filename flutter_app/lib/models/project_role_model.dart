class ProjectRole {
  final String id;
  final String projectId;
  final String roleCategory;
  final String roleTitle;
  final String? description;
  final List<String> skillsRequired;
  final bool isFilled;
  final String? filledBy;
  final int displayOrder;
  final DateTime createdAt;

  ProjectRole({
    required this.id,
    required this.projectId,
    required this.roleCategory,
    required this.roleTitle,
    this.description,
    required this.skillsRequired,
    required this.isFilled,
    this.filledBy,
    required this.displayOrder,
    required this.createdAt,
  });

  factory ProjectRole.fromJson(Map<String, dynamic> json) {
    return ProjectRole(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      roleCategory: json['role_category'] ?? '',
      roleTitle: json['role_title'] ?? '',
      description: json['description'] as String?,
      skillsRequired: List<String>.from(json['skills_required'] ?? []),
      isFilled: json['is_filled'] == true,
      filledBy: json['filled_by'] as String?,
      displayOrder: json['display_order'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'role_category': roleCategory,
      'role_title': roleTitle,
      if (description != null) 'description': description,
      'skills_required': skillsRequired,
      'is_filled': isFilled,
      if (filledBy != null) 'filled_by': filledBy,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProjectRole copyWith({
    String? roleCategory,
    String? roleTitle,
    String? description,
    List<String>? skillsRequired,
    bool? isFilled,
    String? filledBy,
    int? displayOrder,
  }) {
    return ProjectRole(
      id: id,
      projectId: projectId,
      roleCategory: roleCategory ?? this.roleCategory,
      roleTitle: roleTitle ?? this.roleTitle,
      description: description ?? this.description,
      skillsRequired: skillsRequired ?? this.skillsRequired,
      isFilled: isFilled ?? this.isFilled,
      filledBy: filledBy ?? this.filledBy,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt,
    );
  }
}
