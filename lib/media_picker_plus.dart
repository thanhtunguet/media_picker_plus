import 'dart:async';

import 'package:flutter/services.dart';
import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/media_source.dart';
import 'package:media_picker_plus/media_type.dart';

export 'media_options.dart';
export 'media_source.dart';
export 'media_type.dart';
export 'video_bit_rate.dart';
export 'watermark_position.dart';

class MediaPickerPlus {
  static const MethodChannel _channel =
      MethodChannel('info.thanhtunguet.media_picker_plus');

  /// Pick an image from gallery
  static Future<String?> pickImage({
    MediaOptions options = const MediaOptions(),
  }) async {
    return _pickMedia(MediaSource.gallery, MediaType.image, options);
  }

  /// Pick a video from gallery
  static Future<String?> pickVideo({
    MediaOptions options = const MediaOptions(),
  }) async {
    return _pickMedia(MediaSource.gallery, MediaType.video, options);
  }

  /// Capture a photo using camera
  static Future<String?> capturePhoto({
    MediaOptions options = const MediaOptions(),
  }) async {
    return _pickMedia(MediaSource.camera, MediaType.image, options);
  }

  /// Record a video using camera
  static Future<String?> recordVideo({
    MediaOptions options = const MediaOptions(),
  }) async {
    return _pickMedia(MediaSource.camera, MediaType.video, options);
  }

  static Future<String?> _pickMedia(
      MediaSource source, MediaType type, MediaOptions options) async {
    try {
      final result = await _channel.invokeMethod<String>('pickMedia', {
        'source': source.toString().split('.').last,
        'type': type.toString().split('.').last,
        'options': options.toMap(),
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error picking media: ${e.message}');
    }
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    return await _channel.invokeMethod<bool>('hasCameraPermission') ?? false;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    return await _channel.invokeMethod<bool>('requestCameraPermission') ??
        false;
  }

  /// Check if gallery permission is granted
  static Future<bool> hasGalleryPermission() async {
    return await _channel.invokeMethod<bool>('hasGalleryPermission') ?? false;
  }

  /// Request gallery permission
  static Future<bool> requestGalleryPermission() async {
    return await _channel.invokeMethod<bool>('requestGalleryPermission') ??
        false;
  }
}
