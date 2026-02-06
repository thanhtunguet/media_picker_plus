import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/media_source.dart';
import 'package:media_picker_plus/media_type.dart';

import 'crop_helper.dart';
import 'media_picker_plus_platform_interface.dart';
import 'multi_image_helper.dart';
import 'multi_image_options.dart';

export 'media_options.dart';
export 'video_compression_options.dart';
export 'media_source.dart';
export 'media_type.dart';
export 'watermark_position.dart';
export 'crop_options.dart';
export 'preferred_camera_device.dart';
export 'crop_ui.dart';
export 'multi_image_options.dart';

class MediaPickerPlus {
  /// Pick an image from gallery
  static Future<String?> pickImage({
    MediaOptions options = const MediaOptions(),
    BuildContext? context,
  }) async {
    // Use interactive cropping if context is provided and cropping is enabled
    if (context != null && options.cropOptions?.enableCrop == true) {
      return await CropHelper.pickMediaWithCrop(
        context,
        MediaSource.gallery,
        MediaType.image,
        options,
      );
    }

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
    BuildContext? context,
  }) async {
    // Use interactive cropping if context is provided and cropping is enabled
    if (context != null && options.cropOptions?.enableCrop == true) {
      return await CropHelper.pickMediaWithCrop(
        context,
        MediaSource.camera,
        MediaType.image,
        options,
      );
    }

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

  /// Capture multiple photos using the camera with a hub screen.
  ///
  /// Opens a hub screen that continuously loops the native camera for a
  /// multi-capture experience. The user reviews thumbnails between captures
  /// and taps "Done" when finished. Each image is processed with quality and
  /// watermark settings (cropping is skipped for multi-image).
  ///
  /// On web and macOS, this falls back to a single camera capture and returns
  /// a one-item list to preserve this method's signature.
  ///
  /// [context] is required to push the hub screen.
  /// [options] controls image quality, watermark, etc. Crop options are ignored.
  /// [multiImageOptions] controls max/min images and discard confirmation.
  static Future<List<String>?> captureMultiplePhotos({
    required BuildContext context,
    MediaOptions options = const MediaOptions(),
    MultiImageOptions multiImageOptions = const MultiImageOptions(),
  }) async {
    return MultiImageHelper.captureMultiplePhotosWithUI(
      context,
      options,
      multiImageOptions,
    );
  }

  /// Add watermark to an existing image file
  static Future<String?> addWatermarkToImage(
    String imagePath, {
    required MediaOptions options,
  }) async {
    // Ensure watermark is provided
    if (options.watermark == null || options.watermark!.isEmpty) {
      throw ArgumentError('Watermark text cannot be null or empty');
    }

    // Use the universal applyImage method to add watermark
    return MediaPickerPlusPlatform.instance.applyImage(imagePath, options);
  }

  /// Add watermark to an existing video file
  static Future<String?> addWatermarkToVideo(
    String videoPath, {
    required MediaOptions options,
  }) async {
    return MediaPickerPlusPlatform.instance
        .addWatermarkToVideo(videoPath, options);
  }

  /// Extract a thumbnail image from a video file
  ///
  /// [videoPath] is the path to the video file
  /// [timeInSeconds] is the time in seconds to extract the thumbnail from (default: 1.0)
  /// [options] optional MediaOptions for processing the thumbnail (resizing, quality, etc.)
  ///
  /// Returns the path to the generated thumbnail image file
  static Future<String?> getThumbnail(
    String videoPath, {
    double timeInSeconds = 1.0,
    MediaOptions? options,
  }) async {
    return MediaPickerPlusPlatform.instance.getThumbnail(
      videoPath,
      timeInSeconds: timeInSeconds,
      options: options,
    );
  }

  /// Universal image processing method that applies all image transformations:
  /// - Resizing (within maxWidth and maxHeight)
  /// - Image quality compression
  /// - Watermarking
  /// - Cropping (if enabled in options)
  static Future<String?> applyImage(
    String imagePath, {
    required MediaOptions options,
  }) async {
    return MediaPickerPlusPlatform.instance.applyImage(imagePath, options);
  }

  /// Resize an image to fit within the specified maxWidth and maxHeight
  /// while maintaining aspect ratio
  static Future<String?> resizeImage(
    String imagePath, {
    required int maxWidth,
    required int maxHeight,
    int imageQuality = 80,
  }) async {
    final options = MediaOptions(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    return MediaPickerPlusPlatform.instance.applyImage(imagePath, options);
  }

  /// Universal video processing method that applies all video transformations:
  /// - Resizing (within maxWidth and maxHeight)
  /// - Video quality compression (bitrate)
  /// - Watermarking
  ///
  /// [videoPath] path to the input video file
  /// [options] MediaOptions containing processing parameters
  ///
  /// Returns the path to the processed video file
  static Future<String?> applyVideo(
    String videoPath, {
    required MediaOptions options,
  }) async {
    return MediaPickerPlusPlatform.instance.applyVideo(videoPath, options);
  }

  /// Resize a video to fit within the specified dimensions
  /// while maintaining aspect ratio
  static Future<String?> resizeVideo(
    String videoPath, {
    required int maxWidth,
    required int maxHeight,
  }) async {
    final options = MediaOptions(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    return MediaPickerPlusPlatform.instance.applyVideo(videoPath, options);
  }

  /// Compress a video file
  ///
  /// [inputPath] path to the input video file
  /// [outputPath] optional path for the compressed video file. If not provided,
  ///             a path will be generated automatically
  /// [options] compression options including quality, bitrate, resolution, etc.
  ///
  /// Returns the path to the compressed video file
  static Future<String?> compressVideo(
    String inputPath, {
    String? outputPath,
    required dynamic options,
  }) async {
    return MediaPickerPlusPlatform.instance.compressVideo(
      inputPath,
      outputPath: outputPath,
      options: options,
    );
  }
}
