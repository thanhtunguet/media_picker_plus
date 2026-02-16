# Phase 2 — Testing & Quality (Medium Priority)

Goal: improve confidence and prevent regressions across platforms and the crop UI.

## Testing Suite
- [x] **Add comprehensive unit tests for all platform implementations**
  - Create unit tests for Flutter layer (MediaPickerPlus, MediaOptions)
  - Add platform-specific unit tests for Android, iOS, macOS, Web
  - Test error handling and edge cases
  - Mock external dependencies and platform APIs
  - Notes:
    - Dart-side unit/widget tests cover the Flutter layer, MethodChannel implementation, Web implementation, and crop UI/options.
    - Web tests that require a real browser file picker are marked as skipped to keep automated runs reliable.
    - Added issue-focused tests for method-channel crop behavior, web applyImage data URLs, and native image quality handling.

- [x] **Add integration tests for camera and gallery functionality**
  - Create integration tests for camera capture flow
  - Add integration tests for gallery selection
  - Test permission handling scenarios
  - Validate file processing and watermarking end-to-end
  - Notes:
    - Integration tests are added under `example/integration_test/` and use a mocked MethodChannel to validate end-to-end wiring in a real Flutter runtime.

## File System Support
- [x] **Implement file picker functionality for document selection**
  - Add support for MediaSource.files
  - Implement document picker for each platform
  - Add file type validation and filtering
  - Handle various file formats and sizes
  - Verification: `README.md` documents `MediaPickerPlus.pickFile` and `MediaPickerPlus.pickMultipleFiles` with extension filtering.

## Next Session Priorities (Actionable)
1. ~~Add unit tests for crop functionality~~ — Added input validation tests + updated existing tests to reflect new PlatformException behaviour
2. ~~Add widget tests for interactive CropUI (expand beyond existing 2 tests)~~ — Added 8 CropHelper unit tests and expanded CropUI widget tests from 2 to 12 tests (10 new tests)
3. ~~Fix pre-existing multi_capture_screen_test.dart failures (8 tests, likely UI state setup issues)~~ — Rewrote tests for current native camera implementation (7 new tests, 9 legacy tests properly skipped)
4. Enable integration tests in CI (currently commented out in `ci.yml`)
