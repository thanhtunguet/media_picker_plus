# Phase 2 — Testing & Quality (Medium Priority)

Goal: improve confidence and prevent regressions across platforms and the crop UI.

## Testing Suite
- [ ] **Add comprehensive unit tests for all platform implementations**
  - Create unit tests for Flutter layer (MediaPickerPlus, MediaOptions)
  - Add platform-specific unit tests for Android, iOS, macOS, Web
  - Test error handling and edge cases
  - Mock external dependencies and platform APIs

- [ ] **Add integration tests for camera and gallery functionality**
  - Create integration tests for camera capture flow
  - Add integration tests for gallery selection
  - Test permission handling scenarios
  - Validate file processing and watermarking end-to-end

## File System Support
- [ ] **Implement file picker functionality for document selection**
  - Add support for MediaSource.files
  - Implement document picker for each platform
  - Add file type validation and filtering
  - Handle various file formats and sizes

## Next Session Priorities (Actionable)
1. Add unit tests for crop functionality
2. Add widget tests for interactive UI
3. Add integration tests for platform implementations

