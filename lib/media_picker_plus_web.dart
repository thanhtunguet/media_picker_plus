// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:media_picker_plus/web_camera_preview.dart';
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
    // Try modern camera API first if available
    if (_shouldUseCameraAPI(type)) {
      _log('Using modern camera API for capture');

      if (type == MediaType.image) {
        return await _capturePhotoWithCameraAPI(options);
      } else if (type == MediaType.video) {
        return await _recordVideoWithCameraAPI(options);
      }
    }

    // Fall back to file input method
    _log('Falling back to file input method');
    return await _captureFromCameraFileInput(type, options);
  }

  /// Legacy file input capture method (fallback)
  Future<String?> _captureFromCameraFileInput(
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

  /// Capture photo using modern Camera API
  Future<String?> _capturePhotoWithCameraAPI(MediaOptions options) async {
    web.MediaStream? stream;
    web.HTMLVideoElement? videoElement;

    try {
      // Step 1: Get camera stream
      stream = await _getCameraStream(facingMode: 'environment');

      if (stream == null) {
        _log('Failed to get camera stream, falling back to file input');
        return await _captureFromCameraFileInput(MediaType.image, options);
      }

      // Step 2: Show camera preview UI and wait for user to capture
      _log('Showing camera preview UI');
      final preview = WebCameraPreview();
      final shouldCapture = await preview.show(stream: stream, isVideo: false);

      if (shouldCapture != true) {
        // User cancelled
        _log('User cancelled photo capture');
        return null;
      }

      // Step 3: Create video element for capturing
      videoElement =
          web.document.createElement('video') as web.HTMLVideoElement;
      videoElement.srcObject = stream;
      videoElement.autoplay = true;
      videoElement.playsInline = true;
      videoElement.style.display = 'none';

      if (web.document.body != null) {
        web.document.body!.appendChild(videoElement);
      }

      // Wait for video to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: Capture photo
      web.Blob? photoBlob;

      // Try ImageCapture API first (best quality)
      if (_supportsImageCapture()) {
        photoBlob = await _capturePhotoWithImageCapture(stream);
        if (photoBlob != null) {
          _log('Photo captured using ImageCapture API');
        }
      }

      // Fallback to canvas snapshot if ImageCapture failed
      if (photoBlob == null) {
        _log('Using canvas snapshot fallback');
        photoBlob = await _capturePhotoFromVideo(videoElement);
      }

      if (photoBlob == null) {
        _log('Failed to capture photo with camera API, falling back');
        return await _captureFromCameraFileInput(MediaType.image, options);
      }

      //  Step 5: Process image (resize, crop, watermark)
      // Create a temporary File-like object from the blob for processing
      final file = web.File([photoBlob].toJS, 'camera_photo.jpg',
          web.FilePropertyBag(type: 'image/jpeg'));
      final processedDataUrl = await _processImageFile(file, options);

      return processedDataUrl;
    } catch (e) {
      _log('Error in camera API photo capture: $e');
      return await _captureFromCameraFileInput(MediaType.image, options);
    } finally {
      // Step 6: Cleanup
      if (stream != null) {
        _stopMediaStream(stream);
      }
      videoElement?.remove();
    }
  }

  /// Record video using modern Camera API
  Future<String?> _recordVideoWithCameraAPI(MediaOptions options) async {
    web.MediaStream? stream;
    _MediaRecorderHelper? recorder;

    try {
      // Step 1: Get camera + microphone stream
      stream = await _getCameraStream(
        facingMode: 'environment',
        includeAudio: true, // Include audio for video
      );

      if (stream == null) {
        _log('Failed to get camera stream, falling back to file input');
        return await _captureFromCameraFileInput(MediaType.video, options);
      }

      // Step 2: Show camera preview UI and wait for user to start recording
      _log('Showing camera preview UI for video');
      final preview = WebCameraPreview();

      // Start recording when user clicks record button
      recorder = _MediaRecorderHelper();
      final started = await recorder.startRecording(stream);

      if (!started) {
        _log('Failed to start recording, falling back');
        return await _captureFromCameraFileInput(MediaType.video, options);
      }

      // Show preview with recording indicator
      final shouldStop = await preview.show(stream: stream, isVideo: true);

      if (shouldStop != true) {
        // User cancelled before stopping
        _log('User cancelled video recording');
        recorder.stopRecording(); // Make sure to stop the recorder
        return null;
      }

      // Step 3: Stop recording and get blob
      final videoBlob = await recorder.stopRecording();

      if (videoBlob == null) {
        _log('Failed to get recorded video, falling back');
        return await _captureFromCameraFileInput(MediaType.video, options);
      }

      _log('Recording stopped, blob size: ${videoBlob.size} bytes');

      // Step 4: Process video (watermark if requested)
      if (options.watermark != null && options.watermark!.isNotEmpty) {
        _log('Processing video with watermark...');
        // Convert blob to File for processing
        final file = web.File(
          [videoBlob].toJS,
          'camera_video.webm',
          web.FilePropertyBag(type: videoBlob.type),
        );

        // Try to add watermark, fall back to original if it fails
        try {
          final watermarkedUrl =
              await _processVideoFileWithWatermark(file, options);
          return watermarkedUrl;
        } catch (e) {
          _log('Watermarking failed: $e, returning original video');
          // Return original video without watermark
          return web.URL.createObjectURL(videoBlob);
        }
      } else {
        // No watermark requested, return blob URL directly
        return web.URL.createObjectURL(videoBlob);
      }
    } catch (e) {
      _log('Error in camera API video recording: $e');
      return await _captureFromCameraFileInput(MediaType.video, options);
    } finally {
      // Step 5: Cleanup
      if (stream != null) {
        _stopMediaStream(stream);
      }
    }
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

  @override
  Future<String?> getThumbnail(
      String videoPath, {
      double timeInSeconds = 1.0,
      MediaOptions? options,
    }) async {
    try {
      _log('Extracting thumbnail from video: $videoPath at ${timeInSeconds}s');
      
      // Create a video element to load the video
      final video = web.document.createElement('video') as web.HTMLVideoElement;
      video.src = videoPath;
      video.crossOrigin = 'anonymous';
      video.muted = true; // Required for autoplay in some browsers
      
      final completer = Completer<String?>();
      
      // Wait for video metadata to be loaded
      video.addEventListener('loadedmetadata', (web.Event event) async {
        try {
          final duration = video.duration;
          _log('Video duration: ${duration}s');
          
          // Ensure the time is within video duration
          final actualTime = timeInSeconds.clamp(0.0, duration - 0.1);
          video.currentTime = actualTime;
          
          // Wait for the video to seek to the specified time
          video.addEventListener('seeked', (web.Event event) async {
            try {
              // Create a canvas to draw the video frame
              final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
              final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
              
              // Set canvas dimensions
              var canvasWidth = video.videoWidth;
              var canvasHeight = video.videoHeight;
              
              // Apply resize options if provided
              if (options != null) {
                final maxWidth = options.maxWidth;
                final maxHeight = options.maxHeight;
                
                if (maxWidth != null && maxHeight != null && 
                    (canvasWidth > maxWidth || canvasHeight > maxHeight)) {
                  final aspectRatio = canvasWidth / canvasHeight;
                  
                  if (canvasWidth > canvasHeight) {
                    canvasWidth = maxWidth;
                    canvasHeight = (maxWidth / aspectRatio).round();
                    if (canvasHeight > maxHeight) {
                      canvasHeight = maxHeight;
                      canvasWidth = (maxHeight * aspectRatio).round();
                    }
                  } else {
                    canvasHeight = maxHeight;
                    canvasWidth = (maxHeight * aspectRatio).round();
                    if (canvasWidth > maxWidth) {
                      canvasWidth = maxWidth;
                      canvasHeight = (maxWidth / aspectRatio).round();
                    }
                  }
                }
              }
              
              canvas.width = canvasWidth;
              canvas.height = canvasHeight;
              
              // Draw the current video frame to canvas
              context.drawImage(video, 0, 0, canvasWidth, canvasHeight);
              
              // Apply watermark if specified
              if (options?.watermark != null && options!.watermark!.isNotEmpty) {
                _addWatermarkToCanvas(context, options.watermark!, canvasWidth, canvasHeight, options);
              }
              
              // Convert canvas to blob
              final quality = options?.imageQuality ?? 80;
              final qualityValue = quality / 100.0;
              
              canvas.toBlob((web.Blob? blob) {
                if (blob != null) {
                  final url = web.URL.createObjectURL(blob);
                  _log('Thumbnail extracted successfully: $url');
                  completer.complete(url);
                } else {
                  completer.completeError('Failed to create blob from canvas');
                }
              }.toJS, 'image/jpeg', qualityValue.toJS);
              
            } catch (e) {
              completer.completeError('Error drawing video frame: $e');
            }
          }.toJS);
          
          // Trigger seek to the specified time
          video.currentTime = actualTime;
          
        } catch (e) {
          completer.completeError('Error seeking video: $e');
        }
      }.toJS);
      
      video.addEventListener('error', (web.Event event) {
        completer.completeError('Error loading video: ${video.error?.message ?? "Unknown error"}');
      }.toJS);
      
      // Start loading the video
      video.load();
      
      return await completer.future;
      
    } catch (e) {
      throw Exception('Error extracting thumbnail: $e');
    }
  }
  
  /// Add watermark to canvas
  void _addWatermarkToCanvas(web.CanvasRenderingContext2D context, String text, 
      int canvasWidth, int canvasHeight, MediaOptions options) {
    try {
      // Calculate font size
      final fontSize = _calculateWatermarkFontSize(options, canvasWidth, canvasHeight, defaultSize: 30.0);
      
      // Set font properties
      context.font = '${fontSize}px Arial';
      context.fillStyle = 'white';
      context.strokeStyle = 'black';
      context.lineWidth = 2;
      context.textBaseline = 'bottom';
      
      // Measure text dimensions
      final textMetrics = context.measureText(text);
      final textWidth = textMetrics.width;
      final textHeight = fontSize;
      
      // Calculate position
      final position = options.watermarkPosition ?? 'bottomRight';
      final padding = (canvasWidth.compareTo(canvasHeight) < 0 ? canvasWidth : canvasHeight) * 0.02;
      
      double x, y;
      switch (position.toLowerCase()) {
        case 'topleft':
          x = padding;
          y = textHeight + padding;
          break;
        case 'topcenter':
          x = (canvasWidth - textWidth) / 2;
          y = textHeight + padding;
          break;
        case 'topright':
          x = canvasWidth - textWidth - padding;
          y = textHeight + padding;
          break;
        case 'middleleft':
          x = padding;
          y = canvasHeight / 2 + textHeight / 2;
          break;
        case 'center':
          x = (canvasWidth - textWidth) / 2;
          y = canvasHeight / 2 + textHeight / 2;
          break;
        case 'middleright':
          x = canvasWidth - textWidth - padding;
          y = canvasHeight / 2 + textHeight / 2;
          break;
        case 'bottomleft':
          x = padding;
          y = canvasHeight - padding;
          break;
        case 'bottomcenter':
          x = (canvasWidth - textWidth) / 2;
          y = canvasHeight - padding;
          break;
        case 'bottomright':
        default:
          x = canvasWidth - textWidth - padding;
          y = canvasHeight - padding;
          break;
      }
      
      // Draw text with stroke (outline) and fill
      context.strokeText(text, x, y);
      context.fillText(text, x, y);
      
    } catch (e) {
      _log('Error adding watermark to canvas: $e');
    }
  }

  // ============================================================================
  // PHASE 1: Browser Capability Detection
  // ============================================================================

  /// Check if getUserMedia is supported
  bool _supportsGetUserMedia() {
    try {
      // Simply check if mediaDevices exists - getUserMedia is a standard method on it
      // We can't directly check the method due to JS interop limitations
      final _ = web.window.navigator.mediaDevices;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if ImageCapture API is supported
  bool _supportsImageCapture() {
    try {
      return globalThis.has('ImageCapture');
    } catch (e) {
      return false;
    }
  }

  /// Check if MediaRecorder is supported
  bool _supportsMediaRecorder() {
    try {
      return globalThis.has('MediaRecorder');
    } catch (e) {
      return false;
    }
  }

  /// Check if site is running in secure context (HTTPS or localhost)
  bool _isSecureContext() {
    return web.window.isSecureContext;
  }

  /// Check if modern camera API is available and should be used
  bool _shouldUseCameraAPI(MediaType type) {
    // Must have getUserMedia support
    if (!_supportsGetUserMedia()) {
      return false;
    }

    // Must be in secure context (HTTPS or localhost)
    if (!_isSecureContext()) {
      _log('Camera API requires HTTPS or localhost');
      return false;
    }

    // For images, we can use getUserMedia even without ImageCapture
    // (fall back to canvas snapshot)
    if (type == MediaType.image) {
      return true;
    }

    // For video, we need MediaRecorder
    if (type == MediaType.video) {
      return _supportsMediaRecorder();
    }

    return false;
  }

  // ============================================================================
  // PHASE 2: Camera API Helpers
  // ============================================================================

  /// Request camera access and get MediaStream
  Future<web.MediaStream?> _getCameraStream({
    String facingMode =
        'environment', // 'user' for front, 'environment' for back
    bool includeAudio = false,
  }) async {
    if (!_supportsGetUserMedia()) {
      return null;
    }

    if (!_isSecureContext()) {
      _log('Warning: getUserMedia requires HTTPS or localhost');
      return null;
    }

    try {
      final videoConstraints = {
        'facingMode': facingMode,
      };

      final constraints = {
        'video': videoConstraints,
        'audio': includeAudio,
      };

      final mediaDevices = web.window.navigator.mediaDevices;
      final stream = await mediaDevices
          .getUserMedia(constraints.jsify()! as web.MediaStreamConstraints)
          .toDart;

      return stream;
    } catch (e) {
      _log('Error getting camera stream: $e');
      return null;
    }
  }

  /// Capture photo using ImageCapture API
  Future<web.Blob?> _capturePhotoWithImageCapture(
    web.MediaStream stream,
  ) async {
    if (!_supportsImageCapture()) {
      return null;
    }

    try {
      final videoTracks = stream.getVideoTracks().toDart;
      if (videoTracks.isEmpty) {
        return null;
      }

      final videoTrack = videoTracks[0];

      // Create ImageCapture instance using JavaScript interop
      final imageCaptureConstructor =
          globalThis.getProperty('ImageCapture'.toJS) as JSFunction;
      final imageCapture =
          imageCaptureConstructor.callAsConstructor(videoTrack.jsify());

      // Call takePhoto method
      final takePhotoMethod =
          imageCapture.getProperty('takePhoto'.toJS) as JSFunction;
      final promise = takePhotoMethod.callAsFunction(imageCapture) as JSPromise;

      final blob = await promise.toDart as web.Blob;
      return blob;
    } catch (e) {
      _log('Error capturing photo with ImageCapture: $e');
      return null;
    }
  }

  /// Fallback: Capture photo by drawing video frame to canvas
  Future<web.Blob?> _capturePhotoFromVideo(
    web.HTMLVideoElement videoElement,
  ) async {
    try {
      final canvas =
          web.document.createElement('canvas') as web.HTMLCanvasElement;
      canvas.width = videoElement.videoWidth;
      canvas.height = videoElement.videoHeight;

      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
      ctx.drawImage(videoElement, 0, 0);

      final completer = Completer<web.Blob?>();

      canvas.toBlob(
          (web.Blob? blob) {
            completer.complete(blob);
          }.toJS,
          'image/jpeg',
          0.95.toJS);

      return await completer.future;
    } catch (e) {
      _log('Error capturing photo from video: $e');
      return null;
    }
  }

  /// Stop all tracks in a media stream
  void _stopMediaStream(web.MediaStream? stream) {
    if (stream == null) return;

    try {
      final tracks = stream.getTracks().toDart;
      for (final track in tracks) {
        (track).stop();
      }
    } catch (e) {
      _log('Error stopping media stream: $e');
    }
  }
}

/// Helper class for MediaRecorder operations
class _MediaRecorderHelper {
  web.MediaRecorder? _recorder;
  final List<web.Blob> _chunks = [];
  final Completer<web.Blob?> _completer = Completer();

  /// Start recording from a media stream
  Future<bool> startRecording(web.MediaStream stream) async {
    try {
      // Try video/webm first, will use default if not supported
      _recorder = web.MediaRecorder(stream);

      _recorder!.addEventListener(
          'dataavailable',
          (web.Event event) {
            final blobEvent = event as web.BlobEvent;
            final data = blobEvent.data;
            if (data.size > 0) {
              _chunks.add(data);
            }
          }.toJS);

      _recorder!.addEventListener(
          'stop',
          (web.Event event) {
            if (_chunks.isNotEmpty) {
              final blob = web.Blob(
                _chunks.toJS,
                web.BlobPropertyBag(type: 'video/webm'),
              );
              _completer.complete(blob);
            } else {
              _completer.complete(null);
            }
          }.toJS);

      _recorder!.start();
      return true;
    } catch (e) {
      _log('Error starting MediaRecorder: $e');
      return false;
    }
  }

  /// Stop recording and get the blob
  Future<web.Blob?> stopRecording() async {
    if (_recorder == null) {
      return null;
    }

    try {
      _recorder!.stop();
      return await _completer.future;
    } catch (e) {
      _log('Error stopping MediaRecorder: $e');
      return null;
    }
  }

  /// Check if currently recording
  bool get isRecording {
    return _recorder?.state == 'recording';
  }
}
