import 'watermark_position.dart';

class MediaOptions {
  final int imageQuality;

  final int? maxWidth;

  final int? maxHeight;

  final String? watermark;

  final double? watermarkFontSize;

  // 'topLeft', 'topRight', 'bottomLeft', 'bottomRight'
  final String? watermarkPosition;

  final Duration? maxDuration;

  const MediaOptions({
    this.imageQuality = 80,
    this.maxWidth = 1280,
    this.maxHeight = 1280,
    this.watermark,
    this.watermarkFontSize = 30,
    this.watermarkPosition = WatermarkPosition.bottomRight,
    this.maxDuration = const Duration(seconds: 60),
  });

  Map<String, dynamic> toMap() {
    return {
      'imageQuality': imageQuality,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'watermark': watermark,
      'watermarkFontSize': watermarkFontSize,
      'watermarkPosition': watermarkPosition,
      'maxDuration': maxDuration?.inSeconds,
    };
  }
}
