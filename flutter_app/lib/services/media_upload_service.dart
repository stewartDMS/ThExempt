import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles picking and uploading images/videos for discussion posts.
///
/// Files are uploaded to the `discussion-media` Supabase Storage bucket and
/// a record is inserted into the `discussion_media` table.
class MediaUploadService {
  static final _supabase = Supabase.instance.client;
  static final _picker = ImagePicker();

  /// Maximum number of media files per discussion.
  static const int maxFiles = 5;

  /// Maximum image file size in bytes (10 MB).
  static const int maxImageBytes = 10 * 1024 * 1024;

  /// Maximum video file size in bytes (100 MB).
  static const int maxVideoBytes = 100 * 1024 * 1024;

  // ── Picking ──────────────────────────────────────────────────────────────

  /// Opens the image picker and returns up to [limit] selected images.
  static Future<List<XFile>> pickImages({int limit = maxFiles}) async {
    final picked = await _picker.pickMultiImage();
    if (picked.length > limit) {
      throw Exception('Select at most $limit image${limit == 1 ? '' : 's'}');
    }
    return picked;
  }

  /// Opens the gallery video picker and returns the selected video, or null
  /// if the user cancelled.
  static Future<XFile?> pickVideo() async {
    return _picker.pickVideo(source: ImageSource.gallery);
  }

  // ── File type detection ───────────────────────────────────────────────────

  static const _videoMimeTypes = {
    'video/mp4', 'video/quicktime', 'video/webm',
    'video/x-msvideo', 'video/x-matroska',
  };
  static const _videoExtensions = {'.mp4', '.mov', '.webm', '.avi', '.mkv'};

  /// Returns true when [file] is a video, using MIME type first then extension.
  static bool isVideoFile(XFile file) {
    final mime = file.mimeType?.toLowerCase();
    if (mime != null && mime.isNotEmpty) {
      return _videoMimeTypes.contains(mime);
    }
    final ext = '.${file.name.split('.').last.toLowerCase()}';
    return _videoExtensions.contains(ext);
  }

  // ── Uploading ─────────────────────────────────────────────────────────────

  /// Uploads [file] to Supabase Storage under the `discussion-media` bucket.
  ///
  /// Returns a record with the public [fileUrl] and the [fileSize] in bytes.
  /// Pass [isVideo] = true for video files (different size limit applies).
  static Future<({String fileUrl, int fileSize})> uploadFile(
    XFile file, {
    required bool isVideo,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final bytes = await file.readAsBytes();
    final fileSize = bytes.length;
    final maxBytes = isVideo ? maxVideoBytes : maxImageBytes;

    if (fileSize > maxBytes) {
      final limit = isVideo ? '100 MB' : '10 MB';
      throw Exception(
        '${isVideo ? 'Video' : 'Image'} must be less than $limit '
        '(file is ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB)',
      );
    }

    final subfolder = isVideo ? 'videos' : 'images';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final baseName = file.name.isNotEmpty ? file.name : 'media';
    final filePath = '$userId/$subfolder/${timestamp}_$baseName';

    // Resolve MIME type: prefer XFile.mimeType, then look up by file extension,
    // then fall back to a generic type.  The mime package covers all common
    // image/video extensions, so the fallback is only reached for unknown types.
    final mimeType = (file.mimeType?.isNotEmpty == true ? file.mimeType : null)
        ?? lookupMimeType(file.name)
        ?? (isVideo ? 'video/mp4' : 'image/jpeg');

    await _supabase.storage.from('discussion-media').uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: false,
          ),
        );

    final fileUrl = _supabase.storage
        .from('discussion-media')
        .getPublicUrl(filePath);

    return (fileUrl: fileUrl, fileSize: fileSize);
  }

  // ── Database ──────────────────────────────────────────────────────────────

  /// Inserts a `discussion_media` record after a successful upload.
  static Future<void> insertMediaRecord({
    required String discussionId,
    required String mediaType,
    required String fileUrl,
    String? thumbnailUrl,
    required String fileName,
    required int fileSize,
    int? width,
    int? height,
    int? durationSeconds,
    required int displayOrder,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('discussion_media').insert({
      'discussion_id': discussionId,
      'media_type': mediaType,
      'file_url': fileUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      'file_name': fileName,
      'file_size': fileSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      'uploaded_by': userId,
      'display_order': displayOrder,
    });
  }

  /// Deletes a `discussion_media` record from the database.
  ///
  /// Note: this does not remove the associated file from Storage.
  /// Orphaned storage files should be cleaned up by a separate process or
  /// a Supabase storage lifecycle policy.
  static Future<void> deleteMediaRecord(String mediaId) async {
    await _supabase.from('discussion_media').delete().eq('id', mediaId);
  }
}
