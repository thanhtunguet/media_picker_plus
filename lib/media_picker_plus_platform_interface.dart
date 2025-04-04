import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'media_picker_plus_method_channel.dart';

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
}
