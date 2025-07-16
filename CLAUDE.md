# Media Picker Plus - Flutter Plugin

This project is a Flutter plugin to pick media / files with advanced processing capabilities.

## Features
- Using system dialogs to pick files, images and videos
- Support resizing picked media files (max width, max height, preserve ratio, image quality)
- Support platforms: iOS, Android, macOS, web
- Add watermark to picked/captured/recorded videos / images

## Project Status

### Current Implementation Status
- **Android**: ✅ Complete (95%) - Full media picking, camera access, image/video processing, watermarking
- **iOS**: ✅ Complete (95%) - Full media picking, camera access, image/video processing, watermarking
- **macOS**: ❌ Minimal (5%) - Only basic plugin registration
- **Web**: ❌ Minimal (5%) - Only basic plugin registration

### Core Features Status
- **Media Picking**: ✅ Complete for mobile platforms
- **Camera Capture**: ✅ Complete for mobile platforms
- **Image Processing**: ✅ Complete (resize, quality, watermark)
- **Video Processing**: ✅ Complete (watermark overlay)
- **Permission Management**: ✅ Complete for mobile platforms
- **Watermarking**: ✅ Advanced implementation for mobile platforms

## Implementation Plan

### Phase 1: Platform Completion (High Priority)
1. **macOS Implementation**
   - Native media picking using NSOpenPanel
   - Camera access using AVCaptureDevice
   - Permission handling for camera and photo library
   - Image processing and watermarking
   - Video processing and watermarking

2. **Web Implementation**
   - HTML5 media APIs for camera access
   - File picker for gallery selection
   - Client-side image/video processing
   - Canvas-based watermarking

### Phase 2: Testing & Quality (Medium Priority)
3. **Testing Suite**
   - Unit tests for all platform implementations
   - Integration tests for camera and gallery functionality
   - Mock testing for permissions and file operations

4. **File Picker Support**
   - Document selection functionality
   - Support for various file types
   - File validation and processing

### Phase 3: Enhancement (Low Priority)
5. **Multi-Selection Support**
   - Multiple image/video selection
   - Batch processing capabilities
   - Progress tracking for multiple files

6. **Documentation & CI/CD**
   - Comprehensive API documentation
   - Usage examples and tutorials
   - Automated testing pipeline

## Key Architectural Components

### Flutter Layer
- `MediaPickerPlus` - Main plugin class
- `MediaOptions` - Configuration for quality, dimensions, watermarking
- `MediaSource` - Enums for gallery, camera, files
- `MediaType` - Enums for image, video, file
- `WatermarkPosition` - Positioning constants

### Platform-Specific Implementations
- **Android**: Java implementation with Mp4Composer for video watermarking
- **iOS**: Swift implementation with AVFoundation for video processing
- **macOS**: Swift implementation (to be completed)
- **Web**: JavaScript implementation (to be completed)

## Development Guidelines

### Code Standards
- Follow Flutter plugin best practices
- Maintain consistent error handling across platforms
- Use proper permission handling for each platform
- Implement comprehensive logging and debugging

### Testing Requirements
- Unit tests for all public APIs
- Integration tests for platform-specific functionality
- Permission testing scenarios
- Error handling validation

### Performance Considerations
- Efficient image/video processing
- Memory management for large media files
- Progress callbacks for long operations
- Proper cleanup of temporary files

