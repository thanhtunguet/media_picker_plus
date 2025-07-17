// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_util' as js_util;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'media_options.dart';
import 'media_picker_plus_platform_interface.dart';
import 'media_source.dart';
import 'media_type.dart';

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
        (event) async {
          final files = input.files;
          if (files != null && files.length > 0) {
            final file = files.item(0);
            if (file == null) {
              completer.complete(null);
              return;
            }
            try {
              if (type == MediaType.image) {
                final result = await _processImageFile(file, options);
                completer.complete(result);
              } else if (type == MediaType.video) {
                final url = web.URL.createObjectURL(file);
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
        } as web.EventListener);
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
        (event) async {
          final files = input.files;
          if (files != null && files.length > 0) {
            final file = files.item(0);
            if (file == null) {
              completer.complete(null);
              return;
            }
            try {
              if (type == MediaType.image) {
                final result = await _processImageFile(file, options);
                completer.complete(result);
              } else if (type == MediaType.video) {
                final url = await _processVideoFileWithWatermark(file, options);
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
        } as web.EventListener);
    if (web.document.body != null) {
      web.document.body!.appendChild(input);
    }
    input.click();
    input.remove();
    return completer.future;
  }

  Future<String?> _processVideoFileWithWatermark(
      web.File file, MediaOptions options) async {
    if (options.watermark == null || options.watermark!.isEmpty) {
      // No watermark, just return object URL
      return web.URL.createObjectURL(file);
    }
    final watermarkText = options.watermark!;
    final position = options.watermarkPosition ?? 'bottomRight';
    // Call JS function exposed in ffmpeg_watermark.js
    final promise = js_util.callMethod(
      js_util.globalThis,
      'addWatermarkToVideo',
      [file, watermarkText, position],
    );
    final url = await js_util.promiseToFuture<String>(promise);
    return url;
  }

  Future<String?> _processImageFile(web.File file, MediaOptions options) async {
    final completer = Completer<String?>();
    final reader = web.FileReader();
    reader.addEventListener(
        'load',
        (event) async {
          try {
            final img =
                web.document.createElement('img') as web.HTMLImageElement;
            img.addEventListener(
                'load',
                (event) {
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
                  ctx.drawImage(img, 0, 0, width.toDouble(), height.toDouble());
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
                } as web.EventListener);
            img.src = reader.result as String;
          } catch (e) {
            completer.completeError(e);
          }
        } as web.EventListener);
    reader.readAsDataURL(file);
    return completer.future;
  }

  void _drawWatermark(web.CanvasRenderingContext2D ctx, int width, int height,
      MediaOptions options) {
    final text = options.watermark ?? '';
    final fontSize = options.watermarkFontSize ?? 30;
    ctx.font = '${fontSize}px Arial';
    ctx.textBaseline = 'bottom';
    ctx.globalAlpha = 0.7;
    ctx.fillStyle = 'white';
    ctx.strokeStyle = 'black';
    ctx.lineWidth = 2;
    final metrics = ctx.measureText(text);
    double x = width - metrics.width - 20;
    double y = height - 20;
    switch (options.watermarkPosition) {
      case 'topLeft':
        x = 20;
        y = fontSize + 20;
        break;
      case 'topRight':
        x = width - metrics.width - 20;
        y = fontSize + 20;
        break;
      case 'bottomLeft':
        x = 20;
        y = height - 20;
        break;
      case 'bottomRight':
      default:
        x = width - metrics.width - 20;
        y = height - 20;
        break;
    }
    ctx.strokeText(text, x, y);
    ctx.fillText(text, x, y);
    ctx.globalAlpha = 1.0;
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
        (event) async {
          final files = input.files;
          if (files != null && files.length > 0) {
            final file = files.item(0);
            if (file == null) {
              completer.complete(null);
              return;
            }
            final url = web.URL.createObjectURL(file);
            completer.complete(url);
          } else {
            completer.complete(null);
          }
        } as web.EventListener);
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
        (event) async {
          final files = input.files;
          if (files != null && files.length > 0) {
            final urls = <String>[];
            for (var i = 0; i < files.length; i++) {
              final file = files.item(i);
              if (file != null) {
                urls.add(web.URL.createObjectURL(file));
              }
            }
            completer.complete(urls);
          } else {
            completer.complete(null);
          }
        } as web.EventListener);
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
        (event) async {
          final files = input.files;
          if (files != null && files.length > 0) {
            final results = <String>[];
            for (var i = 0; i < files.length; i++) {
              final file = files.item(i);
              if (file == null) continue;
              if (type == MediaType.image) {
                final result = await _processImageFile(file, options);
                if (result != null) results.add(result);
              } else if (type == MediaType.video) {
                final url = await _processVideoFileWithWatermark(file, options);
                if (url != null) results.add(url);
              }
            }
            completer.complete(results);
          } else {
            completer.complete(null);
          }
        } as web.EventListener);
    if (web.document.body != null) {
      web.document.body!.appendChild(input);
    }
    input.click();
    input.remove();
    return completer.future;
  }
}
