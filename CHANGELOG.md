## Unreleased

### Added
- Issue-focused tests across Flutter, web, and native targets to capture current behavior.

### Fixed
- **Android video compression rotation**: Fixed aspect ratio calculation in `compressVideo` to account for video rotation metadata. Videos with 90° or 270° rotation now correctly use effective (post-rotation) dimensions for scaling calculations, preventing incorrect output dimensions when FFmpeg auto-rotates frames.
- **Android thread safety**: Fixed race conditions when processing media from background threads:
  - Added `@Volatile` annotation to `mediaOptions` for thread-safe reads
  - Created `processImageWithOptions` helper that takes explicit options instead of relying on global mutable state
  - Fixed `extractThumbnail` to use the new thread-safe helper instead of mutating global `mediaOptions`
  - Removed unnecessary `mediaOptions` mutation in `processVideo` that created a race condition with no benefit
- **iOS thread safety**: Fixed race condition in `PHPickerViewControllerDelegate` where background closures could read stale `mediaOptions` if another method channel call changed it:
  - Created overloaded `saveMediaToFile(info:options:)` that takes explicit options parameter
  - Updated PHPicker delegate to capture `mediaOptions` at the start and pass it explicitly to background closures
- **iOS build errors**: Fixed Swift compiler errors in `addWatermarkToVideoComposition` method usage:
  - Fixed incorrect parameter label `renderSize:` (should be `videoSize:`)
  - Fixed incorrect use of optional binding for non-optional return type
- Documented known issues and added TODO markers for follow-up fixes.
- Fixed TODO-tracked issues across iOS gallery permissions, image quality handling, Android thumbnail extraction, video processing, and gallery permissions.

## 1.1.0-rc.7

### Fixed
- **Video rotation on all platforms**: Fixed video rotation issue where videos captured by the camera were incorrectly rotated from portrait to landscape during processing.
  - **iOS/macOS**: The `applyVideo` method now properly uses the video track's `preferredTransform` matrix instead of a simplified rotation check, ensuring captured videos maintain their original orientation.
  - **Android**: Fixed dimension calculations to use effective (post-rotation) dimensions. Removed explicit rotation filters from FFmpeg commands since FFmpeg auto-rotates based on metadata. Updated `applyVideo`, `processVideo`, and `watermarkVideoWithNativeProcessing` to correctly handle rotated videos.

### Changed
- Example fullscreen image viewer now displays basic image metadata (width, height, and configured quality).
- Example fullscreen video viewer now displays video metadata (width, height, and quality).
- Generated thumbnails in the example app are now clickable and can be opened in the fullscreen image viewer.

## 1.1.0-rc.5

### Fixed
- Android watermark text now supports line breaks ("\n") consistently across images and videos.

## 1.1.0-rc.4

### Fixed
- **WebAssembly compatibility**: Fixed all WebAssembly compatibility issues to enable WASM builds for web platform:
  - Fixed JS interop type casting issues by replacing unsafe `as JSAny` casts with proper `.toJS` method calls
  - Converted async event handlers to synchronous ones since WebAssembly doesn't support async functions in JS interop
  - Fixed canvas context property assignments (`fillStyle`, `strokeStyle`) to use proper JS interop conversion
  - Replaced unsafe JS interop value casting with proper `(value as JSAny).dartify() as String` conversions
  - Fixed runtime type checking with JS interop types to avoid platform-inconsistent behavior
- Web builds now compile successfully with WebAssembly support enabled

## 1.0.0

### Added
- **Video compression**: Added `compressVideo()` method to compress video files with customizable quality, resolution, and bitrate settings. Includes industry-standard quality presets (360p, 480p, 640p, 720p, 1080p, 1280p, 1440p, 1920p, 2K, Original) with aspect ratio preservation and optimized bitrates. Features progress callbacks and option to delete original files after compression. Supported on Android (MediaCodec), iOS/macOS (AVFoundation), with web implementation planned for future release.
- **Video thumbnail extraction**: Added `getThumbnail()` method to extract thumbnail images from video files at specified times. Supports customizable extraction time (default 1 second), resizing options, quality control, and watermarking. Works on all platforms (Android, iOS, macOS, Web) using FFmpeg on native platforms and HTML5 Canvas API on web.
- Comprehensive example app (`example/lib/main.dart`) demonstrating permissions, picking, cropping, watermarking, and `camerawesome` integration.
- Fullscreen viewer for selected media in example app: Users can now tap on displayed images or videos to view them in fullscreen mode with pinch-to-zoom functionality using `InteractiveViewer`.
- **macOS camera preview**: Added native camera preview window for photo and video capture on macOS using `AVCaptureVideoPreviewLayer`. Users now see a live camera preview with manual capture controls (Capture/Record buttons) similar to iOS `UIImagePickerController`, replacing the previous silent automatic capture behavior.
- **Web permission documentation**: Added comprehensive guide (`docs/web-permissions.md`) explaining how browser permissions work on web, why `permission_handler` doesn't support web, and how to properly handle permissions across platforms.
- **Web platform considerations in README**: Added prominent section in README warning developers about web-specific requirements: checking `kIsWeb` before using `Platform` APIs, using `Image.network()` for images, using `VideoPlayerController.networkUrl()` for videos, and proper permission handling. Includes complete code examples for all common scenarios.

### Fixed
- **Web permission handling**: Fixed example app attempting to use `Permission.photos`, `Permission.camera`, and `Permission.microphone` on web platform where they are not supported. The example app now correctly skips permission requests on web (where browser handles permissions automatically) and desktop platforms (where permissions are configured via Info.plist/manifest). Only mobile platforms (Android/iOS) now request runtime permissions.
- **Web image display**: Fixed `Image.file()` assertion error on web platform by implementing platform-aware image loading. The example app now uses `Image.network()` for data URLs and blob URLs on web, and `Image.file()` for file paths on native platforms. Added helper function `_buildImage()` demonstrating the recommended pattern for cross-platform image display.
- **Web video playback**: Fixed "Unsupported operation: Platform._operatingSystem" error when playing videos on web. The example app now uses `VideoPlayerController.networkUrl()` for data/blob URLs on web, and `VideoPlayerController.file()` for file paths on native platforms.
- **Web path display**: Improved example app to show user-friendly path descriptions (e.g., "Image (data URL)") instead of displaying long base64 strings on web platform. Native platforms continue to show full file paths.
- **Watermark font consistency**: Fixed video watermarks to match photo watermark styling on iOS and macOS. Video watermarks now use attributed strings with black stroke/outline (strokeWidth: -2), creating consistent white text with black outline across both images and videos.
- **Android video watermarking**: Fixed FFmpeg command incompatibility with ffmpeg-kit-https variant. Changed from libx264 encoder with preset options to mpeg4 encoder with quality parameter (-q:v 5), resolving "Unrecognized option 'preset'" error that prevented video watermarking on Android.
- **Android captured video watermarking**: Added fallback to resolve recorded video paths from camera content URIs when the app-provided file is empty, ensuring watermarking runs for camera captures.
- **Android video watermark styling**: Removed the semi-transparent background from video watermark bitmaps so Android video watermarks match photo styling and iOS appearance.
- **Android video watermark positioning**: Adjusted watermark coordinates for rotated portrait videos so right-side placements stay visible.

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
