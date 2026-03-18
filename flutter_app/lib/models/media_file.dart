/// Represents a media file (image or video) attached to a discussion or project.
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
