import 'package:flutter/material.dart';

import 'media_options.dart';
import 'media_picker_plus_platform_interface.dart';
import 'media_source.dart';
import 'media_type.dart';
import 'multi_capture_screen.dart';
import 'multi_image_options.dart';

/// Orchestrator for multi-image picking operations.
///
/// Handles both camera multi-capture (via [MultiCaptureScreen]) and gallery
/// multi-pick, applying quality and watermark processing to each image.
/// Cropping is intentionally skipped for multi-image operations.
class MultiImageHelper {
  /// Opens a hub screen for continuous camera capture.
  ///
  /// 1. Pushes [MultiCaptureScreen] which loops the native camera.
  /// 2. Receives raw image paths when the user taps "Done".
  /// 3. Processes each image (quality + watermark, no crop).
  /// 4. Returns processed paths, or `null` if cancelled.
  static Future<List<String>?> captureMultiplePhotosWithUI(
    BuildContext context,
    MediaOptions options,
    MultiImageOptions multiOptions,
  ) async {
    if (!context.mounted) return null;

    final rawPaths = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => MultiCaptureScreen(
          mediaOptions: options,
          multiImageOptions: multiOptions,
        ),
      ),
    );

    if (rawPaths == null || rawPaths.isEmpty) return null;

    return _processAll(rawPaths, options);
  }

  /// Picks multiple images from the gallery and processes them.
  ///
  /// 1. Calls the platform's `pickMultipleMedia` for gallery images.
  /// 2. If a watermark is configured, processes each image.
  /// 3. Returns processed paths, or `null` if cancelled.
  static Future<List<String>?> pickMultipleImagesProcessed(
    MediaOptions options,
  ) async {
    // Pick without crop — strip cropOptions
    final pickOptions = MediaOptions(
      imageQuality: options.imageQuality,
      maxWidth: options.maxWidth,
      maxHeight: options.maxHeight,
      preferredCameraDevice: options.preferredCameraDevice,
      watermark: options.watermark,
      watermarkFontSize: options.watermarkFontSize,
      watermarkFontSizePercentage: options.watermarkFontSizePercentage,
      watermarkPosition: options.watermarkPosition,
      maxDuration: options.maxDuration,
      // No crop for multi-image
    );

    final paths = await MediaPickerPlusPlatform.instance
        .pickMultipleMedia(MediaSource.gallery, MediaType.image, pickOptions);

    if (paths == null || paths.isEmpty) return null;

    // If watermark is set, process each image individually
    if (options.watermark != null && options.watermark!.isNotEmpty) {
      return _processAll(paths, options);
    }

    return paths;
  }

  /// Processes a list of raw image paths: applies quality + watermark (no crop).
  static Future<List<String>> _processAll(
    List<String> paths,
    MediaOptions options,
  ) async {
    final processOptions = MediaOptions(
      imageQuality: options.imageQuality,
      maxWidth: options.maxWidth,
      maxHeight: options.maxHeight,
      watermark: options.watermark,
      watermarkFontSize: options.watermarkFontSize,
      watermarkFontSizePercentage: options.watermarkFontSizePercentage,
      watermarkPosition: options.watermarkPosition,
      // No crop for multi-image
    );

    final processed = <String>[];
    for (final path in paths) {
      try {
        final result = await MediaPickerPlusPlatform.instance
            .processImage(path, processOptions);
        processed.add(result ?? path);
      } catch (_) {
        // If processing fails for one image, keep the original
        processed.add(path);
      }
    }
    return processed;
  }
}
