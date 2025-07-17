import 'dart:async';

import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/media_source.dart';
import 'package:media_picker_plus/media_type.dart';

import 'media_picker_plus_platform_interface.dart';

export 'media_options.dart';
export 'media_source.dart';
export 'media_type.dart';
export 'watermark_position.dart';

class MediaPickerPlus {
  /// Pick an image from gallery
  static Future<String?> pickImage({
    MediaOptions options = const MediaOptions(),
  }) async {
    return MediaPickerPlusPlatform.instance
        .pickMedia(MediaSource.gallery, MediaType.image, options);
  }

  /// Pick a video from gallery
  static Future<String?> pickVideo({
    MediaOptions options = const MediaOptions(),
  }) async {
    return MediaPickerPlusPlatform.instance
        .pickMedia(MediaSource.gallery, MediaType.video, options);
  }

  /// Capture a photo using camera
  static Future<String?> capturePhoto({
    MediaOptions options = const MediaOptions(),
  }) async {
    return MediaPickerPlusPlatform.instance
        .pickMedia(MediaSource.camera, MediaType.image, options);
  }

  /// Record a video using camera
  static Future<String?> recordVideo({
    MediaOptions options = const MediaOptions(),
  }) async {
    return MediaPickerPlusPlatform.instance
        .pickMedia(MediaSource.camera, MediaType.video, options);
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    return MediaPickerPlusPlatform.instance.hasCameraPermission();
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    return MediaPickerPlusPlatform.instance.requestCameraPermission();
  }

  /// Check if gallery permission is granted
  static Future<bool> hasGalleryPermission() async {
    return MediaPickerPlusPlatform.instance.hasGalleryPermission();
  }

  /// Request gallery permission
  static Future<bool> requestGalleryPermission() async {
    return MediaPickerPlusPlatform.instance.requestGalleryPermission();
  }

  /// Pick files from file system
  static Future<String?> pickFile({
    MediaOptions options = const MediaOptions(),
    List<String>? allowedExtensions,
  }) async {
    return MediaPickerPlusPlatform.instance
        .pickFile(options, allowedExtensions);
  }

  /// Pick multiple files from file system
  static Future<List<String>?> pickMultipleFiles({
    MediaOptions options = const MediaOptions(),
    List<String>? allowedExtensions,
  }) async {
    return MediaPickerPlusPlatform.instance
        .pickMultipleFiles(options, allowedExtensions);
  }

  /// Pick multiple images from gallery
  static Future<List<String>?> pickMultipleImages({
    MediaOptions options = const MediaOptions(),
  }) async {
    return MediaPickerPlusPlatform.instance
        .pickMultipleMedia(MediaSource.gallery, MediaType.image, options);
  }

  /// Pick multiple videos from gallery
  static Future<List<String>?> pickMultipleVideos({
    MediaOptions options = const MediaOptions(),
  }) async {
    return MediaPickerPlusPlatform.instance
        .pickMultipleMedia(MediaSource.gallery, MediaType.video, options);
  }
}
