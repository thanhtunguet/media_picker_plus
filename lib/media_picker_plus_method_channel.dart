import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'media_options.dart';
import 'media_picker_plus_platform_interface.dart';
import 'media_source.dart';
import 'media_type.dart';
import 'src/media_picker_logger.dart';
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
    MediaPickerLogger.d(
        'MethodChannel', 'pickMedia: source=$source type=$type');
    try {
      final result = await methodChannel.invokeMethod<dynamic>('pickMedia', {
        'source': source.toString().split('.').last,
        'type': type.toString().split('.').last,
        'options': options.toMap(),
      });
      final path = _pickMediaResultToPath(result);
      MediaPickerLogger.d('MethodChannel', 'pickMedia result: $path');
      return path;
    } on PlatformException catch (e) {
      if (_isPickerCancellationException(e)) {
        MediaPickerLogger.d('MethodChannel', 'pickMedia cancelled');
        return null;
      }
      MediaPickerLogger.e('MethodChannel', 'pickMedia error', e);
      rethrow;
    }
  }

  /// Converts native pickMedia result to a file path string.
  /// Native may return a [String] path or a [Map] (e.g. {'path': '...'}).
  static String? _pickMediaResultToPath(dynamic result) {
    if (result == null) return null;
    if (result is String) return result;
    if (result is Map) {
      // Some native implementations may return an error object instead of
      // throwing a PlatformException.
      //
      // Expected shape:
      //   { error: { code: 'save_failed', message: 'Failed to save media' } }
      final error = result['error'];
      if (error is Map) {
        final code = error['code']?.toString() ?? 'unknown';
        final message = error['message']?.toString();
        throw PlatformException(code: code, message: message, details: error);
      }

      final path = result['path'] ?? result['filePath'];
      return path is String ? path : path?.toString();
    }
    return result.toString();
  }

  @override
  Future<bool> hasCameraPermission() async {
    try {
      final result = await methodChannel.invokeMethod('hasCameraPermission');
      return _convertToBool(result);
    } on PlatformException catch (e) {
      if (_isPermissionDeniedException(e)) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> requestCameraPermission() async {
    try {
      final result =
          await methodChannel.invokeMethod('requestCameraPermission');
      return _convertToBool(result);
    } on PlatformException catch (e) {
      if (_isPermissionDeniedException(e)) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> hasGalleryPermission() async {
    try {
      final result = await methodChannel.invokeMethod('hasGalleryPermission');
      return _convertToBool(result);
    } on PlatformException catch (e) {
      if (_isPermissionDeniedException(e)) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> requestGalleryPermission() async {
    try {
      final result =
          await methodChannel.invokeMethod('requestGalleryPermission');
      return _convertToBool(result);
    } on PlatformException catch (e) {
      if (_isPermissionDeniedException(e)) {
        return false;
      }
      rethrow;
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
      rethrow;
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
      rethrow;
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
      rethrow;
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
    validateWatermarkText(options.watermark);
    validateFilePath(imagePath);

    // Use the universal applyImage method to add watermark
    return applyImage(imagePath, options);
  }

  @override
  Future<String?> applyImage(String imagePath, MediaOptions options) async {
    validateFilePath(imagePath);
    validateWatermarkText(options.watermark);

    try {
      final result = await methodChannel.invokeMethod<String>('applyImage', {
        'imagePath': imagePath,
        'options': options.toMap(),
      });
      return result;
    } on PlatformException {
      rethrow;
    }
  }

  @override
  Future<String?> addWatermarkToVideo(
      String videoPath, MediaOptions options) async {
    validateFilePath(videoPath);
    validateWatermarkText(options.watermark);

    // Use the universal applyVideo method to add watermark
    return applyVideo(videoPath, options);
  }

  @override
  Future<String?> applyVideo(String videoPath, MediaOptions options) async {
    validateFilePath(videoPath);
    validateWatermarkText(options.watermark);

    try {
      final result = await methodChannel.invokeMethod<String>('applyVideo', {
        'videoPath': videoPath,
        'options': options.toMap(),
      });
      return result;
    } on PlatformException {
      rethrow;
    }
  }

  @override
  Future<String?> getThumbnail(
    String videoPath, {
    double timeInSeconds = 1.0,
    MediaOptions? options,
  }) async {
    validateFilePath(videoPath);

    try {
      final result = await methodChannel.invokeMethod<String>('getThumbnail', {
        'videoPath': videoPath,
        'timeInSeconds': timeInSeconds,
        'options': options?.toMap(),
      });
      return result;
    } on PlatformException {
      rethrow;
    }
  }

  @override
  Future<String?> compressVideo(
    String inputPath, {
    String? outputPath,
    required dynamic options,
  }) async {
    validateFilePath(inputPath);
    validateFilePath(outputPath);

    try {
      Map<String, dynamic> optionsMap;

      if (options is Map<String, dynamic>) {
        optionsMap = options;
      } else if (options is VideoCompressionOptions) {
        // Native side extracts real dimensions from the video internally,
        // so we just pass the options with default fallback values
        optionsMap = options.toMap();
      } else {
        optionsMap = (options as dynamic)?.toMap() ?? {};
      }

      final result = await methodChannel.invokeMethod<String>('compressVideo', {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'options': optionsMap,
      });
      return result;
    } on PlatformException {
      rethrow;
    }
  }

  /// Validates a file path to prevent path traversal attacks.
  static void validateFilePath(String? path) {
    if (path == null || path.isEmpty) return;
    // Allow web URLs (data URIs, blob URLs)
    if (path.startsWith('data:') || path.startsWith('blob:')) return;
    // Prevent path traversal
    if (path.contains('..')) {
      throw ArgumentError('Invalid file path: path traversal not allowed');
    }
  }

  /// Validates watermark text length.
  static void validateWatermarkText(String? text, {int maxLength = 500}) {
    if (text != null && text.length > maxLength) {
      throw ArgumentError(
          'watermarkText exceeds maximum length of $maxLength characters');
    }
  }

  bool _isPickerCancellationException(PlatformException exception) {
    final code = exception.code.toLowerCase();
    return code == 'cancelled' || code == 'operation_cancelled';
  }

  bool _isPermissionDeniedException(PlatformException exception) {
    final code = exception.code.toLowerCase();
    return code == 'permission_denied' ||
        code == 'permissiondenied' ||
        code.contains('permission');
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
    // Log unexpected type for debugging
    if (kDebugMode) {
      debugPrint(
          'Warning: _convertToBool received unexpected type: ${value.runtimeType}');
    }
    return false;
  }
}
