import 'package:flutter/material.dart';
import '../../models/media_file.dart';
import '../../screens/community/media_viewer_screen.dart';
import '../video_player_dialog.dart';

/// Facebook-style media gallery supporting 1–5+ media files.
///
/// Layout patterns:
///   1 item  → full-width 4:3 image/video
///   2 items → 50/50 side-by-side
///   3 items → large left (2/3) + 2 stacked right (1/3)
///   4 items → 2×2 grid
///   5+ items → 2×2 grid with "+N" overlay on the fourth slot
///
/// Tapping an image opens [MediaViewerScreen]; tapping a video opens
/// [VideoPlayerDialog].
class MediaGalleryWidget extends StatelessWidget {
  final List<MediaFile> media;

  const MediaGalleryWidget({super.key, required this.media});

  static const double _multiHeight = 220;
  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: _buildLayout(context),
    );
  }

  Widget _buildLayout(BuildContext context) {
    switch (media.length) {
      case 1:
        return _buildSingle(context);
      case 2:
        return _buildTwo(context);
      case 3:
        return _buildThree(context);
      default:
        return _buildGrid(context);
    }
  }

  // ── Layouts ──────────────────────────────────────────────────────────────

  /// 1 item: full-width 4:3
  Widget _buildSingle(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: _mediaItem(context, media[0], 0),
    );
  }

  /// 2 items: 50/50 side-by-side
  Widget _buildTwo(BuildContext context) {
    return SizedBox(
      height: _multiHeight,
      child: Row(
        children: [
          Expanded(child: _mediaItem(context, media[0], 0)),
          const SizedBox(width: _gap),
          Expanded(child: _mediaItem(context, media[1], 1)),
        ],
      ),
    );
  }

  /// 3 items: large left (flex 2) + 2 stacked right (flex 1)
  Widget _buildThree(BuildContext context) {
    return SizedBox(
      height: _multiHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: _mediaItem(context, media[0], 0),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _mediaItem(context, media[1], 1)),
                const SizedBox(height: _gap),
                Expanded(child: _mediaItem(context, media[2], 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4+ items: 2×2 grid; 4th slot shows "+N" overlay when there are extras.
  Widget _buildGrid(BuildContext context) {
    final items = media.take(4).toList();
    final extra = media.length - 4;

    return SizedBox(
      height: _multiHeight,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _mediaItem(context, items[0], 0)),
                const SizedBox(width: _gap),
                Expanded(child: _mediaItem(context, items[1], 1)),
              ],
            ),
          ),
          const SizedBox(height: _gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _mediaItem(context, items[2], 2)),
                const SizedBox(width: _gap),
                Expanded(
                  child: extra > 0
                      ? _overlayItem(context, items[3], 3, extra)
                      : _mediaItem(context, items[3], 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Item builders ─────────────────────────────────────────────────────────

  Widget _mediaItem(BuildContext context, MediaFile item, int index) {
    return GestureDetector(
      onTap: () => _onTap(context, item, index),
      child: item.isImage ? _imageWidget(item) : _videoWidget(item),
    );
  }

  Widget _imageWidget(MediaFile item) {
    return Image.network(
      item.fileUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFE5E7EB),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFE5E7EB),
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
        ),
      ),
    );
  }

  Widget _videoWidget(MediaFile item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (item.thumbnailUrl != null)
          Image.network(
            item.thumbnailUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) =>
                Container(color: Colors.black87),
          )
        else
          Container(color: Colors.black87),
        const Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 44,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// 4th slot with a "+N more" overlay.
  Widget _overlayItem(
      BuildContext context, MediaFile item, int index, int extra) {
    return GestureDetector(
      onTap: () => _onTap(context, item, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          item.isImage ? _imageWidget(item) : _videoWidget(item),
          Container(color: Colors.black54),
          Center(
            child: Text(
              '+$extra',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _onTap(BuildContext context, MediaFile item, int index) {
    if (item.isImage) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MediaViewerScreen(
            mediaFiles: media,
            initialIndex: index,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => VideoPlayerDialog(
          videoUrl: item.fileUrl,
          projectTitle: item.fileName.isNotEmpty ? item.fileName : 'Video',
        ),
      );
    }
  }
}
