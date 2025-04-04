// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'media_picker_plus_platform_interface.dart';

/// A web implementation of the MediaPickerPlusPlatform of the MediaPickerPlus plugin.
class MediaPickerPlusWeb extends MediaPickerPlusPlatform {
  /// Constructs a MediaPickerPlusWeb
  MediaPickerPlusWeb();

  static void registerWith(Registrar registrar) {
    MediaPickerPlusPlatform.instance = MediaPickerPlusWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }
}
