import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'media_options.dart';
import 'multi_image_options.dart';
import 'preferred_camera_device.dart';
import 'thumbnail_image.dart';

/// Hub screen for instant multi-capture with live native camera preview.
///
/// Shows a live camera preview using native platform views with a capture
/// button that directly captures photos. Thumbnails appear instantly in the
/// bottom strip with a badge count. User taps "Done" when finished.
class MultiCaptureScreen extends StatefulWidget {
  /// Options controlling quality, watermark, etc. Crop is ignored.
  final MediaOptions mediaOptions;

  /// Options controlling max/min images and discard confirmation.
  final MultiImageOptions multiImageOptions;

  const MultiCaptureScreen({
    super.key,
    required this.mediaOptions,
    required this.multiImageOptions,
  });

  @override
  State<MultiCaptureScreen> createState() => MultiCaptureScreenState();
}

@visibleForTesting
class MultiCaptureScreenState extends State<MultiCaptureScreen> {
  static const MethodChannel _cameraChannel =
      MethodChannel('info.thanhtunguet.media_picker_plus/camera');

  final List<String> _capturedPaths = [];
  bool _isCapturing = false;
  double _currentZoom = 1.0;
  PreferredCameraDevice _currentDevice = PreferredCameraDevice.back;

  // Available zoom levels (0.5x, 1x, 2x, etc.)
  final List<double> _zoomLevels = [0.5, 1.0, 2.0, 3.0];

  bool get _maxReached =>
      widget.multiImageOptions.maxImages != null &&
      _capturedPaths.length >= widget.multiImageOptions.maxImages!;

  bool get _canConfirm =>
      _capturedPaths.length >= widget.multiImageOptions.minImages;

  Future<void> _capturePhoto() async {
    if (_isCapturing || _maxReached) return;

    setState(() => _isCapturing = true);

    try {
      final path = await _cameraChannel.invokeMethod<String>('capturePhoto');

      if (mounted) {
        setState(() => _isCapturing = false);

        if (path != null) {
          setState(() {
            _capturedPaths.add(path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _capturedPaths.removeAt(index);
    });
  }

  void _confirmSelection() {
    Navigator.of(context).pop(List<String>.from(_capturedPaths));
  }

  Future<bool> _onWillPop() async {
    if (_capturedPaths.isEmpty) return true;

    if (!widget.multiImageOptions.confirmOnDiscard) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard photos?'),
        content: Text(
          'You have ${_capturedPaths.length} photo(s). '
          'Do you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _previewPhoto(String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: buildThumbnail(path, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  void _showAllPhotos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              '${_capturedPaths.length} Photo${_capturedPaths.length != 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _capturedPaths.length,
            itemBuilder: (context, index) {
              final path = _capturedPaths[index];
              return GestureDetector(
                onTap: () => _previewPhoto(path),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: buildThumbnail(path),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          _removePhoto(index);
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _switchCamera() async {
    setState(() {
      _currentDevice = _currentDevice == PreferredCameraDevice.back
          ? PreferredCameraDevice.front
          : PreferredCameraDevice.back;
      _currentZoom = 1.0; // Reset zoom when switching camera
    });
  }

  void _setZoom(double zoom) {
    setState(() {
      _currentZoom = zoom;
    });
    // TODO: Implement actual zoom via method channel
    _cameraChannel.invokeMethod('setZoom', {'zoom': zoom});
  }

  @override
  void dispose() {
    _cameraChannel.invokeMethod('dispose');
    super.dispose();
  }

  Widget _buildCameraView() {
    final viewKey = ValueKey('camera-view-${_currentDevice.name}');
    final params = {
      'preferredCameraDevice': _currentDevice.name,
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        key: viewKey,
        viewType: 'info.thanhtunguet.media_picker_plus/camera_view',
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        key: viewKey,
        viewType: 'info.thanhtunguet.media_picker_plus/camera_view',
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Camera not supported on this platform',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (!mounted) return;
          if (shouldPop) {
            Navigator.of(this.context).pop(null);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Native camera preview
              _buildCameraView(),

              // Top bar
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
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () async {
                          if (await _onWillPop()) {
                            if (!mounted) return;
                            Navigator.of(this.context).pop(null);
                          }
                        },
                      ),
                      if (_capturedPaths.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_capturedPaths.length}${widget.multiImageOptions.maxImages != null ? '/${widget.multiImageOptions.maxImages}' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: _canConfirm ? _confirmSelection : null,
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: _canConfirm
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    top: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Zoom controls
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _zoomLevels.map((zoom) {
                            final isSelected = _currentZoom == zoom;
                            return GestureDetector(
                              onTap: () => _setZoom(zoom),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  zoom == zoom.toInt()
                                      ? '${zoom.toInt()}x'
                                      : '${zoom}x',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSelected ? 16 : 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Main control row: thumbnails, capture button, camera switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Grouped thumbnails on the left
                          SizedBox(
                            width:
                                90, // Fixed width to contain stacked thumbnails
                            height: 70, // Fixed height
                            child: _capturedPaths.isEmpty
                                ? const SizedBox.shrink()
                                : GestureDetector(
                                    onTap: _showAllPhotos,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Show stacked thumbnail effect
                                        if (_capturedPaths.length > 2)
                                          Positioned(
                                            left: 0,
                                            top: 5,
                                            child: Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.3),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (_capturedPaths.length > 1)
                                          Positioned(
                                            left: 8,
                                            top: 5,
                                            child: Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.5),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        // Top thumbnail (latest)
                                        Positioned(
                                          left: _capturedPaths.length > 1
                                              ? 16
                                              : 0,
                                          top: 5,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: buildThumbnail(
                                                      _capturedPaths.last),
                                                ),
                                              ),
                                              // Badge count
                                              Positioned(
                                                top: -8,
                                                right: -8,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.blue,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    '${_capturedPaths.length}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),

                          // Capture button in center
                          GestureDetector(
                            onTap: _maxReached ? null : _capturePhoto,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _maxReached ? Colors.grey : Colors.white,
                                ),
                                child: _isCapturing
                                    ? const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),

                          // Camera switch button on the right
                          SizedBox(
                            width: 90, // Match left side width for symmetry
                            height: 70,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _switchCamera,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.3),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.flip_camera_ios,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
