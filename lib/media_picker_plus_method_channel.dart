import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'media_options.dart';
import 'media_picker_plus_platform_interface.dart';
import 'media_source.dart';
import 'media_type.dart';
import 'video_compression_options.dart';

/// An implementation of [MediaPickerPlusPlatform] that uses method channels.
class MethodChannelMediaPickerPlus extends MediaPickerPlusPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel =
      const MethodChannel('info.thanhtunguet.media_picker_plus');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> pickMedia(
      MediaSource source, MediaType type, MediaOptions options) async {
    try {
      // Check if freeform cropping is enabled
      if (options.cropOptions?.freeform == true &&
          options.cropOptions?.enableCrop == true) {
        // Handle interactive cropping
        return await _pickMediaWithInteractiveCrop(source, type, options);
      }

      final result = await methodChannel.invokeMethod<String>('pickMedia', {
        'source': source.toString().split('.').last,
        'type': type.toString().split('.').last,
        'options': options.toMap(),
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error picking media: ${e.message}');
    }
  }

  Future<String?> _pickMediaWithInteractiveCrop(
      MediaSource source, MediaType type, MediaOptions options) async {
    // First pick the media without cropping
    final tempOptions = MediaOptions(
      imageQuality: options.imageQuality,
      maxWidth: options.maxWidth,
      maxHeight: options.maxHeight,
      watermark: options.watermark,
      watermarkFontSize: options.watermarkFontSize,
      watermarkPosition: options.watermarkPosition,
      maxDuration: options.maxDuration,
      // Disable cropping for initial pick
      cropOptions: null,
    );

    final tempResult = await methodChannel.invokeMethod<String>('pickMedia', {
      'source': source.toString().split('.').last,
      'type': type.toString().split('.').last,
      'options': tempOptions.toMap(),
    });

    if (tempResult == null) return null;

    // Show interactive cropping UI - this will be handled at the Flutter app level
    // For now, return the uncropped image and let the app handle the UI
    return tempResult;
  }

  @override
  Future<bool> hasCameraPermission() async {
    try {
      final result = await methodChannel.invokeMethod('hasCameraPermission');
      return _convertToBool(result);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestCameraPermission() async {
    try {
      final result =
          await methodChannel.invokeMethod('requestCameraPermission');
      return _convertToBool(result);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> hasGalleryPermission() async {
    try {
      final result = await methodChannel.invokeMethod('hasGalleryPermission');
      return _convertToBool(result);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestGalleryPermission() async {
    try {
      final result =
          await methodChannel.invokeMethod('requestGalleryPermission');
      return _convertToBool(result);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> pickFile(
      MediaOptions options, List<String>? allowedExtensions) async {
    try {
      final result = await methodChannel.invokeMethod<String>('pickFile', {
        'options': options.toMap(),
        'allowedExtensions': allowedExtensions,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error picking file: ${e.message}');
    }
  }

  @override
  Future<List<String>?> pickMultipleFiles(
      MediaOptions options, List<String>? allowedExtensions) async {
    try {
      final result =
          await methodChannel.invokeMethod<List<dynamic>>('pickMultipleFiles', {
        'options': options.toMap(),
        'allowedExtensions': allowedExtensions,
      });
      return result?.cast<String>().toList();
    } on PlatformException catch (e) {
      throw Exception('Error picking multiple files: ${e.message}');
    }
  }

  @override
  Future<List<String>?> pickMultipleMedia(
      MediaSource source, MediaType type, MediaOptions options) async {
    try {
      final result =
          await methodChannel.invokeMethod<List<dynamic>>('pickMultipleMedia', {
        'source': source.toString().split('.').last,
        'type': type.toString().split('.').last,
        'options': options.toMap(),
      });
      return result?.cast<String>().toList();
    } on PlatformException catch (e) {
      throw Exception('Error picking multiple media: ${e.message}');
    }
  }

  @override
  Future<String?> processImage(String imagePath, MediaOptions options) async {
    try {
      final result = await methodChannel.invokeMethod<String>('processImage', {
        'imagePath': imagePath,
        'options': options.toMap(),
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error processing image: ${e.message}');
    }
  }

  @override
  Future<String?> addWatermarkToImage(
      String imagePath, MediaOptions options) async {
    try {
      final result =
          await methodChannel.invokeMethod<String>('addWatermarkToImage', {
        'imagePath': imagePath,
        'options': options.toMap(),
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error adding watermark to image: ${e.message}');
    }
  }

  @override
  Future<String?> addWatermarkToVideo(
      String videoPath, MediaOptions options) async {
    try {
      final result =
          await methodChannel.invokeMethod<String>('addWatermarkToVideo', {
        'videoPath': videoPath,
        'options': options.toMap(),
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error adding watermark to video: ${e.message}');
    }
  }

  @override
  Future<String?> getThumbnail(
    String videoPath, {
    double timeInSeconds = 1.0,
    MediaOptions? options,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<String>('getThumbnail', {
        'videoPath': videoPath,
        'timeInSeconds': timeInSeconds,
        'options': options?.toMap(),
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error extracting thumbnail: ${e.message}');
    }
  }

  @override
  Future<String?> compressVideo(
    String inputPath, {
    String? outputPath,
    required dynamic options,
  }) async {
    try {
      Map<String, dynamic> optionsMap;

      if (options is Map<String, dynamic>) {
        optionsMap = options;
      } else if (options is VideoCompressionOptions) {
        // Get video dimensions first to calculate target resolution
        try {
          final videoInfo =
              await methodChannel.invokeMethod<Map>('getVideoInfo', {
            'videoPath': inputPath,
          });

          final originalWidth = videoInfo?['width'] as int? ?? 1920;
          final originalHeight = videoInfo?['height'] as int? ?? 1080;

          optionsMap = options.toMap(
            originalWidth: originalWidth,
            originalHeight: originalHeight,
          );
        } catch (e) {
          // Fallback to default map if getting video info fails
          optionsMap = options.toMap();
        }
      } else {
        optionsMap = (options as dynamic)?.toMap() ?? {};
      }

      final result = await methodChannel.invokeMethod<String>('compressVideo', {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'options': optionsMap,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error compressing video: ${e.message}');
    }
  }

  /// Helper method to safely convert various types to boolean
  /// This handles cases where native platforms might return different types
  bool _convertToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) {
      return value != 0;
    }
    return false;
  }
}
