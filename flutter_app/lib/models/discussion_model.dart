class MediaFile {
  final String id;
  final String mediaType; // 'image' or 'video'
  final String fileUrl;
  final String? thumbnailUrl;
  final String fileName;
  final int fileSize;
  final int? width;
  final int? height;
  final int? durationSeconds;
  final int displayOrder;

  MediaFile({
    required this.id,
    required this.mediaType,
    required this.fileUrl,
    this.thumbnailUrl,
    required this.fileName,
    required this.fileSize,
    this.width,
    this.height,
    this.durationSeconds,
    this.displayOrder = 0,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id']?.toString() ?? '',
      mediaType: json['media_type'] ?? 'image',
      fileUrl: json['file_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      fileName: json['file_name'] ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'media_type': mediaType,
    'file_url': fileUrl,
    if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
    'file_name': fileName,
    'file_size': fileSize,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (durationSeconds != null) 'duration_seconds': durationSeconds,
    'display_order': displayOrder,
  };

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
}

class Discussion {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String category;
  final String title;
  final String content;
  final List<String> tags;
  final String? imageUrl;
  final bool isPinned;
  final int likesCount;
  final int repliesCount;
  final int viewsCount;
  final bool isLikedByUser;
  final int mediaCount;
  final List<MediaFile> media;
  final DateTime createdAt;
  final DateTime updatedAt;

  Discussion({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.category,
    required this.title,
    required this.content,
    required this.tags,
    this.imageUrl,
    required this.isPinned,
    required this.likesCount,
    required this.repliesCount,
    required this.viewsCount,
    required this.isLikedByUser,
    this.mediaCount = 0,
    this.media = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Discussion.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    List<MediaFile> mediaList = [];
    if (json['media'] != null && json['media'] is List) {
      mediaList = (json['media'] as List)
          .map((m) => MediaFile.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    return Discussion(
      id: json['id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      authorName: profiles?['name'] ?? 'Unknown',
      authorAvatarUrl: profiles?['avatar_url'] as String?,
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['image_url'] as String?,
      isPinned: json['is_pinned'] == true,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      repliesCount: (json['replies_count'] as num?)?.toInt() ?? 0,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      isLikedByUser: json['is_liked_by_user'] == true,
      mediaCount: (json['media_count'] as num?)?.toInt() ?? 0,
      media: mediaList,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author_id': authorId,
    'category': category,
    'title': title,
    'content': content,
    'tags': tags,
    if (imageUrl != null) 'image_url': imageUrl,
    'is_pinned': isPinned,
    'likes_count': likesCount,
    'replies_count': repliesCount,
    'views_count': viewsCount,
    'is_liked_by_user': isLikedByUser,
    'media_count': mediaCount,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  bool get hasMedia => media.isNotEmpty;
  List<MediaFile> get images => media.where((m) => m.isImage).toList();
  List<MediaFile> get videos => media.where((m) => m.isVideo).toList();

  Discussion copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    String? category,
    String? title,
    String? content,
    List<String>? tags,
    String? imageUrl,
    bool? isPinned,
    int? likesCount,
    int? repliesCount,
    int? viewsCount,
    bool? isLikedByUser,
    int? mediaCount,
    List<MediaFile>? media,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Discussion(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      isPinned: isPinned ?? this.isPinned,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      mediaCount: mediaCount ?? this.mediaCount,
      media: media ?? this.media,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DiscussionReply {
  final String id;
  final String discussionId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String? parentReplyId;
  final String content;
  final int likesCount;
  final bool isLikedByUser;
  final DateTime createdAt;
  final List<DiscussionReply> replies;

  DiscussionReply({
    required this.id,
    required this.discussionId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.parentReplyId,
    required this.content,
    required this.likesCount,
    required this.isLikedByUser,
    required this.createdAt,
    this.replies = const [],
  });

  factory DiscussionReply.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return DiscussionReply(
      id: json['id']?.toString() ?? '',
      discussionId: json['discussion_id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      authorName: profiles?['name'] ?? 'Unknown',
      authorAvatarUrl: profiles?['avatar_url'] as String?,
      parentReplyId: json['parent_reply_id'] as String?,
      content: json['content'] ?? '',
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isLikedByUser: json['is_liked_by_user'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((r) => DiscussionReply.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  DiscussionReply copyWith({
    int? likesCount,
    bool? isLikedByUser,
    List<DiscussionReply>? replies,
  }) {
    return DiscussionReply(
      id: id,
      discussionId: discussionId,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      parentReplyId: parentReplyId,
      content: content,
      likesCount: likesCount ?? this.likesCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      createdAt: createdAt,
      replies: replies ?? this.replies,
    );
  }
}

enum DiscussionCategory {
  worldProblems('world_problems', '🌍 World Problems', 'Discuss global challenges to solve'),
  ideas('ideas', '💡 Ideas & Brainstorming', 'Share startup ideas, get feedback'),
  learning('learning', '🎓 Learning & Resources', 'Share knowledge, tutorials'),
  liveEvents('live_events', '🎤 Live Events', 'Upcoming training, workshops, AMAs'),
  networking('networking', '🤝 Networking', 'Introductions, looking for co-founders'),
  general('general', '💬 General', 'Off-topic, community chat'),
  feedback('feedback', '🐛 Feedback', 'Platform suggestions, bug reports');

  const DiscussionCategory(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;

  static DiscussionCategory? fromValue(String value) {
    for (final cat in DiscussionCategory.values) {
      if (cat.value == value) return cat;
    }
    return null;
  }
}
