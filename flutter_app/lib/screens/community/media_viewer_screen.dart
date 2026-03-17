import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../models/discussion_model.dart';

/// Full-screen image viewer with pinch-to-zoom and swipe navigation.
///
/// Only images are shown (videos are skipped). Opens at [initialIndex] which
/// maps into the list of image-only [MediaFile]s filtered from [mediaFiles].
class MediaViewerScreen extends StatefulWidget {
  /// All media files for the discussion.
  final List<MediaFile> mediaFiles;

  /// Index into [mediaFiles] (not just images) that was tapped.
  final int initialIndex;

  const MediaViewerScreen({
    super.key,
    required this.mediaFiles,
    this.initialIndex = 0,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late final List<MediaFile> _images;
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _images = widget.mediaFiles.where((m) => m.isImage).toList();

    // Find the starting index within the images-only list.
    int startIndex = 0;
    if (widget.initialIndex < widget.mediaFiles.length) {
      final tapped = widget.mediaFiles[widget.initialIndex];
      if (tapped.isImage) {
        startIndex = _images.indexOf(tapped);
        if (startIndex < 0) startIndex = 0;
      }
    }
    _currentIndex = startIndex;
    _pageController = PageController(initialPage: startIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('No images to display',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${_images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: _images.length,
        builder: (context, index) {
          final media = _images[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(media.fileUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: media.id),
          );
        },
        onPageChanged: (index) => setState(() => _currentIndex = index),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}
