// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

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
    
    final input = html.InputElement()
      ..type = 'file'
      ..style.display = 'none';
    
    // Set accept attribute based on media type
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
    
    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
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
    
    html.document.body!.append(input);
    input.click();
    input.remove();
    
    return completer.future;
  }

  Future<String?> _captureFromCamera(MediaType type, MediaOptions options) async {
    // For web implementation, we'll use a simplified approach
    // In a real implementation, you'd want to use getUserMedia properly
    throw Exception('Camera capture not fully implemented for web platform');
  }

  void _stopStream(html.MediaStream stream) {
    // Stop stream implementation would go here
  }

  Future<String> _capturePhoto(html.VideoElement video, MediaOptions options) async {
    final canvas = html.CanvasElement()
      ..width = video.videoWidth
      ..height = video.videoHeight;
    
    final context = canvas.context2D;
    context.drawImage(video, 0, 0);
    
    // Apply processing
    if (options.maxWidth != null || options.maxHeight != null) {
      final resizedCanvas = _resizeCanvas(canvas, options.maxWidth, options.maxHeight);
      canvas.width = resizedCanvas.width;
      canvas.height = resizedCanvas.height;
      canvas.context2D.drawImage(resizedCanvas, 0, 0);
    }
    
    if (options.watermark != null) {
      _addWatermarkToCanvas(canvas, options.watermark!, options.watermarkPosition);
    }
    
    final dataUrl = canvas.toDataUrl('image/jpeg', (options.imageQuality / 100).toDouble());
    return dataUrl;
  }

  Future<String?> _processImageFile(html.File file, MediaOptions options) async {
    final completer = Completer<String?>();
    
    final reader = html.FileReader();
    reader.onLoad.listen((event) async {
      try {
        final img = html.ImageElement();
        img.onLoad.listen((event) {
          final canvas = html.CanvasElement()
            ..width = img.naturalWidth
            ..height = img.naturalHeight;
          
          final context = canvas.context2D;
          context.drawImage(img, 0, 0);
          
          // Apply processing
          if (options.maxWidth != null || options.maxHeight != null) {
            final resizedCanvas = _resizeCanvas(canvas, options.maxWidth, options.maxHeight);
            canvas.width = resizedCanvas.width;
            canvas.height = resizedCanvas.height;
            canvas.context2D.drawImage(resizedCanvas, 0, 0);
          }
          
          if (options.watermark != null) {
            _addWatermarkToCanvas(canvas, options.watermark!, options.watermarkPosition);
          }
          
          final dataUrl = canvas.toDataUrl('image/jpeg', (options.imageQuality / 100).toDouble());
          completer.complete(dataUrl);
        });
        
        img.src = reader.result as String;
      } catch (e) {
        completer.completeError(e);
      }
    });
    
    reader.readAsDataUrl(file);
    return completer.future;
  }

  Future<String?> _processVideoFile(html.File file, MediaOptions options) async {
    if (options.watermark != null) {
      // For video watermarking, we'd need a more complex implementation
      // For now, we'll just return the video URL
      return html.Url.createObjectUrlFromBlob(file);
    }
    return html.Url.createObjectUrlFromBlob(file);
  }

  Future<String?> _processVideoBlob(html.Blob blob, MediaOptions options) async {
    if (options.watermark != null) {
      // For video watermarking, we'd need a more complex implementation
      // For now, we'll just return the video URL
      return html.Url.createObjectUrlFromBlob(blob);
    }
    return html.Url.createObjectUrlFromBlob(blob);
  }

  html.CanvasElement _resizeCanvas(html.CanvasElement canvas, int? maxWidth, int? maxHeight) {
    final currentWidth = canvas.width!;
    final currentHeight = canvas.height!;
    
    if (maxWidth == null && maxHeight == null) {
      return canvas;
    }
    
    double ratio = 1.0;
    if (maxWidth != null && maxHeight != null) {
      final widthRatio = maxWidth.toDouble() / currentWidth;
      final heightRatio = maxHeight.toDouble() / currentHeight;
      ratio = [widthRatio, heightRatio].reduce((a, b) => a < b ? a : b);
    } else if (maxWidth != null) {
      ratio = maxWidth.toDouble() / currentWidth;
    } else if (maxHeight != null) {
      ratio = maxHeight.toDouble() / currentHeight;
    }
    
    if (ratio >= 1.0) {
      return canvas;
    }
    
    final newWidth = (currentWidth * ratio).round();
    final newHeight = (currentHeight * ratio).round();
    
    final resizedCanvas = html.CanvasElement()
      ..width = newWidth
      ..height = newHeight;
    
    final context = resizedCanvas.context2D;
    context.drawImageScaled(canvas, 0, 0, newWidth, newHeight);
    
    return resizedCanvas;
  }

  void _addWatermarkToCanvas(html.CanvasElement canvas, String text, String? position) {
    final context = canvas.context2D;
    final canvasWidth = canvas.width!;
    final canvasHeight = canvas.height!;
    
    // Setup text style
    context.font = '24px Arial';
    context.fillStyle = 'white';
    context.strokeStyle = 'black';
    context.lineWidth = 2;
    
    final textMetrics = context.measureText(text);
    final textWidth = textMetrics.width!;
    const textHeight = 24.0; // font size
    
    // Calculate position
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
      default: // bottomRight
        x = canvasWidth - textWidth - margin;
        y = canvasHeight - margin;
    }
    
    // Draw text with stroke
    context.strokeText(text, x, y);
    context.fillText(text, x, y);
  }

  @override
  Future<String?> pickFile(MediaOptions options, List<String>? allowedExtensions) async {
    final completer = Completer<String?>();
    
    final input = html.InputElement()
      ..type = 'file'
      ..style.display = 'none';
    
    // Set accept attribute based on allowed extensions
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      input.accept = allowedExtensions.map((ext) => ext.startsWith('.') ? ext : '.$ext').join(',');
    } else {
      input.accept = '*/*';
    }
    
    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final url = html.Url.createObjectUrlFromBlob(file);
        completer.complete(url);
      } else {
        completer.complete(null);
      }
    });
    
    html.document.body!.append(input);
    input.click();
    input.remove();
    
    return completer.future;
  }

  @override
  Future<List<String>?> pickMultipleFiles(MediaOptions options, List<String>? allowedExtensions) async {
    final completer = Completer<List<String>?>();
    
    final input = html.InputElement()
      ..type = 'file'
      ..multiple = true
      ..style.display = 'none';
    
    // Set accept attribute based on allowed extensions
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      input.accept = allowedExtensions.map((ext) => ext.startsWith('.') ? ext : '.$ext').join(',');
    } else {
      input.accept = '*/*';
    }
    
    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final urls = <String>[];
        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          final url = html.Url.createObjectUrlFromBlob(file);
          urls.add(url);
        }
        completer.complete(urls);
      } else {
        completer.complete(null);
      }
    });
    
    html.document.body!.append(input);
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
    
    final input = html.InputElement()
      ..type = 'file'
      ..multiple = true
      ..style.display = 'none';
    
    // Set accept attribute based on media type
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
    
    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        try {
          final results = <String>[];
          for (int i = 0; i < files.length; i++) {
            final file = files[i];
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
    
    html.document.body!.append(input);
    input.click();
    input.remove();
    
    return completer.future;
  }
}
