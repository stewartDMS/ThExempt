import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VideoService {
  static const String apiUrl = 'http://localhost:5000/api';
  static const int maxVideoSizeMB = 50;
  static const int maxVideoSizeBytes = maxVideoSizeMB * 1024 * 1024;

  // Convert file to base64
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

  // Upload video to project
  static Future<Map<String, String>> uploadVideo({
    required String projectId,
    required String base64Video,
    required String fileName,
    required String thumbnailBase64,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$apiUrl/projects/$projectId/video'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'base64Video': base64Video,
          'fileName': fileName,
          'thumbnailBase64': thumbnailBase64,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'videoUrl': data['video_url'] ?? '',
          'thumbnailUrl': data['thumbnail_url'] ?? '',
        };
      } else {
        throw Exception('Failed to upload video: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  // Validate video file
  static String? validateVideoFile(html.File file) {
    // Check file size
    if (file.size > maxVideoSizeBytes) {
      return 'Video file size must be less than ${maxVideoSizeMB}MB';
    }

    // Check file type
    final validTypes = ['video/mp4', 'video/webm', 'video/quicktime'];
    if (!validTypes.contains(file.type)) {
      return 'Only MP4, WebM, and MOV video formats are supported';
    }

    return null; // No error
  }
}
