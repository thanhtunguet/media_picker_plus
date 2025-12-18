## Unreleased

### Added

- Unit/widget tests for crop options and interactive crop UI.
- Integration tests (mocked MethodChannel) for camera/gallery/file flows under `example/integration_test/`.
- `CropUI` now supports `initialImage` injection (useful for tests/advanced usage).

### Fixed

- Fix iOS image watermark positioning so it no longer overflows the image edge (more consistent with Android).
- Crop UI now emits the initial crop rectangle reliably (avoids first callback being throttled).

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
