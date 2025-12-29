enum VideoCompressionQuality {
  low(bitrate: 500000, width: 480, height: 320),
  medium(bitrate: 1500000, width: 854, height: 480),
  high(bitrate: 3000000, width: 1280, height: 720),
  veryHigh(bitrate: 5000000, width: 1920, height: 1080);

  const VideoCompressionQuality({
    required this.bitrate,
    required this.width,
    required this.height,
  });

  final int bitrate;
  final int width;
  final int height;
}

class VideoCompressionOptions {
  final VideoCompressionQuality? quality;
  final int? customBitrate;
  final int? customWidth;
  final int? customHeight;
  final String outputFormat;
  final bool deleteOriginalFile;
  final Function(double progress)? onProgress;

  const VideoCompressionOptions({
    this.quality = VideoCompressionQuality.medium,
    this.customBitrate,
    this.customWidth,
    this.customHeight,
    this.outputFormat = 'mp4',
    this.deleteOriginalFile = false,
    this.onProgress,
  });

  int get targetBitrate =>
      customBitrate ??
      quality?.bitrate ??
      VideoCompressionQuality.medium.bitrate;

  int get targetWidth =>
      customWidth ?? quality?.width ?? VideoCompressionQuality.medium.width;

  int get targetHeight =>
      customHeight ?? quality?.height ?? VideoCompressionQuality.medium.height;

  Map<String, dynamic> toMap() {
    return {
      'quality': quality?.name,
      'customBitrate': customBitrate,
      'customWidth': customWidth,
      'customHeight': customHeight,
      'outputFormat': outputFormat,
      'deleteOriginalFile': deleteOriginalFile,
      'targetBitrate': targetBitrate,
      'targetWidth': targetWidth,
      'targetHeight': targetHeight,
    };
  }
}
