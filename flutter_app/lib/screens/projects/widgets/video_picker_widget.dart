import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../../services/video_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

const _kInputFill = Color(0xFF252528);
const _kBorder = Color(0xFF3A3A3C);
const _kTextPrimary = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

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
      if (files == null || files.isEmpty) return;

      final file = files[0];
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
        final base64Video = await VideoService.fileToBase64(file);

        final videoElement = html.VideoElement()
          ..src = html.Url.createObjectUrlFromBlob(file)
          ..crossOrigin = 'anonymous';

        await videoElement.onLoadedMetadata.first;

        final seekTime = videoElement.duration > 10
            ? 1.0
            : videoElement.duration * 0.1;
        videoElement.currentTime = seekTime;

        await videoElement.onSeeked.first;

        final thumbnailBase64 =
            await VideoService.extractThumbnail(videoElement);

        setState(() {
          _selectedFile = file;
          _videoBase64 = base64Video;
          _thumbnailBase64 = thumbnailBase64;
          _isProcessing = false;
        });

        widget.onVideoSelected(file, base64Video, thumbnailBase64);
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to process video: $e';
          _isProcessing = false;
        });
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
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFile == null) ...[
          _buildDropZone(),
        ] else ...[
          _buildVideoPreview(),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          _buildErrorBanner(),
        ],
      ],
    );
  }

  // ── Drop zone ─────────────────────────────────────────────────────────────

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _isProcessing ? null : _pickVideo,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: _kInputFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: _isProcessing
                ? AppColors.brightCyan.withOpacity(0.5)
                : _kBorder,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isProcessing) ...[
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.brightCyan,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Processing video…',
                style: TextStyle(
                    color: AppColors.brightCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_circle_outline_rounded,
                    color: AppColors.brightCyan, size: 32),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tap to upload a video pitch',
                style: TextStyle(
                  color: _kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Max ${VideoService.maxVideoSizeMB} MB · MP4, WebM, MOV',
                style: const TextStyle(
                    color: _kTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: const Text(
                  'Choose File',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Video preview ─────────────────────────────────────────────────────────

  Widget _buildVideoPreview() {
    return Container(
      decoration: BoxDecoration(
        color: _kInputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: AppColors.forestGreen.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail / 16:9 preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_thumbnailBase64 != null)
                    Image.network(
                      _thumbnailBase64!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbnailFallback(),
                    )
                  else
                    _thumbnailFallback(),
                  // Dark overlay + play icon
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.5, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                  // Success badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen.withOpacity(0.85),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Ready',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // File info row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                const Icon(Icons.videocam_outlined,
                    color: _kTextSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFile!.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatFileSize(_selectedFile!.size),
                        style: const TextStyle(
                            fontSize: 11, color: _kTextSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _removeVideo,
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.deepRed),
                  label: const Text(
                    'Remove',
                    style: TextStyle(
                        color: AppColors.deepRed, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnailFallback() {
    return Container(
      color: const Color(0xFF1A1A1E),
      child: const Center(
        child: Icon(Icons.video_library_outlined,
            color: Color(0xFF555558), size: 40),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                  color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
