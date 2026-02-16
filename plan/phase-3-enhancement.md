# Phase 3 — Enhancements (Low Priority)

Goal: expand features and developer experience after macOS/Web are functional and test coverage is improved.

## Advanced Features
- [x] **Add multiple media selection support**
  - Implement multiple image/video selection
  - Add batch processing capabilities
  - Create progress tracking for multiple files
  - Handle memory management for large selections
  - Verification: `README.md` lists “Multiple Selection” as a feature and shows `pickMultipleImages` / `pickMultipleFiles` usage.

- [x] **Add multi-image capture from camera**
  - Added `captureMultiplePhotos()` public API with hub screen for continuous camera capture
  - Created `MultiImageOptions` class, `MultiCaptureScreen` hub widget, `MultiImageHelper` orchestrator
  - Cross-platform thumbnail widget with conditional imports (IO/Web)
  - Batch processing for quality + watermark (crop intentionally skipped)
  - Added demo button to example app
  - Documented in `doc/multi-image-capture.md`
  - Updated native zoom behavior: `0.5x` now targets back ultrawide lens where available (with fallback to standard back lens)
  - Fixed camera switch button by forcing platform camera view recreation when `preferredCameraDevice` changes
  - Added web/macOS compatibility fallback: `captureMultiplePhotos()` now performs a single camera capture and returns a one-item list

## Documentation & DevOps
- [ ] **Expand API documentation and usage examples**
  - Create comprehensive API documentation
  - Add usage examples and tutorials
  - Update README with detailed setup instructions
  - Create migration guides from other plugins
  - [x] Add watermark feature demonstration to example project
    - Created `example/lib/features/watermark_feature.dart` with interactive UI
    - Demonstrates `addWatermarkToImage()` and `addWatermarkToVideo()` methods
    - Includes configurable watermark text, font size, and position settings
  - [x] Create comprehensive example app with permissions, camerawesome integration, and all picking modes
    - Updated `example/lib/main.dart` with full feature set.

- [x] **Add Zed Flutter debugging configuration**
  - Added `.zed/debug.json` launch task for the example app.
  - Documented Zed usage in `doc/zed-debugging.md`.

- [ ] **Add CI/CD pipeline for automated testing**
  - [x] Set up GitHub Actions for automated testing (workflows exist: `ci.yml`, `docs.yml`, `publish.yml`)
  - [x] Fix `docs.yml` path typo preventing GitHub Pages deployment (`.github/workflows/docs.yml:52`)
  - [ ] Enable integration tests in CI (currently commented out in `ci.yml`)
  - [ ] Add platform-specific test runners
  - Implement automated publishing workflow (already exists: `publish.yml`)
  - Add code coverage reporting

## Technical Debt & Improvements

### Code Quality
- [ ] **Refactor existing code for better maintainability**
  - Extract common functionality into shared utilities
  - [x] Improve error handling consistency across platforms
    - Permission methods now rethrow non-permission PlatformExceptions instead of silently swallowing all errors
  - [x] Add proper logging and debugging capabilities
    - Added `MediaPickerLogger` utility (`lib/src/media_picker_logger.dart`) with opt-in debug logging
    - Web implementation now uses `MediaPickerLogger` instead of `print()` (fixing `avoid_print` lint)
    - CropHelper and MethodChannel log key flow stages when enabled
  - [x] Remove misleading zoom TODO comment in `multi_capture_screen.dart`
    - setZoom is fully implemented on Android (CameraX) and iOS (videoZoomFactor)
  - Optimize performance for large media files
    - Moved Android image/video processing after picker/camera results to background threads to avoid UI blocking.

### Platform Consistency
- [x] **Add preferred camera device hint for Android/iOS**
  - Added `preferredCameraDevice` in `MediaOptions` (auto/front/back) and passed to native pickers.
  - Android support is best-effort via camera intent extras; web/macOS currently ignore the hint.
- [ ] **Ensure consistent behavior across all platforms**
  - Standardize error messages and codes
  - Align permission handling patterns
  - Consistent file naming and storage patterns
  - Unified watermarking positioning and styling
  - Notes:
    - Resolved TODO-tracked gaps in iOS gallery permissions and Android media permission handling.
  - [x] Fix iOS image watermark bounds/positioning (prevent bottom-edge overflow vs Android)
    - Use `boundingRect`-based bounds + clamping for more accurate emoji/stroke/descender sizing.
  - [x] Handle multiline ("\n") watermark text on Android images/videos
    - Switch to StaticLayout-based rendering for text measurement and drawing.
  - [x] Align picker dialog cancellation behavior to nullable API contract
    - Android/iOS/macOS picker/capture cancel callbacks now return `null` instead of throwing cancellation errors.
    - Dart method-channel picker methods defensively map cancellation codes (`CANCELLED`, `cancelled`, `operation_cancelled`) to `null` while preserving non-cancel errors.

### Security & Privacy
- [ ] **Implement security best practices**
  - [x] Add input validation for all parameters
    - Added path traversal prevention (validates file paths for `..` sequences)
    - Added watermark text length validation (max 500 characters)
    - Validation applied to all file path parameters in public API and method channel
  - Implement proper file access controls
  - Add privacy-focused permission descriptions
  - Secure temporary file handling
