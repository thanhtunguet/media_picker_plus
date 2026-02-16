## Unreleased

### Fixed
- **Dart `compressVideo` removed dead `getVideoInfo` call**: The method channel `compressVideo()` no longer calls the unimplemented `getVideoInfo` native method. The native side already extracts real video dimensions internally, so the Dart-side dimension pre-fetch was redundant and always fell back to hardcoded defaults.
- **iOS `compressVideo` rotation bug**: Fixed portrait video compression producing wrong dimensions. Now uses `preferredTransform` to detect rotation (matching the existing `applyVideo` pattern), calculates aspect-ratio-preserving output dimensions, and applies rotation-aware transforms.
- **iOS `compressVideo` compile regression**: Fixed an undefined export session reference in the no-video-track guard path; invalid inputs now return a clear `INVALID_VIDEO` error.
- **iOS/macOS `compressVideo` bitrate handling**: `targetBitrate` is now applied during export by setting an output file size limit based on media duration, so compression options are no longer ignored on Apple platforms.
- **Android camera recording `maxDuration` parity**: `MediaOptions.maxDuration` is now forwarded to camera capture intents through `MediaStore.EXTRA_DURATION_LIMIT` (seconds) for compatible camera apps.
- **iOS multi-pick source validation parity**: `pickMultipleMedia` now enforces gallery-only source and returns `invalid_source` for non-gallery inputs.
- **macOS preferred camera device parity**: `preferredCameraDevice` is now honored as a best-effort front/back camera selection for capture/recording, with fallback to default camera.
- **macOS watermark percentage parity**: `watermarkFontSizePercentage` is now applied for image/video watermark flows with fallback to absolute `watermarkFontSize`.
- **Dart method-channel error parity**: Non-cancel `PlatformException`s are now rethrown instead of wrapped in generic `Exception`, preserving native error codes and details.

### Added
- **iOS `getThumbnail`**: Extracts a video frame at a specified time using `AVAssetImageGenerator`. Supports optional post-processing (crop, watermark, quality) via the existing `processImage` pipeline.
- **macOS `getThumbnail`**: Same functionality as iOS, using `NSBitmapImageRep` for JPEG conversion.
- **macOS `pickMultipleMedia`**: Gallery-based multi-file picker using `NSOpenPanel` with `allowsMultipleSelection`. Supports filtering by image or video file types.
- **macOS `compressVideo`**: Full video compression with rotation-aware dimension handling, aspect ratio preservation, audio track passthrough, and `AVAssetExportSession`-based export. Matches the pattern established in the iOS and macOS `applyVideo` implementations.
- **Native `getPlatformVersion` support on Android/iOS/macOS**: Added method handling so Dart `getPlatformVersion()` now works consistently across all native platforms.

## 1.1.0-rc.14

### Fixed
- **Pick video / pickMedia result type**: Method channel now accepts both `String` and `Map` from native. When native returns a map (e.g. `{'path': '...'}`), the path is extracted so `pickVideo()` and other pick flows no longer throw due to type mismatch.
- **iOS error propagation**: iOS now returns `FlutterError` (not `{error:{code,message}}` maps) for picker failures like `save_failed`, ensuring Dart receives a proper `PlatformException` instead of an “unknown map structure”.

## 1.1.0-rc.13

### Added
- **Multi-image capture from camera with live preview**: Added `captureMultiplePhotos()` method with native camera preview for instant multi-capture. The screen displays a live camera preview using native platform views, with instant capture button that directly takes photos (no picker UI). Thumbnails appear in the bottom strip with badge count showing progress. Each image is processed with quality and watermark settings (crop is skipped for multi-image). **No external camera package dependencies** - uses only native camera APIs (AVCaptureSession on iOS, CameraX on Android).
- **`MultiImageOptions`**: New options class controlling `maxImages`, `minImages`, and `confirmOnDiscard` for multi-image flows.
- **`MultiCaptureScreen`**: Native camera preview screen with live feed embedded via platform views (UiKitView/AndroidView). Features:
  - **Zoom controls**: 0.5x, 1x, 2x, 3x zoom levels displayed at the top of the bottom control area. Fully functional with native camera zoom implementation on both iOS (AVCaptureDevice videoZoomFactor) and Android (CameraX setZoomRatio).
  - **Grouped thumbnails**: Stacked thumbnail preview on bottom-left corner showing latest captured photo with badge count. Tap to view all photos in a grid.
  - **Capture button**: Large centered button for instant photo capture
  - **Camera switch**: Flip button on bottom-right corner to switch between front and back cameras
  - **Grid view**: Tap the thumbnail group to see all captured photos in a 3-column grid with delete options
  - Thumbnail strip at bottom, badge count showing progress, instant capture button, and full-screen preview for captured photos
- **Native camera platform views**:
  - iOS: `CameraView.swift` using AVCaptureSession, AVCapturePhotoOutput, and AVCaptureVideoPreviewLayer with custom `CameraPreviewView` that properly handles layout updates
  - Android: `CameraView.kt` using CameraX (camera-camera2, camera-lifecycle, camera-view) with proper Activity lifecycle binding
  - Method channel for Flutter-native communication (`info.thanhtunguet.media_picker_plus/camera`)
  - Preview layer automatically resizes when view bounds change to ensure proper display
- **`MultiImageHelper`**: Orchestration class for camera multi-capture and gallery multi-pick with batch processing.
- **Cross-platform thumbnail widget**: `thumbnail_image.dart` with conditional imports for IO (`Image.file` with `cacheWidth`) and web (`Image.network`).
- Added "Multi-Capture Photos" demo button to example app.
- Added `doc/multi-image-capture.md` feature documentation.
- Added `doc/multi-capture-ui-layout.md` detailed UI layout documentation with implementation guide for zoom functionality.

### Fixed
- **iOS camera preview**: Fixed black screen issue by creating custom `CameraPreviewView` that updates preview layer frame in `layoutSubviews()` when bounds change
- **Android camera lifecycle**: Fixed camera initialization by properly passing Activity reference to CameraX via activity provider lambda, ensuring correct lifecycle binding
- **0.5x zoom uses ultrawide back lens**: Updated native multi-capture camera implementations to switch to back ultrawide hardware for `0.5x` when available, and switch back to standard wide lens for `1x+`. Added safe fallback to standard back lens on devices without ultrawide support.
- **Camera switch button in multi-capture screen**: Fixed front/back switching by keying native platform camera views with the selected device, forcing recreation with updated `preferredCameraDevice` params.
- **`captureMultiplePhotos()` web/macOS compatibility fallback**: Avoids not-implemented flows by falling back to a single camera capture on web and macOS, returning a one-item `List<String>` to keep API shape consistent.
- **Timestamp collision causing duplicate file paths**: Fixed bug where processing multiple media files (images/videos) within the same second would result in duplicate paths due to filename collisions. Updated all timestamp formats across Android, iOS, and macOS from second-precision to millisecond-precision. This affects: image picking (`pickMultipleImages`), video picking (`pickMultipleMedia`), watermarking (image/video), thumbnails, compression, and camera capture. All processed files now use `yyyyMMdd_HHmmss_SSS` format (or `Int(Date().timeIntervalSince1970 * 1000)`) ensuring unique filenames even with rapid successive operations. **Refactored to use reusable timestamp methods**: Android uses `generateTimestamp()` companion object method; iOS uses `SwiftMediaPickerPlusPlugin.generateTimestamp()` and `generateTimestampMillis()` static methods; macOS uses `MediaPickerPlusPlugin.generateTimestamp()` and `generateTimestampMillis()` static methods; `CameraView` has its own `generateTimestamp()` static method.
- **Picker cancellation returns `null` consistently**: Updated picker/capture dialog cancellation behavior to return `null` (instead of throwing errors) across Android, iOS, and macOS picker/capture cancel paths, aligning with existing nullable API contracts (`Future<String?>`, `Future<List<String>?>`) and web behavior. Kept non-picker failures (permissions/processing errors) as exceptions.

## 1.1.0-rc.11

### Added
- **Preferred camera device hint**: Added `preferredCameraDevice` to `MediaOptions` to request front/back camera for capture on Android/iOS. This is best-effort and may be ignored by Android camera apps; web currently ignores it.
- Added Zed Flutter debugging configuration (`.zed/debug.json`) and setup notes in `doc/zed-debugging.md`.

### Fixed
- Web `pickFile`/`pickMultipleFiles` now treat all selected files as generic files instead of validating as videos.
- Removed `dart:io` usage from crop UI flows on web by adding conditional file/image loaders.
- Guarded `CropUI` async state updates with `mounted` checks and expanded repaint conditions to handle layout changes.

## 1.1.0-rc.9

### Fixed
- Move Android image/video processing after capture or selection to background threads to avoid blocking the UI during compression or watermarking.
- **Android thread safety for media options**: Fixed race condition where background threads processing images/videos could read stale or incorrect `mediaOptions` if another request updated the global mutable state while processing was in progress:
  - Created `processVideoWithOptions` function that accepts options as a parameter (similar to existing `processImageWithOptions`)
  - Updated `processVideo` to snapshot `mediaOptions` and delegate to `processVideoWithOptions`
  - Updated `processVideoWithFFmpeg` and `watermarkVideoWithNativeProcessing` to accept options parameter instead of reading from global `mediaOptions`
  - Updated all `onActivityResult` call sites to snapshot `mediaOptions` before starting background threads, ensuring each request uses its own immutable copy of options
  - Added comprehensive tests for concurrency scenarios on both Android native and Dart sides
- **iOS build errors**: Fixed Swift compiler errors in iOS test pipeline:
  - Fixed iOS 14+ availability check for `.limited` authorization status in `hasGalleryPermission()` and `requestGalleryPermission()` methods to support iOS versions below 14.0
  - Fixed type mismatch errors in division operations by converting `Int` to `Double` before dividing by `100.0` in `processImage()` and `addWatermarkToExistingImage()` methods
- **Android release build errors**: Fixed compilation error in Android release builds where `integration_test` plugin (dev dependency) was being included in `GeneratedPluginRegistrant.java`. Added Gradle task to automatically remove `integration_test` plugin registration from generated files before release compilation.
- **Test timeouts**: Fixed timeout issues in `CropUI` tests by properly waiting for post-frame callbacks. Tests now pump frames correctly and wait for the `onCropChanged` callback to be triggered after widget initialization.
- **iOS build errors**: Fixed Swift compiler errors in iOS example app where `FlutterImplicitEngineDelegate` and `FlutterImplicitEngineBridge` types were not found. Simplified `AppDelegate.swift` to use standard `FlutterAppDelegate` pattern without implicit engine delegate.

## 1.1.0-rc.8

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
