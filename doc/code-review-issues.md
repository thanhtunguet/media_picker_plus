# Code Review Issues

This document tracks potential issues and unclean code discovered during review.

## Issues

1. iOS image quality uses integer division, so values < 100 become 0 and produce extremely low-quality output.
   - ios/Classes/MediaPickerPlusPlugin.swift:1563
   - ios/Classes/MediaPickerPlusPlugin.swift:1611

2. Android thumbnail extraction blocks with CountDownLatch.await(30s), risking ANR/hangs if run on the platform thread.
   - android/src/main/kotlin/info/thanhtunguet/media_picker_plus/MediaPickerPlusPlugin.kt:1969

3. Android compressVideoWithMediaCodec does not compress; it copies the file and returns success.
   - android/src/main/kotlin/info/thanhtunguet/media_picker_plus/MediaPickerPlusPlugin.kt:2332

4. Android applyVideo ignores resize/compression when no watermark is specified, returning the original path.
   - android/src/main/kotlin/info/thanhtunguet/media_picker_plus/MediaPickerPlusPlugin.kt:2143

5. iOS gallery permission does not treat limited access as granted.
   - ios/Classes/MediaPickerPlusPlugin.swift:264
   - ios/Classes/MediaPickerPlusPlugin.swift:268

6. Android gallery permission requires both READ_MEDIA_IMAGES and READ_MEDIA_VIDEO, so image-only permission blocks image picking.
   - android/src/main/kotlin/info/thanhtunguet/media_picker_plus/MediaPickerPlusPlugin.kt:539

7. Method-channel cropping path returns uncropped media when cropOptions.enableCrop is true and freeform is true without a BuildContext.
   - lib/media_picker_plus_method_channel.dart:28

8. Unused/duplicate web camera preview UI path (CameraPreviewController/Overlay not referenced).
   - lib/camera_preview_controller.dart
   - lib/camera_preview_web.dart
