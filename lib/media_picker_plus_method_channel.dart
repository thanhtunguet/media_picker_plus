import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'media_picker_plus_platform_interface.dart';
import 'media_options.dart';
import 'media_source.dart';
import 'media_type.dart';

/// An implementation of [MediaPickerPlusPlatform] that uses method channels.
class MethodChannelMediaPickerPlus extends MediaPickerPlusPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('info.thanhtunguet.media_picker_plus');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> pickMedia(MediaSource source, MediaType type, MediaOptions options) async {
    try {
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

  @override
  Future<bool> hasCameraPermission() async {
    return await methodChannel.invokeMethod<bool>('hasCameraPermission') ?? false;
  }

  @override
  Future<bool> requestCameraPermission() async {
    return await methodChannel.invokeMethod<bool>('requestCameraPermission') ?? false;
  }

  @override
  Future<bool> hasGalleryPermission() async {
    return await methodChannel.invokeMethod<bool>('hasGalleryPermission') ?? false;
  }

  @override
  Future<bool> requestGalleryPermission() async {
    return await methodChannel.invokeMethod<bool>('requestGalleryPermission') ?? false;
  }

  @override
  Future<String?> pickFile(MediaOptions options, List<String>? allowedExtensions) async {
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
  Future<List<String>?> pickMultipleFiles(MediaOptions options, List<String>? allowedExtensions) async {
    try {
      final result = await methodChannel.invokeMethod<List<dynamic>>('pickMultipleFiles', {
        'options': options.toMap(),
        'allowedExtensions': allowedExtensions,
      });
      return result?.cast<String>().toList();
    } on PlatformException catch (e) {
      throw Exception('Error picking multiple files: ${e.message}');
    }
  }

  @override
  Future<List<String>?> pickMultipleMedia(MediaSource source, MediaType type, MediaOptions options) async {
    try {
      final result = await methodChannel.invokeMethod<List<dynamic>>('pickMultipleMedia', {
        'source': source.toString().split('.').last,
        'type': type.toString().split('.').last,
        'options': options.toMap(),
      });
      return result?.cast<String>().toList();
    } on PlatformException catch (e) {
      throw Exception('Error picking multiple media: ${e.message}');
    }
  }
}
