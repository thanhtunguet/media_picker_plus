import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'media_options.dart';
import 'media_picker_plus_method_channel.dart';
import 'media_source.dart';
import 'media_type.dart';

abstract class MediaPickerPlusPlatform extends PlatformInterface {
  /// Constructs a MediaPickerPlusPlatform.
  MediaPickerPlusPlatform() : super(token: _token);

  static final Object _token = Object();

  static MediaPickerPlusPlatform _instance = MethodChannelMediaPickerPlus();

  /// The default instance of [MediaPickerPlusPlatform] to use.
  ///
  /// Defaults to [MethodChannelMediaPickerPlus].
  static MediaPickerPlusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MediaPickerPlusPlatform] when
  /// they register themselves.
  static set instance(MediaPickerPlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> pickMedia(
      MediaSource source, MediaType type, MediaOptions options) {
    throw UnimplementedError('pickMedia() has not been implemented.');
  }

  Future<bool> hasCameraPermission() {
    throw UnimplementedError('hasCameraPermission() has not been implemented.');
  }

  Future<bool> requestCameraPermission() {
    throw UnimplementedError(
        'requestCameraPermission() has not been implemented.');
  }

  Future<bool> hasGalleryPermission() {
    throw UnimplementedError(
        'hasGalleryPermission() has not been implemented.');
  }

  Future<bool> requestGalleryPermission() {
    throw UnimplementedError(
        'requestGalleryPermission() has not been implemented.');
  }

  Future<String?> pickFile(
      MediaOptions options, List<String>? allowedExtensions) {
    throw UnimplementedError('pickFile() has not been implemented.');
  }

  Future<List<String>?> pickMultipleFiles(
      MediaOptions options, List<String>? allowedExtensions) {
    throw UnimplementedError('pickMultipleFiles() has not been implemented.');
  }

  Future<List<String>?> pickMultipleMedia(
      MediaSource source, MediaType type, MediaOptions options) {
    throw UnimplementedError('pickMultipleMedia() has not been implemented.');
  }

  Future<String?> processImage(String imagePath, MediaOptions options) {
    throw UnimplementedError('processImage() has not been implemented.');
  }

  Future<String?> addWatermarkToImage(String imagePath, MediaOptions options) {
    throw UnimplementedError('addWatermarkToImage() has not been implemented.');
  }

  Future<String?> addWatermarkToVideo(String videoPath, MediaOptions options) {
    throw UnimplementedError('addWatermarkToVideo() has not been implemented.');
  }
}
