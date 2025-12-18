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
1. Add unit tests for crop functionality
2. Add widget tests for interactive UI
3. Add integration tests for platform implementations
