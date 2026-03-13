import 'project_stage.dart';

class Project {
  final String id;
  final String title;
  final String description;
  final String ownerId;
  final String ownerName;
  final List<String> requiredSkills;
  final String status;
  final ProjectStage stage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? ownerAvatarUrl;
  final int totalRolesNeeded;
  final int rolesFilled;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.requiredSkills,
    required this.status,
    this.stage = ProjectStage.ideation,
    required this.createdAt,
    this.updatedAt,
    this.videoUrl,
    this.thumbnailUrl,
    this.ownerAvatarUrl,
    this.totalRolesNeeded = 0,
    this.rolesFilled = 0,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      ownerName: json['owner_name'] ?? json['profiles']?['name'] ?? 'Unknown',
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      status: json['status'] ?? 'open',
      stage: ProjectStage.fromString(json['stage'] ?? 'ideation'),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      ownerAvatarUrl: json['owner_avatar_url'] as String?,
      totalRolesNeeded: json['total_roles_needed'] ?? 0,
      rolesFilled: json['roles_filled'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'required_skills': requiredSkills,
      'status': status,
      'stage': stage.name,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (videoUrl != null) 'video_url': videoUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (ownerAvatarUrl != null) 'owner_avatar_url': ownerAvatarUrl,
      'total_roles_needed': totalRolesNeeded,
      'roles_filled': rolesFilled,
    };
  }
}
