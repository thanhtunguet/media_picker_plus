import 'package:flutter/foundation.dart';

/// A minimal logger for MediaPickerPlus that uses debugPrint.
///
/// This logger is disabled by default to avoid production noise.
/// Enable it by setting [MediaPickerLogger.enabled] to true.
class MediaPickerLogger {
  /// Whether logging is enabled. Default is false.
  static bool enabled = false;

  /// Log a debug message.
  ///
  /// [tag] identifies the source module (e.g., "MethodChannel", "CropHelper")
  /// [message] the message to log
  static void d(String tag, String message) {
    if (enabled) {
      debugPrint('[$tag] $message');
    }
  }

  /// Log an error message.
  ///
  /// [tag] identifies the source module
  /// [message] the error message
  /// [error] optional error object to include in the log
  static void e(String tag, String message, [Object? error]) {
    if (enabled) {
      debugPrint('[$tag] ERROR: $message${error != null ? ' ($error)' : ''}');
    }
  }
}
