// This file is required for web platform registration
// It exports the MediaPickerPlusWeb implementation with the expected class name

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'media_picker_plus_web.dart';

/// A web implementation plugin class that delegates to MediaPickerPlusWeb
class MediaPickerPlusPlugin {
  /// Registers the web implementation
  static void registerWith(Registrar registrar) {
    MediaPickerPlusWeb.registerWith(registrar);
  }
}
