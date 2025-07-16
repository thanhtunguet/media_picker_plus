// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'media_picker_plus_platform_interface.dart';
import 'media_options.dart';
import 'media_source.dart';
import 'media_type.dart';

/// A web implementation of the MediaPickerPlusPlatform of the MediaPickerPlus plugin.
class MediaPickerPlusWeb extends MediaPickerPlusPlatform {
  /// Constructs a MediaPickerPlusWeb
  MediaPickerPlusWeb();

  static void registerWith(Registrar registrar) {
    MediaPickerPlusPlatform.instance = MediaPickerPlusWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  @override
  Future<String?> pickMedia(MediaSource source, MediaType type, MediaOptions options) async {
    try {
      switch (source) {
        case MediaSource.gallery:
          return await _pickFromGallery(type, options);
        case MediaSource.camera:
          return await _captureFromCamera(type, options);
        default:
          throw Exception('Unsupported source: $source');
      }
    } catch (e) {
      throw Exception('Error picking media: $e');
    }
  }

  @override
  Future<bool> hasCameraPermission() async {
    try {
      // For web, we'll assume camera permission is available
      // In a real implementation, you'd check navigator.mediaDevices
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestCameraPermission() async {
    return await hasCameraPermission();
  }

  @override
  Future<bool> hasGalleryPermission() async {
    // Web doesn't require explicit permission for file picker
    return true;
  }

  @override
  Future<bool> requestGalleryPermission() async {
    // Web doesn't require explicit permission for file picker
    return true;
  }

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
    input.addEventListener('change', (event) async {
      final files = input.files;
      if (files != null && files.length > 0) {
        final file = files.item(0);
        try {
          String? result;
          if (type == MediaType.image) {
            result = await _processImageFile(file, options);
          } else if (type == MediaType.video) {
            result = await _processVideoFile(file, options);
          }
          completer.complete(result);
        } catch (e) {
          completer.completeError(e);
        }
      } else {
        completer.complete(null);
      }
    });
    web.document.body.appendChild(input);
    input.click();
    input.remove();
    return completer.future;
  }

  Future<String?> _captureFromCamera(MediaType type, MediaOptions options) async {
    // For web implementation, we'll use a simplified approach
    // In a real implementation, you'd want to use getUserMedia properly
    throw Exception('Camera capture not fully implemented for web platform');
  }



  Future<String?> _processImageFile(web.File file, MediaOptions options) async {
    final completer = Completer<String?>();
    final reader = web.FileReader();
    reader.addEventListener('load', (event) async {
      try {
        final img = web.document.createElement('img') as web.HTMLImageElement;
        img.addEventListener('load', (event) {
          final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
          canvas.width = img.naturalWidth;
          canvas.height = img.naturalHeight;
          final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
          context.drawImage(img, 0, 0);
          if (options.maxWidth != null || options.maxHeight != null) {
            final resizedCanvas = _resizeCanvas(canvas, options.maxWidth, options.maxHeight);
            canvas.width = resizedCanvas.width;
            canvas.height = resizedCanvas.height;
            (canvas.getContext('2d') as web.CanvasRenderingContext2D).drawImage(resizedCanvas, 0, 0);
          }
          if (options.watermark != null) {
            _addWatermarkToCanvas(canvas, options.watermark!, options.watermarkPosition);
          }
          final dataUrl = canvas.toDataURL('image/jpeg', (options.imageQuality / 100));
          completer.complete(dataUrl);
        });
        img.src = reader.result as String;
      } catch (e) {
        completer.completeError(e);
      }
    });
    reader.readAsDataURL(file);
    return completer.future;
  }

  Future<String?> _processVideoFile(web.File file, MediaOptions options) async {
    // Watermarking not implemented for video
    final url = web.window.URL.createObjectURL(file);
    return url;
  }

  // Removed unused _processVideoBlob method

  web.HTMLCanvasElement _resizeCanvas(web.HTMLCanvasElement canvas, int? maxWidth, int? maxHeight) {
    final currentWidth = canvas.width;
    final currentHeight = canvas.height;
    if (maxWidth == null && maxHeight == null) {
      return canvas;
    }
    double ratio = 1.0;
    if (maxWidth != null && maxHeight != null) {
      final widthRatio = maxWidth / currentWidth;
      final heightRatio = maxHeight / currentHeight;
      ratio = [widthRatio, heightRatio].reduce((a, b) => a < b ? a : b);
    } else if (maxWidth != null) {
      ratio = maxWidth / currentWidth;
    } else if (maxHeight != null) {
      ratio = maxHeight / currentHeight;
    }
    if (ratio >= 1.0) {
      return canvas;
    }
    final newWidth = (currentWidth * ratio).round();
    final newHeight = (currentHeight * ratio).round();
    final resizedCanvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
    resizedCanvas.width = newWidth;
    resizedCanvas.height = newHeight;
    final context = resizedCanvas.getContext('2d') as web.CanvasRenderingContext2D;
    context.drawImage(canvas, 0, 0, newWidth.toDouble(), newHeight.toDouble());
    return resizedCanvas;
  }

  void _addWatermarkToCanvas(web.HTMLCanvasElement canvas, String text, String? position) {
    final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    final canvasWidth = canvas.width;
    final canvasHeight = canvas.height;
    context.font = '24px Arial';
    context.fillStyle = 'white';
    context.strokeStyle = 'black';
    context.lineWidth = 2;
    final textMetrics = context.measureText(text);
    final textWidth = textMetrics.width;
    const textHeight = 24.0;
    const margin = 20.0;
    double x, y;
    switch (position ?? 'bottomRight') {
      case 'topLeft':
        x = margin;
        y = margin + textHeight;
        break;
      case 'topCenter':
        x = (canvasWidth - textWidth) / 2;
        y = margin + textHeight;
        break;
      case 'topRight':
        x = canvasWidth - textWidth - margin;
        y = margin + textHeight;
        break;
      case 'middleLeft':
        x = margin;
        y = (canvasHeight + textHeight) / 2;
        break;
      case 'middleCenter':
        x = (canvasWidth - textWidth) / 2;
        y = (canvasHeight + textHeight) / 2;
        break;
      case 'middleRight':
        x = canvasWidth - textWidth - margin;
        y = (canvasHeight + textHeight) / 2;
        break;
      case 'bottomLeft':
        x = margin;
        y = canvasHeight - margin;
        break;
      case 'bottomCenter':
        x = (canvasWidth - textWidth) / 2;
        y = canvasHeight - margin;
        break;
      default:
        x = canvasWidth - textWidth - margin;
        y = canvasHeight - margin;
    }
    context.strokeText(text, x, y);
    context.fillText(text, x, y);
  }

  @override
  Future<String?> pickFile(MediaOptions options, List<String>? allowedExtensions) async {
    final completer = Completer<String?>();
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.style.display = 'none';
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      input.accept = allowedExtensions.map((ext) => ext.startsWith('.') ? ext : '.$ext').join(',');
    } else {
      input.accept = '*/*';
    }
    input.addEventListener('change', (event) async {
      final files = input.files;
      if (files != null && files.length > 0) {
        final file = files.item(0);
        final url = web.window.URL.createObjectURL(file);
        completer.complete(url);
      } else {
        completer.complete(null);
      }
    });
    web.document.body.appendChild(input);
    input.click();
    input.remove();
    return completer.future;
  }

  @override
  Future<List<String>?> pickMultipleFiles(MediaOptions options, List<String>? allowedExtensions) async {
    final completer = Completer<List<String>?>();
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.multiple = true;
    input.style.display = 'none';
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      input.accept = allowedExtensions.map((ext) => ext.startsWith('.') ? ext : '.$ext').join(',');
    } else {
      input.accept = '*/*';
    }
    input.addEventListener('change', (event) async {
      final files = input.files;
      if (files != null && files.length > 0) {
        final urls = <String>[];
        for (int i = 0; i < files.length; i++) {
          final file = files.item(i);
          final url = web.window.URL.createObjectURL(file);
          urls.add(url);
        }
        completer.complete(urls);
      } else {
        completer.complete(null);
      }
    });
    web.document.body.appendChild(input);
    input.click();
    input.remove();
    return completer.future;
  }

  @override
  Future<List<String>?> pickMultipleMedia(MediaSource source, MediaType type, MediaOptions options) async {
    if (source == MediaSource.camera) {
      throw Exception('Multiple media capture from camera not supported on web');
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
    input.addEventListener('change', (event) async {
      final files = input.files;
      if (files != null && files.length > 0) {
        try {
          final results = <String>[];
          for (int i = 0; i < files.length; i++) {
            final file = files.item(i);
            String? result;
            if (type == MediaType.image) {
              result = await _processImageFile(file, options);
            } else if (type == MediaType.video) {
              result = await _processVideoFile(file, options);
            }
            if (result != null) {
              results.add(result);
            }
          }
          completer.complete(results);
        } catch (e) {
          completer.completeError(e);
        }
      } else {
        completer.complete(null);
      }
    });
    web.document.body.appendChild(input);
    input.click();
    input.remove();
    return completer.future;
  }
}
