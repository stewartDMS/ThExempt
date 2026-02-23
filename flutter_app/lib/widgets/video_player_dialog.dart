import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  final String projectTitle;

  const VideoPlayerDialog({
    Key? key,
    required this.videoUrl,
    required this.projectTitle,
  }) : super(key: key);

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _controllerCreated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      _controllerCreated = true;

      await _controller.initialize();

      setState(() {
        _isInitialized = true;
      });

      // Auto-play when ready
      _controller.play();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    if (_controllerCreated) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 900,
          maxHeight: 700,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and close button
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.projectTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Video player area
            Expanded(
              child: Container(
                color: Colors.black,
                child: _buildVideoContent(),
              ),
            ),

            // Controls
            if (_isInitialized && !_hasError) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load video',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Progress bar
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.blue,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 8),

          // Play/Pause and time
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),

              // Current time / Duration
              ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, VideoPlayerValue value, child) {
                  return Text(
                    '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),

              const Spacer(),

              // Volume/Mute
              IconButton(
                icon: Icon(
                  _controller.value.volume > 0
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    final newVolume = _controller.value.volume > 0 ? 0.0 : 1.0;
                    _controller.setVolume(newVolume);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
