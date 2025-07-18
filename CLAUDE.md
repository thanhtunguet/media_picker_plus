# Media Picker Plus - Flutter Plugin

This project is a Flutter plugin to pick media / files with advanced processing capabilities.

## Features
- Using system dialogs to pick files, images and videos
- Support resizing picked media files (max width, max height, preserve ratio, image quality)
- Support platforms: iOS, Android, macOS, web
- Add watermark to picked/captured/recorded videos / images
- **Interactive Cropping**: Advanced cropping functionality with manual selection UI

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
- **Interactive Cropping**: ✅ Complete (manual selection UI, aspect ratio control, zoom support)

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
- `CropOptions` - Configuration for cropping functionality
- `CropRect` - Normalized crop rectangle coordinates
- `CropUI` - Interactive cropping widget
- `CropHelper` - Utility for crop workflow management

### Platform-Specific Implementations
- **Android**: Java implementation with Mp4Composer for video watermarking + image cropping
- **iOS**: Swift implementation with AVFoundation for video processing + Core Graphics for image cropping
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

## Completed Features

### Interactive Cropping System (✅ Complete)
A comprehensive cropping system with the following features:

#### Core Components
- **CropOptions**: Configuration class for crop settings, aspect ratios, and presets
- **CropRect**: Normalized coordinate system (0.0-1.0) for crop rectangles
- **CropUI**: Interactive widget with draggable handles and visual feedback
- **CropHelper**: Workflow management for seamless crop integration

#### Key Features
- **Manual Selection**: Interactive UI with draggable corner handles
- **Aspect Ratio Control**: Support for freeform, square, 4:3, 3:4, 16:9 ratios
- **Visual Feedback**: Real-time crop preview with grid overlay
- **Zoom Support**: Dynamic zoom (up to 5x) when crop reaches minimum size
- **Minimum Size Protection**: 30% of smaller screen edge to prevent crashes
- **Performance Optimized**: Throttled callbacks, cached paint objects, RepaintBoundary

#### Technical Implementation
- **Normalized Coordinates**: Cross-platform compatibility using 0.0-1.0 coordinate system
- **Ratio-Based Movement**: Gesture tracking relative to image dimensions
- **Multi-Layer Validation**: Comprehensive error handling and fallback mechanisms
- **Platform Integration**: Native image processing on Android/iOS with processImage method
- **Memory Management**: Efficient handling of large images with proper cleanup

#### Files Involved
- `lib/crop_options.dart` - API definitions and configuration
- `lib/crop_ui.dart` - Interactive UI widget (main implementation)
- `lib/crop_helper.dart` - Workflow helper utilities
- `lib/media_picker_plus_platform_interface.dart` - Platform interface updates
- `android/src/main/kotlin/...Plugin.kt` - Android native processing
- `ios/Classes/MediaPickerPlusPlugin.swift` - iOS native processing
- `example/lib/main.dart` - Integration demonstration

#### Known Issues Fixed
- ✅ Infinite size rendering errors
- ✅ Scale assertion crashes (scale != 0.0)
- ✅ ArgumentError(0.1) with minimum size constraints
- ✅ Gesture tracking precision issues
- ✅ Original image returned instead of processed crop

## Next Development Priorities

### Immediate Tasks
1. **Complete macOS Implementation** - Add native cropping support
2. **Complete Web Implementation** - Canvas-based cropping functionality
3. **Video Cropping Support** - Extend cropping to video files
4. **Enhanced Testing** - Unit tests for crop functionality

### Future Enhancements
1. **Advanced Crop Shapes** - Circle, custom polygon support
2. **Batch Cropping** - Multiple image crop processing
3. **Crop Presets** - Save/load custom crop configurations
4. **Performance Metrics** - Crop operation timing and memory usage
