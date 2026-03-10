import 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/base64_utils.dart';

class VideoService {
  static final _supabase = Supabase.instance.client;
  static const int maxVideoSizeMB = 50;
  static const int maxVideoSizeBytes = maxVideoSizeMB * 1024 * 1024;

  // Convert file to base64 data URL
  static Future<String> fileToBase64(html.File file) async {
    final reader = html.FileReader();
    reader.readAsDataUrl(file);

    await reader.onLoad.first;
    return reader.result as String;
  }

  // Extract thumbnail from video element
  static Future<String> extractThumbnail(html.VideoElement videoElement) async {
    final canvas = html.CanvasElement();
    canvas.width = videoElement.videoWidth;
    canvas.height = videoElement.videoHeight;

    final context = canvas.getContext('2d') as html.CanvasRenderingContext2D;
    context.drawImage(videoElement, 0, 0);

    // Return thumbnail as base64 JPEG with 0.8 quality
    return canvas.toDataUrl('image/jpeg', 0.8);
  }

  // Upload video to Supabase Storage and link it to the project
  static Future<Map<String, String>> uploadVideo({
    required String projectId,
    required String base64Video,
    required String fileName,
    required String thumbnailBase64,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final videoBytes = base64DataUrlToBytes(base64Video);
    final thumbnailBytes = base64DataUrlToBytes(thumbnailBase64);

    final videoPath = '$userId/$projectId/$fileName';
    final thumbnailPath = '$userId/$projectId/thumbnail.jpg';

    await _supabase.storage.from('project-videos').uploadBinary(
          videoPath,
          videoBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    await _supabase.storage.from('project-thumbnails').uploadBinary(
          thumbnailPath,
          thumbnailBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final videoUrl =
        _supabase.storage.from('project-videos').getPublicUrl(videoPath);
    final thumbnailUrl = _supabase.storage
        .from('project-thumbnails')
        .getPublicUrl(thumbnailPath);

    // Update the project record with the video and thumbnail URLs
    await _supabase
        .from('projects')
        .update({'video_url': videoUrl, 'thumbnail_url': thumbnailUrl})
        .eq('id', projectId);

    return {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  // Validate video file
  static String? validateVideoFile(html.File file) {
    if (file.size > maxVideoSizeBytes) {
      return 'Video file size must be less than ${maxVideoSizeMB}MB';
    }

    final validTypes = ['video/mp4', 'video/webm', 'video/quicktime'];
    if (!validTypes.contains(file.type)) {
      return 'Only MP4, WebM, and MOV video formats are supported';
    }

    return null;
  }
}
