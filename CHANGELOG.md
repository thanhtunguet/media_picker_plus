## Unreleased

### Added
- Comprehensive example app (`example/lib/main.dart`) demonstrating permissions, picking, cropping, watermarking, and `camerawesome` integration.
- Fullscreen viewer for selected media in example app: Users can now tap on displayed images or videos to view them in fullscreen mode with pinch-to-zoom functionality using `InteractiveViewer`.

### Fixed

## 0.3.0-rc.5

### Added

- Unit/widget tests for crop options and interactive crop UI.
- Integration tests (mocked MethodChannel) for camera/gallery/file flows under `example/integration_test/`.
- `CropUI` now supports `initialImage` injection (useful for tests/advanced usage).
- **Standalone watermarking methods**: `MediaPickerPlus.addWatermarkToImage()` and `MediaPickerPlus.addWatermarkToVideo()` for adding watermarks to existing media files.
- **Watermark feature example**: Added comprehensive watermark feature demonstration in `example/lib/features/watermark_feature.dart` with interactive UI for adding watermarks to photos and videos.
- **Third-party camera integration demo**: Added example showing how to integrate third-party camera packages with MediaPickerPlus watermarking functionality.
- **Percentage-based watermark font size**: Added `watermarkFontSizePercentage` parameter to `MediaOptions` for responsive watermark sizing. Font size is calculated as a percentage (default 4%) of the shorter edge of the image/video, ensuring consistent watermark appearance across different media dimensions. Updated all platform implementations (Android, iOS, Web) to support this feature.

### Fixed

- Fix iOS image watermark positioning so it no longer overflows the image edge (more consistent with Android).
- Crop UI now emits the initial crop rectangle reliably (avoids first callback being throttled).
- Fix black image output issue in iOS `addWatermarkToImage` method by improving graphics context configuration.

## 0.1.2+4

### Fixed

- Refactored example project for easier maintainance
- Fixed bug: cropping image outputed wrong result image (iOS)
- Fixed bug: picking image on web
- Fixed bug: error picking file on Android

## 0.1.1+3

### Fixed

- `dart:js_util` deprecated, replaced with `dart:js_interop`

## 0.1.0+2

### Added
- Cropping feature

### Fixed
- Remove included permission declarations to avoid unnecessary permission requirements when publishing to Play Store

## 0.0.1+1

### Added
- Picking image / multiple images / video / multiple videos
- Capturing photo directly from camera
- Recording video directly from camera
- Resizing picked images/videos
- Add watermark for images
- Add watermark for videos (iOS / macOS only)
