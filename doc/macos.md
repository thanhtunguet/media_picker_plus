# macOS Platform - Technical Documentation

## Overview
The macOS implementation provides partial media picking and camera capture capabilities using native macOS frameworks. Currently at ~15% completion with basic functionality implemented but several features requiring full implementation.

## Native Libraries Used

### Core macOS Frameworks
- **AVFoundation** - Camera capture and video processing
  - Purpose: Camera/microphone access, video recording, composition
  - Status: ✅ Basic implementation complete

- **Cocoa/AppKit** - UI components and file dialogs
  - Purpose: NSOpenPanel for file selection, NSImage processing
  - Status: ✅ Complete implementation

- **Photos** - Photo library access (macOS 11.0+)
  - Purpose: PHPhotoLibrary permissions (when needed)
  - Status: ⚠️ Limited implementation

- **UniformTypeIdentifiers** - File type handling (macOS 11.0+)
  - Purpose: UTType-based file filtering in NSOpenPanel
  - Status: ✅ Complete with legacy fallbacks

- **Core Animation** - Video watermark overlay
  - Purpose: CATextLayer composition for video watermarks
  - Status: ✅ Complete implementation

## Implementation Status

### ✅ Fully Implemented Features (15% Complete)

#### File Selection
- **NSOpenPanel Integration**: Complete file picker with content type filtering
- **Multiple File Selection**: Full support for selecting multiple files
- **Extension Filtering**: UTType-based filtering (macOS 11.0+) with legacy fallbacks
- **Document Types**: Support for all common file types and MIME types

#### Basic Camera Functionality
- **Device Discovery**: Smart device selection with Continuity Camera support (macOS 14.0+)
- **Permission Management**: Camera and microphone permission handling
- **Photo Capture**: Basic photo capture using AVCapturePhotoOutput
- **Video Recording**: Basic video recording with auto-stop functionality
- **Preferred Camera Device**: `preferredCameraDevice` is currently ignored on macOS (no explicit selection support).

#### Image Processing (Basic)
- **Watermarking**: Text overlay with dynamic font sizing and positioning
- **Cropping**: Manual rectangle and aspect ratio-based cropping
- **Resizing**: Max width/height with aspect ratio preservation
- **Format Support**: JPEG output with configurable quality

### 🔄 Partially Implemented Features

#### Video Processing
- **Watermarking**: ✅ Native AVFoundation-based text overlay
- **Cropping**: ✅ Rectangle and aspect ratio support
- **Compression**: ✅ Full `compressVideo` with rotation-aware transforms, aspect ratio preservation, and audio passthrough
- **Thumbnail Extraction**: ✅ `getThumbnail` using AVAssetImageGenerator with optional post-processing
- **Quality Control**: ⚠️ Basic export quality settings with bitrate-targeted size limiting in `compressVideo`
- **Format Support**: ⚠️ Limited to MOV/MP4 output

#### Gallery Access
- **File System**: ✅ NSOpenPanel works well for file selection
- **Photos Library**: ⚠️ Limited PHPhotoLibrary integration
- **Content Types**: ✅ Smart filtering for images and videos
- **Multiple Media Selection**: ✅ `pickMultipleMedia` with image/video type filtering via NSOpenPanel

### ❌ Missing Features (85% Incomplete)

#### Advanced Camera Features
- **Camera Preview**: No live preview implementation
- **Focus/Exposure Control**: No manual camera controls
- **Multiple Camera Support**: Basic device selection only
- **Recording Quality Options**: Limited bitrate/resolution control

#### Advanced Image Processing
- **Batch Processing**: No multiple image processing
- **Advanced Filters**: No color correction or effects
- **Metadata Preservation**: EXIF data not maintained
- **RAW Format Support**: Only basic formats supported

#### Advanced Video Processing
- **Trimming/Editing**: No video editing capabilities
- **Multiple Track Support**: Basic single track only
- **Hardware Acceleration**: Not optimized for performance
- **Background Processing**: No async processing support

#### System Integration
- **Drag & Drop**: No drag-drop support
- **Quick Look**: No preview integration
- **Spotlight**: No search integration
- **Sandboxing**: Basic sandbox compliance only

## Developer Configuration Notes

### Required Permissions
Add to `macos/Runner/Info.plist`:

```xml
<!-- Camera and microphone permissions -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture photos and videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio with videos</string>

<!-- Photo library access (if using programmatic access) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to manage photos</string>
```

### macOS Version Support
Minimum deployment target in `macos/Runner.xcodeproj`:
```
MACOSX_DEPLOYMENT_TARGET = 10.14
```

**Version-specific Features:**
- **macOS 14.0+**: Continuity Camera support
- **macOS 11.0+**: UTType file filtering, enhanced permissions
- **macOS 10.14+**: Basic AVFoundation functionality

### Sandboxing Configuration
For App Store distribution, update `macos/Runner/Release.entitlements`:

```xml
<!-- Camera and microphone access -->
<key>com.apple.security.device.camera</key>
<true/>
<key>com.apple.security.device.microphone</key>
<true/>

<!-- File system access for user-selected files -->
<key>com.apple.security.files.user-selected.read-write</key>
<true/>

<!-- Temporary directory access -->
<key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
<array>
    <string>/private/tmp/</string>
</array>
```

### Build Configuration
Update `macos/Runner.xcodeproj` build settings:

```xcconfig
ENABLE_HARDENED_RUNTIME = YES
ENABLE_USER_SELECTED_FILES = YES
DEVELOPMENT_TEAM = [Your Team ID]
```

## Performance Characteristics

### File Operations
- **NSOpenPanel**: Native performance, good user experience
- **File Copying**: Basic I/O performance
- **Multiple Selection**: Handles moderate file counts well

### Camera Operations
- **Device Discovery**: Fast for built-in cameras, slower for Continuity Camera
- **Photo Capture**: Good performance, 1-3 second delay
- **Video Recording**: Acceptable performance with auto-stop

### Processing Performance
- **Image Processing**: Moderate performance using NSImage/Core Graphics
- **Video Processing**: Slower than iOS due to less optimization
- **Memory Usage**: Higher than mobile platforms

## Known Issues & Limitations

### Camera Issues
- **Long Initialization**: Continuity Camera can take 5-10 seconds to initialize
- **Auto-Recording**: No interactive stop control for video recording
- **Preview Missing**: No live camera preview for user feedback
- **Multiple Cameras**: Basic support, no camera switching UI

### Processing Limitations
- **Synchronous Operations**: Blocking UI during processing
- **Memory Usage**: High memory consumption for large files
- **Format Support**: Limited output format options
- **Quality Control**: Basic compression settings only

### System Integration
- **Sandbox Restrictions**: Limited file system access outside user selection
- **Background Processing**: No background task support
- **Energy Efficiency**: Not optimized for battery usage
- **Hardware Acceleration**: Limited use of GPU acceleration

## Troubleshooting

### Common Issues

#### Permission Denied Errors
- Verify Info.plist entries are complete
- Check System Preferences > Security & Privacy settings
- Ensure proper entitlements for sandboxed apps
- Test permission prompts in development builds

#### Camera Access Failures
- Check for multiple apps using camera simultaneously
- Verify camera hardware availability
- Test with different camera types (built-in vs. external)
- Monitor for Continuity Camera connectivity issues

#### File Access Issues
- Ensure NSOpenPanel is used for user file selection
- Check sandboxing entitlements for file access
- Verify temporary directory permissions
- Handle security-scoped bookmarks properly

#### Performance Problems
- Monitor memory usage during processing
- Check for memory leaks in capture sessions
- Profile video processing operations
- Optimize for specific macOS versions

### Debug Information
Enable detailed logging by monitoring:
- Console output for plugin debug messages
- AVFoundation error domains and codes
- NSOpenPanel user cancellation events
- Memory pressure and performance metrics

## Architecture Notes

### File Access Strategy
- **User-Selected Files**: NSOpenPanel provides proper sandboxing compliance
- **Temporary Files**: Use NSTemporaryDirectory() for processed media
- **Security-Scoped Resources**: Minimal usage, prefer copying to temp directory
- **Cleanup**: Manual temporary file management required

### Camera Session Management
- **Single Session**: One AVCaptureSession at a time to avoid conflicts
- **Proper Cleanup**: Stop sessions and release delegates to prevent memory leaks
- **Timeout Handling**: Auto-timeout for failed operations
- **Device Selection**: Prioritize newer camera types when available

### Threading Model
- **Main Thread**: UI operations, permission dialogs, delegate callbacks
- **Background Queues**: File I/O, processing operations
- **Synchronization**: DispatchSemaphore for async-to-sync bridging
- **Memory Management**: ARC with manual session cleanup

## Testing Recommendations

### Unit Testing
- File selection and filtering logic
- Permission state management
- Basic image processing operations
- Error handling scenarios

### Integration Testing
- Cross-macOS version compatibility (10.14-14.0+)
- Different camera configurations
- Various file types and sizes
- Sandbox compliance testing

### Performance Testing
- Memory usage during processing
- Camera initialization timing
- File operation performance
- Large file handling

## Future Development Priorities

### Phase 1: Core Completion (High Priority)
1. **Camera Preview**: Implement live camera preview UI
2. **Interactive Recording**: Add user controls for video recording
3. **Advanced Device Support**: Better multi-camera handling
4. **Background Processing**: Async processing for large files

### Phase 2: Enhanced Features (Medium Priority)
1. **Batch Processing**: Multiple file processing capabilities
2. **Advanced Quality Control**: More compression and format options
3. **Metadata Preservation**: EXIF and video metadata handling
4. **Hardware Acceleration**: GPU-accelerated processing

### Phase 3: System Integration (Low Priority)
1. **Drag & Drop**: Native macOS drag-drop support
2. **Quick Look**: Preview integration
3. **Service Extensions**: macOS Services menu integration
4. **Spotlight Support**: Search and indexing integration

### Phase 4: Advanced Features (Future)
1. **Real-time Effects**: Live filters during capture
2. **RAW Processing**: Support for RAW image formats
3. **Professional Tools**: Advanced editing capabilities
4. **Multi-display Support**: Extended desktop features

## Implementation Roadmap

### Immediate Tasks (Next Release)
- Complete camera preview implementation
- Add interactive video recording controls
- Improve error handling and user feedback
- Optimize memory usage and performance

### Short-term Goals (6 months)
- Achieve 50% feature parity with iOS implementation
- Complete batch processing capabilities
- Add comprehensive test coverage
- Improve documentation and examples

### Long-term Vision (1 year)
- Full feature parity with mobile platforms
- Native macOS-specific enhancements
- Professional-grade processing capabilities
- App Store ready with full sandboxing support
