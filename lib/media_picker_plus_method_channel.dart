import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'media_picker_plus_platform_interface.dart';

/// An implementation of [MediaPickerPlusPlatform] that uses method channels.
class MethodChannelMediaPickerPlus extends MediaPickerPlusPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('media_picker_plus');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
