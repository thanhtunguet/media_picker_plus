import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'crop_options.dart';

/// Interactive cropping UI widget for manual crop selection
class CropUI extends StatefulWidget {
  final String imagePath;

  /// Optional pre-decoded image to display instead of loading [imagePath].
  ///
  /// This is mainly intended for tests and advanced use-cases where you already
  /// have a decoded [ui.Image] available.
  final ui.Image? initialImage;
  final CropOptions? initialCropOptions;
  final Function(CropRect? cropRect) onCropChanged;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const CropUI({
    super.key,
    required this.imagePath,
    this.initialImage,
    this.initialCropOptions,
    required this.onCropChanged,
    this.onConfirm,
    this.onCancel,
  });

  @override
  State<CropUI> createState() => _CropUIState();
}

class _CropUIState extends State<CropUI> with TickerProviderStateMixin {
  ui.Image? _image;
  Rect _cropRect = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
  bool _isLoading = true;
  double? _aspectRatio;
  bool _lockAspectRatio = false;
  bool _isAtMinimumSize = false;

  // Performance optimization: reduce callback frequency
  DateTime _lastCallbackTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const _callbackThrottleMs = 16; // ~60 FPS

  @override
  void initState() {
    super.initState();
    _initializeCropSettings();
    if (widget.initialImage != null) {
      _image = widget.initialImage;
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyCropChanged();
      });
    } else {
      _loadImage();
    }
  }

  void _initializeCropSettings() {
    if (widget.initialCropOptions != null) {
      _aspectRatio = widget.initialCropOptions!.aspectRatio;
      _lockAspectRatio = widget.initialCropOptions!.lockAspectRatio;

      if (widget.initialCropOptions!.cropRect != null) {
        final rect = widget.initialCropOptions!.cropRect!;
        _cropRect = Rect.fromLTWH(rect.x, rect.y, rect.width, rect.height);
      } else if (_aspectRatio != null) {
        // Calculate crop rect based on aspect ratio
        _cropRect = _calculateCropRectForAspectRatio(_aspectRatio!);
      }
    }
  }

  Rect _calculateCropRectForAspectRatio(double aspectRatio) {
    const margin = 0.1;
    const availableWidth = 1.0 - (2 * margin);
    const availableHeight = 1.0 - (2 * margin);

    double width, height;

    if (availableWidth / availableHeight > aspectRatio) {
      // Container is wider than needed, fit by height
      height = availableHeight;
      width = height * aspectRatio;
    } else {
      // Container is taller than needed, fit by width
      width = availableWidth;
      height = width / aspectRatio;
    }

    final x = (1.0 - width) / 2;
    final y = (1.0 - height) / 2;

    return Rect.fromLTWH(x, y, width, height);
  }

  Future<void> _loadImage() async {
    try {
      Uint8List bytes;

      if (kIsWeb || widget.imagePath.startsWith('data:')) {
        // Handle web data URLs
        if (widget.imagePath.startsWith('data:image')) {
          final base64Data = widget.imagePath.split(',')[1];
          bytes = base64Decode(base64Data);
        } else {
          throw Exception('Unsupported image format for web');
        }
      } else {
        // Handle file paths
        final file = File(widget.imagePath);
        bytes = await file.readAsBytes();
      }

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      setState(() {
        _image = frame.image;
        _isLoading = false;

        // Adjust crop rect based on image aspect ratio if needed
        if (_aspectRatio != null) {
          _cropRect = _calculateCropRectForAspectRatio(_aspectRatio!);
        }
      });

      _notifyCropChanged();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _notifyCropChanged() {
    // Throttle callbacks for better performance
    final now = DateTime.now();
    if (now.difference(_lastCallbackTime).inMilliseconds <
        _callbackThrottleMs) {
      return;
    }
    _lastCallbackTime = now;

    final cropRect = CropRect(
      x: _cropRect.left,
      y: _cropRect.top,
      width: _cropRect.width,
      height: _cropRect.height,
    );
    widget.onCropChanged(cropRect);
  }

  void _updateCropRect(Rect newRect) {
    // Validate the crop rectangle before updating
    final validatedRect = _validateCropRectSafely(newRect);

    // Check if crop area is at minimum size
    final screenSize = MediaQuery.of(context).size;
    final smallerEdge = screenSize.width < screenSize.height
        ? screenSize.width
        : screenSize.height;
    final minPixelSize = smallerEdge * 0.3;
    final minNormalizedSize = (minPixelSize / smallerEdge).clamp(0.2, 0.5);

    final isAtMinSize = validatedRect.width <= minNormalizedSize + 0.01 ||
        validatedRect.height <= minNormalizedSize + 0.01;

    // Immediate visual update without throttling for smooth interaction
    setState(() {
      _cropRect = validatedRect;
      _isAtMinimumSize = isAtMinSize;
    });
    _notifyCropChanged();
  }

  /// Safely validate crop rectangle with fallback
  Rect _validateCropRectSafely(Rect rect) {
    // Calculate minimum size based on 30% of smaller screen edge
    final screenSize = MediaQuery.of(context).size;
    final smallerEdge = screenSize.width < screenSize.height
        ? screenSize.width
        : screenSize.height;
    final minPixelSize = smallerEdge * 0.3; // 30% of smaller edge

    // Convert to normalized size relative to image dimensions
    final minSize = _image != null
        ? (minPixelSize /
                (screenSize.width < screenSize.height
                    ? screenSize.width
                    : screenSize.height))
            .clamp(0.2, 0.5)
        : 0.3; // Fallback to 30% if no image

    const maxSize = 0.9; // 90% maximum size for safety

    // Ensure all values are finite and within bounds
    final left = rect.left.clamp(0.0, maxSize);
    final top = rect.top.clamp(0.0, maxSize);
    final width = rect.width.clamp(minSize, 1.0 - left);
    final height = rect.height.clamp(minSize, 1.0 - top);

    // Double check the rectangle is valid
    if (width <= 0.0 || height <= 0.0 || left < 0.0 || top < 0.0) {
      // Return a safe default rectangle if invalid
      return const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
    }

    return Rect.fromLTWH(left, top, width, height);
  }

  void _resetCrop() {
    setState(() {
      if (_aspectRatio != null) {
        _cropRect = _calculateCropRectForAspectRatio(_aspectRatio!);
      } else {
        _cropRect = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
      }
    });
    _notifyCropChanged();
  }

  void _setAspectRatio(double? ratio) {
    setState(() {
      _aspectRatio = ratio;
      _lockAspectRatio = ratio != null;
      if (ratio != null) {
        _cropRect = _calculateCropRectForAspectRatio(ratio);
        _notifyCropChanged();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_image == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Crop Image'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel,
          ),
        ),
        body: const Center(
          child: Text('Failed to load image'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop Image'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCrop,
            tooltip: 'Reset',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: widget.onConfirm,
            tooltip: 'Confirm',
          ),
        ],
      ),
      body: Column(
        children: [
          // Crop Controls
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Aspect Ratio Controls
                Row(
                  children: [
                    const Text(
                      'Aspect Ratio:',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _buildAspectRatioChip('Free', null),
                          _buildAspectRatioChip('1:1', 1.0),
                          _buildAspectRatioChip('4:3', 4.0 / 3.0),
                          _buildAspectRatioChip('3:4', 3.0 / 4.0),
                          _buildAspectRatioChip('16:9', 16.0 / 9.0),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Current Crop Info
                Column(
                  children: [
                    Text(
                      'Crop: ${(_cropRect.width * 100).toStringAsFixed(0)}% × ${(_cropRect.height * 100).toStringAsFixed(0)}%',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    if (_isAtMinimumSize)
                      const Text(
                        'Minimum size reached - Pinch to zoom for more precision',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Crop Area (optimized with RepaintBoundary)
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: _isAtMinimumSize
                  ? 5.0
                  : 3.0, // Allow higher zoom when at minimum size
              child: Center(
                child: RepaintBoundary(
                  child: AspectRatio(
                    aspectRatio: _image!.width / _image!.height,
                    child: CropWidget(
                      image: _image!,
                      cropRect: _cropRect,
                      aspectRatio: _aspectRatio,
                      lockAspectRatio: _lockAspectRatio,
                      onCropChanged: _updateCropRect,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Controls
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: widget.onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Crop'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectRatioChip(String label, double? ratio) {
    final isSelected = _aspectRatio == ratio;
    return GestureDetector(
      onTap: () => _setAspectRatio(ratio),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.white54,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Custom crop widget with interactive handles
class CropWidget extends StatefulWidget {
  final ui.Image image;
  final Rect cropRect;
  final double? aspectRatio;
  final bool lockAspectRatio;
  final Function(Rect) onCropChanged;

  const CropWidget({
    super.key,
    required this.image,
    required this.cropRect,
    this.aspectRatio,
    this.lockAspectRatio = false,
    required this.onCropChanged,
  });

  @override
  State<CropWidget> createState() => _CropWidgetState();
}

class _CropWidgetState extends State<CropWidget> {
  Rect _currentCropRect = Rect.zero;
  Size _imageDisplaySize = Size.zero;
  Offset _imageOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _currentCropRect = widget.cropRect;
  }

  @override
  void didUpdateWidget(CropWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cropRect != widget.cropRect) {
      _currentCropRect = widget.cropRect;
    }
  }

  /// Validate crop rectangle to ensure it has valid dimensions
  Rect _validateCropRect(Rect rect) {
    const minSize =
        0.3; // 30% minimum size (will be refined in gesture handling)

    // Ensure all values are finite and within bounds
    final left = rect.left.clamp(0.0, 1.0);
    final top = rect.top.clamp(0.0, 1.0);
    final width = rect.width.clamp(minSize, 1.0 - left);
    final height = rect.height.clamp(minSize, 1.0 - top);

    // Ensure the rectangle is valid
    if (width <= 0.0 || height <= 0.0) {
      // Return a safe default rectangle if invalid
      return const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
    }

    return Rect.fromLTWH(left, top, width, height);
  }

  void _calculateImageLayout(Size widgetSize) {
    final imageAspectRatio = widget.image.width / widget.image.height;
    final widgetAspectRatio = widgetSize.width / widgetSize.height;

    if (imageAspectRatio > widgetAspectRatio) {
      // Image is wider, fit by width
      _imageDisplaySize = Size(
        widgetSize.width,
        widgetSize.width / imageAspectRatio,
      );
    } else {
      // Image is taller, fit by height
      _imageDisplaySize = Size(
        widgetSize.height * imageAspectRatio,
        widgetSize.height,
      );
    }

    _imageOffset = Offset(
      (widgetSize.width - _imageDisplaySize.width) / 2,
      (widgetSize.height - _imageDisplaySize.height) / 2,
    );
  }

  Rect _normalizedToScreen(Rect normalizedRect) {
    return Rect.fromLTWH(
      _imageOffset.dx + normalizedRect.left * _imageDisplaySize.width,
      _imageOffset.dy + normalizedRect.top * _imageDisplaySize.height,
      normalizedRect.width * _imageDisplaySize.width,
      normalizedRect.height * _imageDisplaySize.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _calculateImageLayout(constraints.biggest);

        return SizedBox.fromSize(
          size: constraints.biggest,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background image
              Positioned.fill(
                child: CustomPaint(
                  painter: CropImagePainter(
                    image: widget.image,
                    imageSize: _imageDisplaySize,
                    imageOffset: _imageOffset,
                    cropRect: _normalizedToScreen(_currentCropRect),
                  ),
                ),
              ),

              // Crop handles
              Positioned.fill(
                child: CropHandles(
                  cropRect: _normalizedToScreen(_currentCropRect),
                  aspectRatio: widget.aspectRatio,
                  lockAspectRatio: widget.lockAspectRatio,
                  imageDisplaySize: _imageDisplaySize,
                  imageOffset: _imageOffset,
                  onCropChanged: (newNormalizedRect) {
                    // Validate the crop rectangle before using it
                    final validatedRect = _validateCropRect(newNormalizedRect);
                    _currentCropRect = validatedRect;
                    setState(() {});
                    widget.onCropChanged(_currentCropRect);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for the image and crop overlay (optimized)
class CropImagePainter extends CustomPainter {
  final ui.Image image;
  final Size imageSize;
  final Offset imageOffset;
  final Rect cropRect;

  // Cache paint objects for better performance
  static final Paint _overlayPaint = Paint()..color = Colors.black54;
  static final Paint _borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _gridPaint = Paint()
    ..color = Colors.white38
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  CropImagePainter({
    required this.image,
    required this.imageSize,
    required this.imageOffset,
    required this.cropRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Validate crop rectangle before painting
    if (cropRect.width <= 0.0 || cropRect.height <= 0.0) {
      return; // Skip painting if invalid crop rectangle
    }

    // Draw the image (cached paint object)
    final imageRect = Rect.fromLTWH(
      imageOffset.dx,
      imageOffset.dy,
      imageSize.width,
      imageSize.height,
    );

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint(), // This is fine as a new instance for image drawing
    );

    // Optimized overlay drawing (batch operations)
    final overlayRects = <Rect>[];

    // Calculate overlay rectangles
    if (cropRect.top > imageRect.top) {
      overlayRects.add(Rect.fromLTRB(
          imageRect.left, imageRect.top, imageRect.right, cropRect.top));
    }
    if (cropRect.bottom < imageRect.bottom) {
      overlayRects.add(Rect.fromLTRB(
          imageRect.left, cropRect.bottom, imageRect.right, imageRect.bottom));
    }
    if (cropRect.left > imageRect.left) {
      overlayRects.add(Rect.fromLTRB(
          imageRect.left, cropRect.top, cropRect.left, cropRect.bottom));
    }
    if (cropRect.right < imageRect.right) {
      overlayRects.add(Rect.fromLTRB(
          cropRect.right, cropRect.top, imageRect.right, cropRect.bottom));
    }

    // Draw all overlays in batch
    for (final rect in overlayRects) {
      canvas.drawRect(rect, _overlayPaint);
    }

    // Draw crop border
    canvas.drawRect(cropRect, _borderPaint);

    // Optimized grid lines drawing
    final thirdWidth = cropRect.width / 3;
    final thirdHeight = cropRect.height / 3;

    // Draw all grid lines in batch
    final gridLines = <Offset>[
      // Vertical lines
      Offset(cropRect.left + thirdWidth, cropRect.top),
      Offset(cropRect.left + thirdWidth, cropRect.bottom),
      Offset(cropRect.left + thirdWidth * 2, cropRect.top),
      Offset(cropRect.left + thirdWidth * 2, cropRect.bottom),
      // Horizontal lines
      Offset(cropRect.left, cropRect.top + thirdHeight),
      Offset(cropRect.right, cropRect.top + thirdHeight),
      Offset(cropRect.left, cropRect.top + thirdHeight * 2),
      Offset(cropRect.right, cropRect.top + thirdHeight * 2),
    ];

    // Draw lines in pairs for better performance
    for (int i = 0; i < gridLines.length; i += 2) {
      canvas.drawLine(gridLines[i], gridLines[i + 1], _gridPaint);
    }
  }

  @override
  bool shouldRepaint(CropImagePainter oldDelegate) {
    // More precise repaint conditions for better performance
    return oldDelegate.cropRect != cropRect;
  }
}

/// Interactive crop handles widget
class CropHandles extends StatefulWidget {
  final Rect cropRect;
  final double? aspectRatio;
  final bool lockAspectRatio;
  final Function(Rect) onCropChanged;
  final Size imageDisplaySize;
  final Offset imageOffset;

  const CropHandles({
    super.key,
    required this.cropRect,
    this.aspectRatio,
    this.lockAspectRatio = false,
    required this.onCropChanged,
    required this.imageDisplaySize,
    required this.imageOffset,
  });

  @override
  State<CropHandles> createState() => _CropHandlesState();
}

class _CropHandlesState extends State<CropHandles> {
  Rect _currentRect = Rect.zero;
  bool _isDragging = false;
  String _dragType = '';

  @override
  void initState() {
    super.initState();
    _currentRect = widget.cropRect;
  }

  @override
  void didUpdateWidget(CropHandles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cropRect != widget.cropRect) {
      _currentRect = widget.cropRect;
    }
  }

  void _onPanStart(DragStartDetails details, String dragType) {
    setState(() {
      _isDragging = true;
      _dragType = dragType;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final delta = details.delta;

    // Convert screen pixel delta to normalized ratio relative to image
    final normalizedDeltaX = delta.dx / widget.imageDisplaySize.width;
    final normalizedDeltaY = delta.dy / widget.imageDisplaySize.height;

    // Convert current screen rect to normalized coordinates for calculations
    final normalizedCurrentRect = _screenToNormalized(_currentRect);

    // Apply delta in normalized space for proper ratio-based movement
    late final Rect newNormalizedRect;
    switch (_dragType) {
      case 'move':
        newNormalizedRect =
            normalizedCurrentRect.translate(normalizedDeltaX, normalizedDeltaY);
        break;
      case 'topLeft':
        newNormalizedRect = Rect.fromLTRB(
          normalizedCurrentRect.left + normalizedDeltaX,
          normalizedCurrentRect.top + normalizedDeltaY,
          normalizedCurrentRect.right,
          normalizedCurrentRect.bottom,
        );
        break;
      case 'topRight':
        newNormalizedRect = Rect.fromLTRB(
          normalizedCurrentRect.left,
          normalizedCurrentRect.top + normalizedDeltaY,
          normalizedCurrentRect.right + normalizedDeltaX,
          normalizedCurrentRect.bottom,
        );
        break;
      case 'bottomLeft':
        newNormalizedRect = Rect.fromLTRB(
          normalizedCurrentRect.left + normalizedDeltaX,
          normalizedCurrentRect.top,
          normalizedCurrentRect.right,
          normalizedCurrentRect.bottom + normalizedDeltaY,
        );
        break;
      case 'bottomRight':
        newNormalizedRect = Rect.fromLTRB(
          normalizedCurrentRect.left,
          normalizedCurrentRect.top,
          normalizedCurrentRect.right + normalizedDeltaX,
          normalizedCurrentRect.bottom + normalizedDeltaY,
        );
        break;
      default:
        return;
    }

    // Define minimum crop size based on 30% of smaller screen edge
    final screenSize = MediaQuery.of(context).size;
    final smallerEdge = screenSize.width < screenSize.height
        ? screenSize.width
        : screenSize.height;
    final minPixelSize = smallerEdge * 0.3; // 30% of smaller edge

    // Calculate minimum normalized size based on image display size
    final minNormalizedWidth =
        (minPixelSize / widget.imageDisplaySize.width).clamp(0.2, 0.5);
    final minNormalizedHeight =
        (minPixelSize / widget.imageDisplaySize.height).clamp(0.2, 0.5);

    // Constrain to safe bounds with proper minimum sizes
    final constrainedRect = Rect.fromLTWH(
      newNormalizedRect.left.clamp(0.0, 1.0 - minNormalizedWidth),
      newNormalizedRect.top.clamp(0.0, 1.0 - minNormalizedHeight),
      newNormalizedRect.width.clamp(minNormalizedWidth,
          1.0 - newNormalizedRect.left.clamp(0.0, 1.0 - minNormalizedWidth)),
      newNormalizedRect.height.clamp(minNormalizedHeight,
          1.0 - newNormalizedRect.top.clamp(0.0, 1.0 - minNormalizedHeight)),
    );

    // Apply aspect ratio constraint if needed (in normalized space)
    final finalNormalizedRect =
        (widget.lockAspectRatio && widget.aspectRatio != null)
            ? _constrainToAspectRatioNormalized(
                constrainedRect, widget.aspectRatio!)
            : constrainedRect;

    // Convert back to screen coordinates for visual update
    final finalScreenRect = _normalizedToScreen(finalNormalizedRect);

    // Update current rect for next iteration
    _currentRect = finalScreenRect;

    // Trigger immediate UI update
    setState(() {});

    // Send normalized coordinates to parent
    widget.onCropChanged(finalNormalizedRect);
  }

  /// Convert screen coordinates to normalized coordinates (0.0 - 1.0)
  Rect _screenToNormalized(Rect screenRect) {
    return Rect.fromLTWH(
      (screenRect.left - widget.imageOffset.dx) / widget.imageDisplaySize.width,
      (screenRect.top - widget.imageOffset.dy) / widget.imageDisplaySize.height,
      screenRect.width / widget.imageDisplaySize.width,
      screenRect.height / widget.imageDisplaySize.height,
    );
  }

  /// Convert normalized coordinates to screen coordinates
  Rect _normalizedToScreen(Rect normalizedRect) {
    return Rect.fromLTWH(
      widget.imageOffset.dx +
          normalizedRect.left * widget.imageDisplaySize.width,
      widget.imageOffset.dy +
          normalizedRect.top * widget.imageDisplaySize.height,
      normalizedRect.width * widget.imageDisplaySize.width,
      normalizedRect.height * widget.imageDisplaySize.height,
    );
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragType = '';
    });
  }

  /// Constrain aspect ratio in normalized coordinates with safe bounds
  Rect _constrainToAspectRatioNormalized(Rect rect, double aspectRatio) {
    // Ensure aspect ratio is valid
    if (aspectRatio <= 0.0) return rect;

    final currentAspectRatio = rect.width / rect.height;

    // If current aspect ratio is already close enough, return as-is
    if ((currentAspectRatio - aspectRatio).abs() < 0.01) {
      return rect;
    }

    late final Rect adjustedRect;

    if (currentAspectRatio > aspectRatio) {
      // Too wide, adjust width
      final newWidth = rect.height * aspectRatio;
      final widthDiff = rect.width - newWidth;
      adjustedRect = Rect.fromLTWH(
        rect.left + widthDiff / 2,
        rect.top,
        newWidth,
        rect.height,
      );
    } else {
      // Too tall, adjust height
      final newHeight = rect.width / aspectRatio;
      final heightDiff = rect.height - newHeight;
      adjustedRect = Rect.fromLTWH(
        rect.left,
        rect.top + heightDiff / 2,
        rect.width,
        newHeight,
      );
    }

    // Ensure the adjusted rect is within bounds (using dynamic minimum size)
    const minSize = 0.3; // 30% minimum size
    final boundedRect = Rect.fromLTWH(
      adjustedRect.left.clamp(0.0, 1.0 - adjustedRect.width),
      adjustedRect.top.clamp(0.0, 1.0 - adjustedRect.height),
      adjustedRect.width.clamp(minSize, 1.0),
      adjustedRect.height.clamp(minSize, 1.0),
    );

    // Final safety check - ensure dimensions are valid
    if (boundedRect.width > 0.0 && boundedRect.height > 0.0) {
      return boundedRect;
    }

    // Fallback to original rect if something went wrong
    return rect;
  }

  @override
  Widget build(BuildContext context) {
    const handleSize = 24.0;
    const handleColor = Colors.white;

    // Cache calculations for better performance
    const halfHandle = handleSize / 2;
    final moveAreaLeft = _currentRect.left + halfHandle;
    final moveAreaTop = _currentRect.top + halfHandle;
    final moveAreaWidth = _currentRect.width - handleSize;
    final moveAreaHeight = _currentRect.height - handleSize;

    return RepaintBoundary(
      child: Stack(
        children: [
          // Center drag area (move) - optimized positioning
          Positioned(
            left: moveAreaLeft,
            top: moveAreaTop,
            width: moveAreaWidth,
            height: moveAreaHeight,
            child: GestureDetector(
              onPanStart: (details) => _onPanStart(details, 'move'),
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),

          // Corner handles (cached positions)
          _buildHandle(
              _currentRect.topLeft, 'topLeft', handleSize, handleColor),
          _buildHandle(_currentRect.topRight.translate(-handleSize, 0),
              'topRight', handleSize, handleColor),
          _buildHandle(_currentRect.bottomLeft.translate(0, -handleSize),
              'bottomLeft', handleSize, handleColor),
          _buildHandle(
              _currentRect.bottomRight.translate(-handleSize, -handleSize),
              'bottomRight',
              handleSize,
              handleColor),
        ],
      ),
    );
  }

  Widget _buildHandle(
      Offset position, String dragType, double size, Color color) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: (details) => _onPanStart(details, dragType),
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 1),
            borderRadius: BorderRadius.circular(size / 2),
          ),
        ),
      ),
    );
  }
}
