import 'watermark_position.dart';

class MediaOptions {
  final int imageQuality;

  final int? width;

  final int? height;

  final int? videoBitrate;

  final String? watermark;

  final double? watermarkFontSize;

  // 'topLeft', 'topRight', 'bottomLeft', 'bottomRight'
  final String? watermarkPosition;

  const MediaOptions({
    this.imageQuality = 80,
    this.width,
    this.height,
    this.videoBitrate,
    this.watermark,
    this.watermarkFontSize = 30,
    this.watermarkPosition = WatermarkPosition.bottomRight,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageQuality': imageQuality,
      'width': width,
      'height': height,
      'videoBitrate': videoBitrate,
      'watermark': watermark,
      'watermarkFontSize': watermarkFontSize,
      'watermarkPosition': watermarkPosition,
    };
  }
}
