/// Phase 1 — Resource library
///
/// Dart model for [DiscussionResource],
/// matching the discussion_resources table.

enum ResourceType {
  link('link', '🔗 Link'),
  document('document', '📄 Document'),
  video('video', '🎥 Video'),
  image('image', '🖼️ Image'),
  dataset('dataset', '📊 Dataset');

  const ResourceType(this.value, this.label);
  final String value;
  final String label;

  static ResourceType fromValue(String value) {
    for (final type in ResourceType.values) {
      if (type.value == value) return type;
    }
    return ResourceType.link;
  }
}

class DiscussionResource {
  final String id;
  final String discussionId;
  final String uploadedBy;
  final String? uploaderName;
  final String? uploaderAvatarUrl;
  final ResourceType resourceType;
  final String title;
  final String? description;
  final String? url;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final List<String> tags;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiscussionResource({
    required this.id,
    required this.discussionId,
    required this.uploadedBy,
    this.uploaderName,
    this.uploaderAvatarUrl,
    required this.resourceType,
    required this.title,
    this.description,
    this.url,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.tags = const [],
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiscussionResource.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return DiscussionResource(
      id: json['id'] as String,
      discussionId: json['discussion_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      uploaderName: profiles?['username'] as String?,
      uploaderAvatarUrl: profiles?['avatar_url'] as String?,
      resourceType: ResourceType.fromValue(json['resource_type'] as String? ?? 'link'),
      title: json['title'] as String,
      description: json['description'] as String?,
      url: json['url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      mimeType: json['mime_type'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      isFeatured: json['is_featured'] == true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'discussion_id': discussionId,
        'uploaded_by': uploadedBy,
        'resource_type': resourceType.value,
        'title': title,
        if (description != null) 'description': description,
        if (url != null) 'url': url,
        if (fileName != null) 'file_name': fileName,
        if (fileSize != null) 'file_size': fileSize,
        if (mimeType != null) 'mime_type': mimeType,
        'tags': tags,
        'is_featured': isFeatured,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
