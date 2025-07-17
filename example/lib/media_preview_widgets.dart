import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

/// Enhanced image preview widget with zoom and fullscreen capabilities
class EnhancedImagePreview extends StatelessWidget {
  final String imagePath;
  final String? title;
  final VoidCallback? onClear;
  final double height;
  final bool showControls;

  const EnhancedImagePreview({
    super.key,
    required this.imagePath,
    this.title,
    this.onClear,
    this.height = 300,
    this.showControls = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (showControls && onClear != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: onClear,
                      tooltip: 'Clear image',
                    ),
                ],
              ),
            ),
          Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                bottom: const Radius.circular(12),
                top: title == null ? const Radius.circular(12) : Radius.zero,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                bottom: const Radius.circular(12),
                top: title == null ? const Radius.circular(12) : Radius.zero,
              ),
              child: Stack(
                children: [
                  // Image display
                  Positioned.fill(
                    child: _buildImageWidget(),
                  ),
                  // Overlay controls
                  if (showControls)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          _buildControlButton(
                            icon: Icons.fullscreen,
                            tooltip: 'View fullscreen',
                            onPressed: () => _showFullscreenImage(context),
                          ),
                          const SizedBox(width: 4),
                          _buildControlButton(
                            icon: Icons.info_outline,
                            tooltip: 'Image info',
                            onPressed: () => _showImageInfo(context),
                          ),
                        ],
                      ),
                    ),
                  // Watermark indicator
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_drop, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Watermarked',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showControls)
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                _getImagePath(),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    if (kIsWeb || imagePath.startsWith('data:')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text('Failed to load image'),
            ],
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text('Failed to load image'),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  String _getImagePath() {
    if (imagePath.length > 50) {
      return '...${imagePath.substring(imagePath.length - 47)}';
    }
    return imagePath;
  }

  void _showFullscreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(imagePath: imagePath),
      ),
    );
  }

  void _showImageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info),
            SizedBox(width: 8),
            Text('Image Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Path', _getImagePath()),
            _buildInfoRow(
                'Type',
                imagePath.toLowerCase().contains('.jpg') ||
                        imagePath.toLowerCase().contains('.jpeg')
                    ? 'JPEG'
                    : 'Image'),
            _buildInfoRow(
                'Source',
                kIsWeb || imagePath.startsWith('data:')
                    ? 'Web/Data URL'
                    : 'Local File'),
            _buildInfoRow('Watermark', 'Applied with timestamp'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Video player widget with custom controls and fullscreen support
class EnhancedVideoPlayer extends StatefulWidget {
  final String videoPath;
  final String? title;
  final VoidCallback? onClear;
  final double height;
  final bool showControls;
  final bool autoPlay;

  const EnhancedVideoPlayer({
    super.key,
    required this.videoPath,
    this.title,
    this.onClear,
    this.height = 300,
    this.showControls = true,
    this.autoPlay = false,
  });

  @override
  State<EnhancedVideoPlayer> createState() => _EnhancedVideoPlayerState();
}

class _EnhancedVideoPlayerState extends State<EnhancedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      if (kIsWeb || widget.videoPath.startsWith('data:')) {
        _controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        _controller = VideoPlayerController.file(File(widget.videoPath));
      }

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        if (widget.autoPlay) {
          _playPause();
        }
      }

      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  void _playPause() {
    if (_controller == null) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  void _seek(Duration position) {
    _controller?.seekTo(position);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.video_library, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (widget.showControls && widget.onClear != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: widget.onClear,
                      tooltip: 'Clear video',
                    ),
                ],
              ),
            ),
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(
                bottom: const Radius.circular(12),
                top: widget.title == null
                    ? const Radius.circular(12)
                    : Radius.zero,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                bottom: const Radius.circular(12),
                top: widget.title == null
                    ? const Radius.circular(12)
                    : Radius.zero,
              ),
              child: _buildVideoContent(),
            ),
          ),
          if (widget.showControls && _isInitialized) _buildVideoControls(),
          if (widget.showControls)
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                _getVideoPath(),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              'Video Error',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
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
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _toggleControls,
            child: VideoPlayer(_controller!),
          ),
        ),
        if (_showControls && widget.showControls)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(77),
                    Colors.transparent,
                    Colors.black.withAlpha(77),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Play/Pause button in center
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: _playPause,
                      ),
                    ),
                  ),
                  // Top controls
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _buildControlButton(
                          icon: Icons.fullscreen,
                          tooltip: 'Fullscreen',
                          onPressed: () => _showFullscreenVideo(context),
                        ),
                        const SizedBox(width: 4),
                        _buildControlButton(
                          icon: Icons.info_outline,
                          tooltip: 'Video info',
                          onPressed: () => _showVideoInfo(context),
                        ),
                      ],
                    ),
                  ),
                  // Watermark indicator
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_drop, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Watermarked',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoControls() {
    final duration = _controller!.value.duration;
    final position = _controller!.value.position;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value: position.inMilliseconds.toDouble(),
                  max: duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    _seek(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _playPause,
              ),
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {
                  final newPosition = position - const Duration(seconds: 10);
                  _seek(newPosition < Duration.zero
                      ? Duration.zero
                      : newPosition);
                },
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () {
                  final newPosition = position + const Duration(seconds: 10);
                  _seek(newPosition > duration ? duration : newPosition);
                },
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () => _showFullscreenVideo(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getVideoPath() {
    if (widget.videoPath.length > 50) {
      return '...${widget.videoPath.substring(widget.videoPath.length - 47)}';
    }
    return widget.videoPath;
  }

  void _showFullscreenVideo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(
          videoPath: widget.videoPath,
          controller: _controller,
        ),
      ),
    );
  }

  void _showVideoInfo(BuildContext context) {
    final duration = _controller?.value.duration ?? Duration.zero;
    final size = _controller?.value.size ?? Size.zero;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info),
            SizedBox(width: 8),
            Text('Video Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Path', _getVideoPath()),
            _buildInfoRow('Duration', _formatDuration(duration)),
            _buildInfoRow(
                'Resolution', '${size.width.toInt()}x${size.height.toInt()}'),
            _buildInfoRow(
                'Source',
                kIsWeb || widget.videoPath.startsWith('data:')
                    ? 'Web/Data URL'
                    : 'Local File'),
            _buildInfoRow('Watermark', 'Applied with timestamp'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Fullscreen image viewer with zoom and pan
class FullscreenImageViewer extends StatelessWidget {
  final String imagePath;

  const FullscreenImageViewer({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showImageInfo(context),
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: kIsWeb || imagePath.startsWith('data:')
            ? NetworkImage(imagePath)
            : FileImage(File(imagePath)) as ImageProvider,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        heroAttributes: PhotoViewHeroAttributes(tag: imagePath),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Path: ${_getShortPath()}'),
            const Text('Watermark: Applied with timestamp'),
            Text(
                'Source: ${kIsWeb || imagePath.startsWith('data:') ? 'Web/Data URL' : 'Local File'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getShortPath() {
    if (imagePath.length > 40) {
      return '...${imagePath.substring(imagePath.length - 37)}';
    }
    return imagePath;
  }
}

/// Fullscreen video player
class FullscreenVideoPlayer extends StatefulWidget {
  final String videoPath;
  final VideoPlayerController? controller;

  const FullscreenVideoPlayer({
    super.key,
    required this.videoPath,
    this.controller,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null && widget.controller!.value.isInitialized) {
      _controller = widget.controller!;
      _isPlaying = _controller.value.isPlaying;
    } else {
      _initializeVideo();
    }

    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
        });
      }
    });
  }

  Future<void> _initializeVideo() async {
    if (kIsWeb || widget.videoPath.startsWith('data:')) {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
    } else {
      _controller = VideoPlayerController.file(File(widget.videoPath));
    }

    await _controller.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _playPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_controller.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Controls overlay
          if (_showControls)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(128),
                        Colors.transparent,
                        Colors.black.withAlpha(128),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Top controls
                      SafeArea(
                        child: Row(
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.info_outline,
                                  color: Colors.white),
                              onPressed: () => _showVideoInfo(context),
                            ),
                          ],
                        ),
                      ),

                      // Center play button
                      Expanded(
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 48,
                              ),
                              onPressed: _playPause,
                            ),
                          ),
                        ),
                      ),

                      // Bottom controls
                      SafeArea(
                        child: _buildBottomControls(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final duration = _controller.value.duration;
    final position = _controller.value.position;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Expanded(
                child: Slider(
                  value: position.inMilliseconds.toDouble(),
                  max: duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    _controller.seekTo(Duration(milliseconds: value.toInt()));
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white30,
                ),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white),
                onPressed: () {
                  final newPosition = position - const Duration(seconds: 10);
                  _controller.seekTo(newPosition < Duration.zero
                      ? Duration.zero
                      : newPosition);
                },
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white),
                onPressed: _playPause,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white),
                onPressed: () {
                  final newPosition = position + const Duration(seconds: 10);
                  _controller
                      .seekTo(newPosition > duration ? duration : newPosition);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showVideoInfo(BuildContext context) {
    final duration = _controller.value.duration;
    final size = _controller.value.size;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${_formatDuration(duration)}'),
            Text('Resolution: ${size.width.toInt()}x${size.height.toInt()}'),
            const Text('Watermark: Applied with timestamp'),
            Text(
                'Source: ${kIsWeb || widget.videoPath.startsWith('data:') ? 'Web/Data URL' : 'Local File'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
