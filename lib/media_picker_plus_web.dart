// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'crop_options.dart';
import 'media_options.dart';
import 'media_picker_plus_platform_interface.dart';
import 'media_source.dart';
import 'media_type.dart';

@JS()
external JSObject get globalThis;

// Simple logging helper to avoid print() warnings
void _log(String message) {
  // In production, this could be replaced with a proper logging framework
  // For now, using print for debugging purposes
  // ignore: avoid_print
  print('[MediaPickerPlusWeb] $message');
}

// ignore_for_file: invalid_assignment
/// Web implementation of MediaPickerPlusPlatform.
class MediaPickerPlusWeb extends MediaPickerPlusPlatform {
  MediaPickerPlusWeb();

  static void registerWith(Registrar registrar) {
    MediaPickerPlusPlatform.instance = MediaPickerPlusWeb();
  }

  @override
  Future<String?> getPlatformVersion() async {
    return web.window.navigator.userAgent;
  }

  @override
  Future<String?> pickMedia(
      MediaSource source, MediaType type, MediaOptions options) async {
    if (source == MediaSource.camera) {
      return _captureFromCamera(type, options);
    }
    return _pickFromGallery(type, options);
  }

  @override
  Future<bool> hasCameraPermission() async => true;
  @override
  Future<bool> requestCameraPermission() async => true;
  @override
  Future<bool> hasGalleryPermission() async => true;
  @override
  Future<bool> requestGalleryPermission() async => true;

  Future<String?> _pickFromGallery(MediaType type, MediaOptions options) async {
    final completer = Completer<String?>();
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.style.display = 'none';
    switch (type) {
      case MediaType.image:
        input.accept = 'image/*';
        break;
      case MediaType.video:
        input.accept = 'video/*';
        break;
      default:
        input.accept = '*/*';
    }
    input.addEventListener(
        'change',
        (web.Event event) {
          final files = input.files;
          if (files != null && files.length > 0) {
            final file = files.item(0);
            if (file == null) {
              completer.complete(null);
              return;
            }
            try {
              if (type == MediaType.image) {
                _processImageFile(file, options).then((result) {
                  completer.complete(result);
                }).catchError((e) {
                  completer.completeError(e);
                });
              } else if (type == MediaType.video) {
                final url = _createVideoObjectURL(file);
                completer.complete(url);
              } else {
                completer.complete(null);
              }
            } catch (e) {
              completer.completeError(e);
            }
          } else {
            completer.complete(null);
          }
        }.toJS);
    if (web.document.body != null) {
      web.document.body!.appendChild(input);
    }
    input.click();
    input.remove();
    return completer.future;
  }

  Future<String?> _captureFromCamera(
      MediaType type, MediaOptions options) async {
    final completer = Completer<String?>();
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.style.display = 'none';
    input.capture = 'environment';
    switch (type) {
      case MediaType.image:
        input.accept = 'image/*';
        break;
      case MediaType.video:
        input.accept = 'video/*';
        break;
      default:
        input.accept = '*/*';
    }
    input.addEventListener(
        'change',
        (web.Event event) {
          final files = input.files;
          if (files != null && files.length > 0) {
            final file = files.item(0);
            if (file == null) {
              completer.complete(null);
              return;
            }
            try {
              if (type == MediaType.image) {
                _processImageFile(file, options).then((result) {
                  completer.complete(result);
                }).catchError((e) {
                  completer.completeError(e);
                });
              } else if (type == MediaType.video) {
                _processVideoFileWithWatermark(file, options).then((url) {
                  completer.complete(url);
                }).catchError((e) {
                  completer.completeError(e);
                });
              } else {
                completer.complete(null);
              }
            } catch (e) {
              completer.completeError(e);
            }
          } else {
            completer.complete(null);
          }
        }.toJS);
    if (web.document.body != null) {
      web.document.body!.appendChild(input);
    }
    input.click();
    input.remove();
    return completer.future;
  }

  String _createVideoObjectURL(web.File file) {
    // Validate video file before creating object URL
    final mimeType = file.type;

    // Check if it's a valid video MIME type
    if (!mimeType.startsWith('video/')) {
      throw Exception('Invalid video file: MIME type is $mimeType');
    }

    // Log the video type for debugging
    _log(
        'Creating object URL for video: ${file.name}, type: $mimeType, size: ${file.size} bytes');

    try {
      final url = web.URL.createObjectURL(file);
      _log('Created video object URL: $url');
      return url;
    } catch (e) {
      _log('Failed to create object URL for video: $e');
      throw Exception('Failed to create video object URL: $e');
    }
  }

  /// Get video dimensions from a File or URL
  Future<Map<String, int>> _getVideoDimensions(dynamic videoSource) async {
    final completer = Completer<Map<String, int>>();
    final video = web.document.createElement('video') as web.HTMLVideoElement;

    video.addEventListener(
        'loadedmetadata',
        (web.Event event) {
          completer.complete({
            'width': video.videoWidth,
            'height': video.videoHeight,
          });
        }.toJS);

    video.addEventListener(
        'error',
        (web.Event event) {
          // Default dimensions if we can't load video
          completer.complete({'width': 1280, 'height': 720});
        }.toJS);

    if (videoSource is web.File) {
      video.src = web.URL.createObjectURL(videoSource);
    } else if (videoSource is String) {
      video.src = videoSource;
    }

    return completer.future;
  }

  Future<String?> _processVideoFileWithWatermark(
      web.File file, MediaOptions options) async {
    if (options.watermark == null || options.watermark!.isEmpty) {
      // No watermark, just return object URL
      return _createVideoObjectURL(file);
    }

    try {
      final watermarkText = options.watermark!;
      final position = options.watermarkPosition ?? 'bottomRight';

      // Check if the watermarking function exists
      final addWatermarkToVideo =
          globalThis.getProperty('addWatermarkToVideo'.toJS);
      if (addWatermarkToVideo.isUndefined || addWatermarkToVideo.isNull) {
        // Watermarking function not available, return video without watermark
        _log(
            'Warning: Video watermarking not available on web. Returning video without watermark.');
        return _createVideoObjectURL(file);
      }

      // Get video dimensions to calculate font size
      final dimensions = await _getVideoDimensions(file);
      final fontSize = _calculateWatermarkFontSize(
        options,
        dimensions['width']!,
        dimensions['height']!,
        defaultSize: 48.0,
      );

      // Call JS function exposed in ffmpeg_watermark.js
      final JSFunction watermarkFunction = addWatermarkToVideo as JSFunction;
      final promise = watermarkFunction.callAsFunction(
        null,
        file.jsify(),
        watermarkText.toJS,
        position.toJS,
        fontSize.toJS,
      ) as JSPromise;
      final url = await promise.toDart as String;
      return url;
    } catch (e) {
      // Fallback to original video without watermark if processing fails
      _log('Video watermarking failed: $e. Returning original video.');
      return _createVideoObjectURL(file);
    }
  }

  Future<String?> _processImageFile(web.File file, MediaOptions options) async {
    final completer = Completer<String?>();
    final reader = web.FileReader();
    reader.addEventListener(
        'load',
        (web.Event event) {
          try {
            final img =
                web.document.createElement('img') as web.HTMLImageElement;
            img.addEventListener(
                'load',
                (web.Event event) {
                  final canvas = web.document.createElement('canvas')
                      as web.HTMLCanvasElement;
                  // Resize logic
                  int width = img.naturalWidth;
                  int height = img.naturalHeight;
                  if (options.maxWidth != null && width > options.maxWidth!) {
                    height = (height * (options.maxWidth! / width)).round();
                    width = options.maxWidth!;
                  }
                  if (options.maxHeight != null &&
                      height > options.maxHeight!) {
                    width = (width * (options.maxHeight! / height)).round();
                    height = options.maxHeight!;
                  }
                  canvas.width = width;
                  canvas.height = height;
                  final ctx =
                      canvas.getContext('2d') as web.CanvasRenderingContext2D;

                  // Apply cropping if specified
                  if (options.cropOptions?.enableCrop == true) {
                    final croppedDimensions = _applyCropToImage(
                        img, ctx, canvas, options.cropOptions!);
                    width = croppedDimensions['width'] as int;
                    height = croppedDimensions['height'] as int;
                  } else {
                    ctx.drawImage(
                        img, 0, 0, width.toDouble(), height.toDouble());
                  }

                  // Watermark
                  if (options.watermark != null &&
                      options.watermark!.isNotEmpty) {
                    _drawWatermark(ctx, width, height, options);
                  }
                  // Quality
                  final quality =
                      (options.imageQuality.clamp(0, 100)).toDouble() / 100.0;
                  final dataUrl =
                      canvas.toDataURL('image/jpeg', quality as dynamic);
                  completer.complete(dataUrl);
                }.toJS);
            img.src = reader.result as String;
          } catch (e) {
            completer.completeError(e);
          }
        }.toJS);
    reader.readAsDataURL(file);
    return completer.future;
  }

  /// Calculate watermark font size from options.
  /// If watermarkFontSizePercentage is provided, calculates based on shorter edge.
  /// Otherwise, uses watermarkFontSize or default value.
  double _calculateWatermarkFontSize(
      MediaOptions options, int width, int height,
      {double defaultSize = 30.0}) {
    // Check if percentage is provided
    if (options.watermarkFontSizePercentage != null) {
      final shorterEdge = width < height ? width : height;
      return shorterEdge * (options.watermarkFontSizePercentage! / 100.0);
    }

    // Fall back to absolute font size
    return options.watermarkFontSize ?? defaultSize;
  }

  void _drawWatermark(web.CanvasRenderingContext2D ctx, int width, int height,
      MediaOptions options) {
    final text = options.watermark ?? '';
    final fontSize = _calculateWatermarkFontSize(options, width, height);
    ctx.font = '${fontSize}px Arial';
    ctx.textBaseline = 'bottom';
    ctx.globalAlpha = 0.7;
    ctx.fillStyle = 'white' as dynamic;
    ctx.strokeStyle = 'black' as dynamic;
    ctx.lineWidth = 2;
    final metrics = ctx.measureText(text);

    // Calculate 2% padding based on shorter edge for non-center positions
    final shorterEdge = width < height ? width : height;
    final edgePadding = shorterEdge * 0.02; // 2% of shorter edge

    double x = width - metrics.width - edgePadding;
    double y = height - edgePadding;

    switch (options.watermarkPosition) {
      case 'topLeft':
        x = edgePadding;
        y = fontSize + edgePadding;
        break;
      case 'topCenter':
        x = (width - metrics.width) / 2;
        y = fontSize + edgePadding;
        break;
      case 'topRight':
        x = width - metrics.width - edgePadding;
        y = fontSize + edgePadding;
        break;
      case 'middleLeft':
        x = edgePadding;
        y = (height + fontSize) / 2;
        break;
      case 'middleCenter':
        x = (width - metrics.width) / 2;
        y = (height + fontSize) / 2;
        break;
      case 'middleRight':
        x = width - metrics.width - edgePadding;
        y = (height + fontSize) / 2;
        break;
      case 'bottomLeft':
        x = edgePadding;
        y = height - edgePadding;
        break;
      case 'bottomCenter':
        x = (width - metrics.width) / 2;
        y = height - edgePadding;
        break;
      case 'bottomRight':
      default:
        x = width - metrics.width - edgePadding;
        y = height - edgePadding;
        break;
    }
    ctx.strokeText(text, x, y);
    ctx.fillText(text, x, y);
    ctx.globalAlpha = 1.0;
  }

  Map<String, int> _applyCropToImage(
      web.HTMLImageElement img,
      web.CanvasRenderingContext2D ctx,
      web.HTMLCanvasElement canvas,
      CropOptions cropOptions) {
    final originalWidth = img.naturalWidth;
    final originalHeight = img.naturalHeight;

    if (cropOptions.cropRect != null) {
      // Use specified crop rectangle
      final rect = cropOptions.cropRect!;
      final cropX = (rect.x * originalWidth).round();
      final cropY = (rect.y * originalHeight).round();
      final cropWidth = (rect.width * originalWidth).round();
      final cropHeight = (rect.height * originalHeight).round();

      // Ensure crop bounds are within image bounds
      final clampedX = cropX.clamp(0, originalWidth);
      final clampedY = cropY.clamp(0, originalHeight);
      final clampedWidth = (cropWidth).clamp(0, originalWidth - clampedX);
      final clampedHeight = (cropHeight).clamp(0, originalHeight - clampedY);

      canvas.width = clampedWidth;
      canvas.height = clampedHeight;

      ctx.drawImage(
          img,
          clampedX.toDouble(),
          clampedY.toDouble(),
          clampedWidth.toDouble(),
          clampedHeight.toDouble(),
          0,
          0,
          clampedWidth.toDouble(),
          clampedHeight.toDouble());

      return {'width': clampedWidth, 'height': clampedHeight};
    } else if (cropOptions.aspectRatio != null) {
      // Apply aspect ratio cropping
      final targetAspectRatio = cropOptions.aspectRatio!;
      final originalAspectRatio = originalWidth / originalHeight;

      int cropX, cropY, cropWidth, cropHeight;

      if (originalAspectRatio > targetAspectRatio) {
        // Original is wider, crop width
        cropHeight = originalHeight;
        cropWidth = (originalHeight * targetAspectRatio).round();
        cropX = ((originalWidth - cropWidth) / 2).round();
        cropY = 0;
      } else {
        // Original is taller, crop height
        cropWidth = originalWidth;
        cropHeight = (originalWidth / targetAspectRatio).round();
        cropX = 0;
        cropY = ((originalHeight - cropHeight) / 2).round();
      }

      canvas.width = cropWidth;
      canvas.height = cropHeight;

      ctx.drawImage(
          img,
          cropX.toDouble(),
          cropY.toDouble(),
          cropWidth.toDouble(),
          cropHeight.toDouble(),
          0,
          0,
          cropWidth.toDouble(),
          cropHeight.toDouble());

      return {'width': cropWidth, 'height': cropHeight};
    } else {
      // No cropping, just draw normally
      ctx.drawImage(
          img, 0, 0, originalWidth.toDouble(), originalHeight.toDouble());
      return {'width': originalWidth, 'height': originalHeight};
    }
  }

  @override
  Future<String?> pickFile(
      MediaOptions options, List<String>? allowedExtensions) async {
    final completer = Completer<String?>();
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.style.display = 'none';
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      input.accept =
          allowedExtensions.map((e) => e.startsWith('.') ? e : '.$e').join(',');
    } else {
      input.accept = '*/*';
    }
    input.addEventListener(
        'change',
        (web.Event event) {
          final files = input.files;
          if (files != null && files.length > 0) {
            final file = files.item(0);
            if (file == null) {
              completer.complete(null);
              return;
            }
            try {
              final url = _createVideoObjectURL(file);
              completer.complete(url);
            } catch (e) {
              completer.completeError(e);
            }
          } else {
            completer.complete(null);
          }
        }.toJS);
    if (web.document.body != null) {
      web.document.body!.appendChild(input);
    }
    input.click();
    input.remove();
    return completer.future;
  }

  @override
  Future<List<String>?> pickMultipleFiles(
      MediaOptions options, List<String>? allowedExtensions) async {
    final completer = Completer<List<String>?>();
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.multiple = true;
    input.style.display = 'none';
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      input.accept =
          allowedExtensions.map((e) => e.startsWith('.') ? e : '.$e').join(',');
    } else {
      input.accept = '*/*';
    }
    input.addEventListener(
        'change',
        (web.Event event) {
          final files = input.files;
          if (files != null && files.length > 0) {
            final urls = <String>[];
            for (var i = 0; i < files.length; i++) {
              final file = files.item(i);
              if (file != null) {
                try {
                  // Check if it's a video file based on accept attribute
                  if (input.accept.contains('video/')) {
                    urls.add(_createVideoObjectURL(file));
                  } else {
                    urls.add(web.URL.createObjectURL(file));
                  }
                } catch (e) {
                  _log(
                      'Failed to create object URL for file: ${file.name}, error: $e');
                  // Skip this file but continue with others
                }
              }
            }
            completer.complete(urls);
          } else {
            completer.complete(null);
          }
        }.toJS);
    if (web.document.body != null) {
      web.document.body!.appendChild(input);
    }
    input.click();
    input.remove();
    return completer.future;
  }

  @override
  Future<List<String>?> pickMultipleMedia(
      MediaSource source, MediaType type, MediaOptions options) async {
    if (source == MediaSource.camera) {
      throw Exception(
          'Multiple media capture from camera not supported on web');
    }
    final completer = Completer<List<String>?>();
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.multiple = true;
    input.style.display = 'none';
    switch (type) {
      case MediaType.image:
        input.accept = 'image/*';
        break;
      case MediaType.video:
        input.accept = 'video/*';
        break;
      default:
        input.accept = '*/*';
    }
    input.addEventListener(
        'change',
        (web.Event event) {
          final files = input.files;
          if (files != null && files.length > 0) {
            final results = <String>[];
            var completed = 0;
            final totalFiles = files.length;

            for (var i = 0; i < files.length; i++) {
              final file = files.item(i);
              if (file == null) {
                completed++;
                if (completed == totalFiles) {
                  completer.complete(results);
                }
                continue;
              }

              if (type == MediaType.image) {
                _processImageFile(file, options).then((result) {
                  if (result != null) results.add(result);
                  completed++;
                  if (completed == totalFiles) {
                    completer.complete(results);
                  }
                }).catchError((e) {
                  completed++;
                  if (completed == totalFiles) {
                    completer.complete(results);
                  }
                });
              } else if (type == MediaType.video) {
                _processVideoFileWithWatermark(file, options).then((url) {
                  if (url != null) results.add(url);
                  completed++;
                  if (completed == totalFiles) {
                    completer.complete(results);
                  }
                }).catchError((e) {
                  completed++;
                  if (completed == totalFiles) {
                    completer.complete(results);
                  }
                });
              } else {
                completed++;
                if (completed == totalFiles) {
                  completer.complete(results);
                }
              }
            }
          } else {
            completer.complete(null);
          }
        }.toJS);
    if (web.document.body != null) {
      web.document.body!.appendChild(input);
    }
    input.click();
    input.remove();
    return completer.future;
  }

  @override
  Future<String?> processImage(String imagePath, MediaOptions options) async {
    try {
      // For web, the imagePath is typically a data URL
      if (!imagePath.startsWith('data:image')) {
        return imagePath; // Return as-is if not a data URL
      }

      // Create an image element to process the data URL
      final img = web.HTMLImageElement();
      final completer = Completer<String?>();

      img.onLoad.listen((_) async {
        try {
          final canvas = web.HTMLCanvasElement();
          final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;

          // Apply crop options if provided
          if (options.cropOptions?.enableCrop == true &&
              options.cropOptions?.cropRect != null) {
            final cropDimensions =
                _applyCropToImage(img, ctx, canvas, options.cropOptions!);
            canvas.width = cropDimensions['width']!;
            canvas.height = cropDimensions['height']!;
          } else {
            // No cropping, use original dimensions
            canvas.width = img.naturalWidth;
            canvas.height = img.naturalHeight;
            ctx.drawImage(img, 0, 0);
          }

          // Apply watermark if provided
          if (options.watermark != null && options.watermark!.isNotEmpty) {
            _drawWatermark(ctx, canvas.width, canvas.height, options);
          }

          // Convert to data URL with quality settings
          final dataUrl = canvas.toDataURL('image/jpeg');
          completer.complete(dataUrl);
        } catch (e) {
          completer.complete(imagePath); // Return original on error
        }
      });

      img.onError.listen((_) {
        completer.complete(imagePath); // Return original on error
      });

      img.src = imagePath;
      return await completer.future;
    } catch (e) {
      return imagePath; // Return original on error
    }
  }

  @override
  Future<String?> addWatermarkToImage(
      String imagePath, MediaOptions options) async {
    try {
      // Check if watermark is specified
      if (options.watermark == null || options.watermark!.isEmpty) {
        throw Exception('Watermark text is required');
      }

      // For web, the imagePath could be a data URL, blob URL, or object URL
      final img = web.HTMLImageElement();
      final completer = Completer<String?>();

      img.onLoad.listen((_) async {
        try {
          final canvas = web.HTMLCanvasElement();
          canvas.width = img.naturalWidth;
          canvas.height = img.naturalHeight;

          final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;

          // Draw the original image
          ctx.drawImage(img, 0, 0);

          // Add watermark
          _drawWatermark(ctx, canvas.width, canvas.height, options);

          // Convert to data URL with quality settings
          final quality =
              (options.imageQuality.clamp(0, 100)).toDouble() / 100.0;
          final dataUrl = canvas.toDataURL('image/jpeg', quality as dynamic);
          completer.complete(dataUrl);
        } catch (e) {
          completer
              .completeError(Exception('Failed to add watermark to image: $e'));
        }
      });

      img.onError.listen((_) {
        completer.completeError(Exception('Failed to load image'));
      });

      img.src = imagePath;
      return await completer.future;
    } catch (e) {
      throw Exception('Error adding watermark to image: $e');
    }
  }

  @override
  Future<String?> addWatermarkToVideo(
      String videoPath, MediaOptions options) async {
    try {
      // Check if watermark is specified
      if (options.watermark == null || options.watermark!.isEmpty) {
        throw Exception('Watermark text is required');
      }

      // For web video watermarking, we need to use the JavaScript function
      final watermarkText = options.watermark!;
      final position = options.watermarkPosition ?? 'bottomRight';

      // Check if the watermarking function exists
      final addWatermarkToVideoFunc =
          globalThis.getProperty('addWatermarkToVideo'.toJS);
      if (addWatermarkToVideoFunc.isUndefined ||
          addWatermarkToVideoFunc.isNull) {
        throw Exception(
            'Video watermarking function not available on web. Please include ffmpeg_watermark.js');
      }

      // Get video dimensions to calculate font size
      final dimensions = await _getVideoDimensions(videoPath);
      final fontSize = _calculateWatermarkFontSize(
        options,
        dimensions['width']!,
        dimensions['height']!,
        defaultSize: 48.0,
      );

      // Create a File object from the video path (assuming it's a blob URL)
      // This is a simplified approach - in a real scenario you might need to
      // fetch the blob and create a File object
      _log('Adding watermark to video: $videoPath');

      try {
        // Call JS function exposed in ffmpeg_watermark.js
        final JSFunction watermarkFunction =
            addWatermarkToVideoFunc as JSFunction;
        final promise = watermarkFunction.callAsFunction(
          null,
          videoPath.toJS, // Pass the video path/URL
          watermarkText.toJS,
          position.toJS,
          fontSize.toJS,
        ) as JSPromise;
        final url = await promise.toDart as String;
        return url;
      } catch (e) {
        throw Exception('Failed to add watermark to video: $e');
      }
    } catch (e) {
      throw Exception('Error adding watermark to video: $e');
    }
  }
}
