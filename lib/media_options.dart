import 'watermark_position.dart';
import 'crop_options.dart';
import 'preferred_camera_device.dart';

class MediaOptions {
  final int imageQuality;

  final int? maxWidth;

  final int? maxHeight;

  /// Preferred camera device when capturing media.
  ///
  /// This is a best-effort hint to the platform. Some platforms or camera apps
  /// may ignore it and use the default camera instead.
  final PreferredCameraDevice preferredCameraDevice;

  final String? watermark;

  final double? watermarkFontSize;

  /// Watermark font size as a percentage of the shorter edge of the image/video.
  /// Value should be between 0 and 100.
  /// If specified, this takes precedence over watermarkFontSize.
  /// Default is 4.0 (4% of shorter edge).
  final double? watermarkFontSizePercentage;

  // 'topLeft', 'topRight', 'bottomLeft', 'bottomRight'
  final String? watermarkPosition;

  final Duration? maxDuration;

  final CropOptions? cropOptions;

  const MediaOptions({
    this.imageQuality = 80,
    this.maxWidth = 1280,
    this.maxHeight = 1280,
    this.preferredCameraDevice = PreferredCameraDevice.auto,
    this.watermark,
    this.watermarkFontSize,
    this.watermarkFontSizePercentage = 4.0,
    this.watermarkPosition = WatermarkPosition.bottomRight,
    this.maxDuration = const Duration(seconds: 60),
    this.cropOptions,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageQuality': imageQuality,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'preferredCameraDevice': preferredCameraDevice.name,
      'watermark': watermark,
      'watermarkFontSize': watermarkFontSize,
      'watermarkFontSizePercentage': watermarkFontSizePercentage,
      'watermarkPosition': watermarkPosition,
      'maxDuration': maxDuration?.inSeconds,
      'cropOptions': cropOptions?.toMap(),
    };
  }
}
