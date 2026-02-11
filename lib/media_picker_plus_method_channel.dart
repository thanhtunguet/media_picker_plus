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
      final result = await methodChannel.invokeMethod<String>('pickMedia', {
        'source': source.toString().split('.').last,
        'type': type.toString().split('.').last,
        'options': options.toMap(),
      });
      return result;
    } on PlatformException catch (e) {
      if (_isPickerCancellationException(e)) {
        return null;
      }
      throw Exception('Error picking media: ${e.message}');
    }
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
      if (_isPickerCancellationException(e)) {
        return null;
      }
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
      if (_isPickerCancellationException(e)) {
        return null;
      }
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
      if (_isPickerCancellationException(e)) {
        return null;
      }
      throw Exception('Error picking multiple media: ${e.message}');
    }
  }

  @override
  Future<String?> processImage(String imagePath, MediaOptions options) async {
    // Use the universal applyImage method for processing
    return applyImage(imagePath, options);
  }

  @override
  Future<String?> addWatermarkToImage(
      String imagePath, MediaOptions options) async {
    // Ensure watermark is provided
    if (options.watermark == null || options.watermark!.isEmpty) {
      throw ArgumentError('Watermark text cannot be null or empty');
    }

    // Use the universal applyImage method to add watermark
    return applyImage(imagePath, options);
  }

  @override
  Future<String?> applyImage(String imagePath, MediaOptions options) async {
    try {
      final result = await methodChannel.invokeMethod<String>('applyImage', {
        'imagePath': imagePath,
        'options': options.toMap(),
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error applying image transformations: ${e.message}');
    }
  }

  @override
  Future<String?> addWatermarkToVideo(
      String videoPath, MediaOptions options) async {
    // Use the universal applyVideo method to add watermark
    return applyVideo(videoPath, options);
  }

  @override
  Future<String?> applyVideo(String videoPath, MediaOptions options) async {
    try {
      final result = await methodChannel.invokeMethod<String>('applyVideo', {
        'videoPath': videoPath,
        'options': options.toMap(),
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error applying video transformations: ${e.message}');
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

  bool _isPickerCancellationException(PlatformException exception) {
    final code = exception.code.toLowerCase();
    return code == 'cancelled' || code == 'operation_cancelled';
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
