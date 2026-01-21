import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Camera preview overlay for web
// TODO: This overlay path appears unused; consider removing or integrating.
class CameraPreviewOverlay extends StatefulWidget {
  final web.MediaStream stream;
  final bool isVideo;
  final VoidCallback onCapture;
  final VoidCallback? onStopRecording;
  final VoidCallback onCancel;
  final bool isRecording;
  final Duration? recordingDuration;

  const CameraPreviewOverlay({
    Key? key,
    required this.stream,
    required this.isVideo,
    required this.onCapture,
    this.onStopRecording,
    required this.onCancel,
    this.isRecording = false,
    this.recordingDuration,
  }) : super(key: key);

  @override
  State<CameraPreviewOverlay> createState() => _CameraPreviewOverlayState();
}

class _CameraPreviewOverlayState extends State<CameraPreviewOverlay> {
  late String _viewId;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _viewId = 'camera-preview-${DateTime.now().millisecondsSinceEpoch}';
    _registerVideoElement();

    if (widget.isRecording) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(CameraPreviewOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _startTimer();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _stopTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _registerVideoElement() {
    // Create video element
    final videoElement =
        web.document.createElement('video') as web.HTMLVideoElement;
    videoElement.id = _viewId;
    videoElement.srcObject = widget.stream;
    videoElement.autoplay = true;
    videoElement.playsInline = true;
    videoElement.muted = true; // Mute to avoid feedback
    videoElement.style.width = '100%';
    videoElement.style.height = '100%';
    videoElement.style.objectFit = 'cover';

    // Register the view factory
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => videoElement,
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          // Camera preview
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: HtmlElementView(viewType: _viewId),
              ),
            ),
          ),

          // Top bar with close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(153),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      widget.isVideo ? 'Record Video' : 'Take Photo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                      onPressed: widget.onCancel,
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recording indicator (for video)
          if (widget.isVideo && widget.isRecording)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(230),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Recording dot (animated)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'REC ${_formatDuration(_elapsedSeconds)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withAlpha(204),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: _buildControls(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (widget.isVideo) {
      return _buildVideoControls();
    } else {
      return _buildPhotoControls();
    }
  }

  Widget _buildPhotoControls() {
    return Center(
      child: GestureDetector(
        onTap: widget.onCapture,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            color: Colors.white.withAlpha(77),
          ),
          child: const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    if (widget.isRecording) {
      // Stop button
      return Center(
        child: GestureDetector(
          onTap: widget.onStopRecording,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: Colors.red.withAlpha(204),
            ),
            child: const Center(
              child: Icon(
                Icons.stop,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      );
    } else {
      // Record button
      return Center(
        child: GestureDetector(
          onTap: widget.onCapture,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: Colors.red.withAlpha(77),
            ),
            child: const Center(
              child: Icon(
                Icons.fiber_manual_record,
                color: Colors.red,
                size: 40,
              ),
            ),
          ),
        ),
      );
    }
  }
}
