# Phase 3 — Enhancements (Low Priority)

Goal: expand features and developer experience after macOS/Web are functional and test coverage is improved.

## Advanced Features
- [x] **Add multiple media selection support**
  - Implement multiple image/video selection
  - Add batch processing capabilities
  - Create progress tracking for multiple files
  - Handle memory management for large selections
  - Verification: `README.md` lists “Multiple Selection” as a feature and shows `pickMultipleImages` / `pickMultipleFiles` usage.

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

- [ ] **Add CI/CD pipeline for automated testing**
  - Set up GitHub Actions for automated testing
  - Add platform-specific test runners
  - Implement automated publishing workflow
  - Add code coverage reporting

## Technical Debt & Improvements

### Code Quality
- [ ] **Refactor existing code for better maintainability**
  - Extract common functionality into shared utilities
  - Improve error handling consistency across platforms
  - Add proper logging and debugging capabilities
  - Optimize performance for large media files

### Platform Consistency
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

### Security & Privacy
- [ ] **Implement security best practices**
  - Add input validation for all parameters
  - Implement proper file access controls
  - Add privacy-focused permission descriptions
  - Secure temporary file handling
