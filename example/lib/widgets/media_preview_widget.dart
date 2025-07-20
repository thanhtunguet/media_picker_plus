import 'package:flutter/material.dart';

import '../media_preview_widgets.dart';

class MediaPreviewWidget extends StatelessWidget {
  final String mediaPath;
  final String? title;
  final VoidCallback? onClear;
  final double height;
  final bool showControls;
  final bool enableImageResize;
  final int? maxWidth;
  final int? maxHeight;

  const MediaPreviewWidget({
    super.key,
    required this.mediaPath,
    this.title,
    this.onClear,
    this.height = 300,
    this.showControls = true,
    this.enableImageResize = true,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = mediaPath.toLowerCase().endsWith('.mp4') ||
        mediaPath.toLowerCase().endsWith('.mov');

    if (isVideo) {
      return EnhancedVideoPlayer(
        videoPath: mediaPath,
        title: title,
        onClear: onClear,
        height: height,
        showControls: showControls,
        autoPlay: false,
        maxWidth: enableImageResize ? maxWidth : null,
        maxHeight: enableImageResize ? maxHeight : null,
        resizeEnabled: enableImageResize,
      );
    } else {
      return EnhancedImagePreview(
        imagePath: mediaPath,
        title: title,
        onClear: onClear,
        height: height,
        showControls: showControls,
        maxWidth: enableImageResize ? maxWidth : null,
        maxHeight: enableImageResize ? maxHeight : null,
        resizeEnabled: enableImageResize,
      );
    }
  }
}
