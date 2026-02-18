import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../../services/video_service.dart';

class VideoPickerWidget extends StatefulWidget {
  final Function(html.File, String, String) onVideoSelected;
  final VoidCallback? onVideoRemoved;

  const VideoPickerWidget({
    super.key,
    required this.onVideoSelected,
    this.onVideoRemoved,
  });

  @override
  State<VideoPickerWidget> createState() => _VideoPickerWidgetState();
}

class _VideoPickerWidgetState extends State<VideoPickerWidget> {
  html.File? _selectedFile;
  String? _videoBase64;
  String? _thumbnailBase64;
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _pickVideo() async {
    final input = html.FileUploadInputElement()..accept = 'video/*';
    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];

        // Validate file
        final error = VideoService.validateVideoFile(file);
        if (error != null) {
          setState(() {
            _errorMessage = error;
            _selectedFile = null;
            _videoBase64 = null;
            _thumbnailBase64 = null;
          });
          return;
        }

        setState(() {
          _isProcessing = true;
          _errorMessage = null;
        });

        try {
          // Convert to base64
          final base64Video = await VideoService.fileToBase64(file);

          // Create video element to extract thumbnail
          final videoElement = html.VideoElement()
            ..src = html.Url.createObjectUrlFromBlob(file)
            ..crossOrigin = 'anonymous';

          // Wait for video to load
          await videoElement.onLoadedMetadata.first;

          // Seek to 1 second or 10% of video duration (whichever is less)
          final seekTime = videoElement.duration > 10 ? 1.0 : videoElement.duration * 0.1;
          videoElement.currentTime = seekTime;

          // Wait for seek to complete
          await videoElement.onSeeked.first;

          // Extract thumbnail
          final thumbnailBase64 = await VideoService.extractThumbnail(videoElement);

          setState(() {
            _selectedFile = file;
            _videoBase64 = base64Video;
            _thumbnailBase64 = thumbnailBase64;
            _isProcessing = false;
          });

          // Notify parent
          widget.onVideoSelected(file, base64Video, thumbnailBase64);
        } catch (e) {
          setState(() {
            _errorMessage = 'Failed to process video: $e';
            _isProcessing = false;
          });
        }
      }
    });
  }

  void _removeVideo() {
    setState(() {
      _selectedFile = null;
      _videoBase64 = null;
      _thumbnailBase64 = null;
      _errorMessage = null;
    });
    widget.onVideoRemoved?.call();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFile == null) ...[
          // Upload button
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _pickVideo,
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.video_library),
            label: Text(_isProcessing ? 'Processing...' : 'Upload Video (Optional)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Max ${VideoService.maxVideoSizeMB}MB • MP4, WebM, MOV',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ] else ...[
          // Video preview card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Thumbnail preview
                if (_thumbnailBase64 != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _thumbnailBase64!,
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.videocam, color: Colors.grey),
                  ),
                const SizedBox(width: 12),

                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFile!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFileSize(_selectedFile!.size),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Remove button
                IconButton(
                  onPressed: _removeVideo,
                  icon: const Icon(Icons.close),
                  color: Colors.red,
                  tooltip: 'Remove video',
                ),
              ],
            ),
          ),
        ],

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
