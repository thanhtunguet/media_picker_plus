enum VideoCompressionQuality {
  // 360p (nHD) - Mobile/basic quality
  p360(maxHeight: 360, bitrate: 400000),
  // 480p (SD) - Standard definition
  p480(maxHeight: 480, bitrate: 800000),
  // 640p (qHD) - Quarter HD
  p640(maxHeight: 640, bitrate: 1200000),
  // 720p (HD) - High definition
  p720(maxHeight: 720, bitrate: 2000000),
  // 1080p (FHD) - Full HD
  p1080(maxHeight: 1080, bitrate: 4000000),
  // 1280p - HD Plus
  p1280(maxHeight: 1280, bitrate: 6000000),
  // 1440p (QHD) - Quad HD
  p1440(maxHeight: 1440, bitrate: 8000000),
  // 1920p - Custom high resolution
  p1920(maxHeight: 1920, bitrate: 12000000),
  // 2K - Cinema standard (2048x1080)
  k2(maxHeight: 1080, bitrate: 10000000),
  // Original - No compression, preserve original resolution
  original(maxHeight: 0, bitrate: 0);

  const VideoCompressionQuality({
    required this.maxHeight,
    required this.bitrate,
  });

  final int maxHeight;
  final int bitrate;

  /// Calculate target width based on original aspect ratio and max height
  int calculateWidth(int originalWidth, int originalHeight) {
    if (maxHeight == 0) return originalWidth; // Original quality

    final aspectRatio = originalWidth / originalHeight;
    final targetHeight =
        maxHeight < originalHeight ? maxHeight : originalHeight;
    return (targetHeight * aspectRatio).round();
  }

  /// Calculate target height based on original dimensions
  int calculateHeight(int originalHeight) {
    if (maxHeight == 0) return originalHeight; // Original quality
    return maxHeight < originalHeight ? maxHeight : originalHeight;
  }
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
    this.quality = VideoCompressionQuality.p720,
    this.customBitrate,
    this.customWidth,
    this.customHeight,
    this.outputFormat = 'mp4',
    this.deleteOriginalFile = false,
    this.onProgress,
  });

  int get targetBitrate =>
      customBitrate ?? quality?.bitrate ?? VideoCompressionQuality.p720.bitrate;

  /// Get target width based on original dimensions and quality setting
  int getTargetWidth(int originalWidth, int originalHeight) =>
      customWidth ??
      quality?.calculateWidth(originalWidth, originalHeight) ??
      VideoCompressionQuality.p720
          .calculateWidth(originalWidth, originalHeight);

  /// Get target height based on original dimensions and quality setting
  int getTargetHeight(int originalHeight) =>
      customHeight ??
      quality?.calculateHeight(originalHeight) ??
      VideoCompressionQuality.p720.calculateHeight(originalHeight);

  /// Convert to map with calculated target dimensions
  Map<String, dynamic> toMap({int? originalWidth, int? originalHeight}) {
    final targetWidth = originalWidth != null && originalHeight != null
        ? getTargetWidth(originalWidth, originalHeight)
        : customWidth ?? 1280;
    final targetHeight = originalHeight != null
        ? getTargetHeight(originalHeight)
        : customHeight ?? 720;

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
