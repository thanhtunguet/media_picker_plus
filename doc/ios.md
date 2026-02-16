# iOS Platform - Technical Documentation

## Overview
The iOS implementation provides comprehensive media picking, camera capture, and processing capabilities leveraging native iOS frameworks. The implementation supports iOS 12.0+ with modern APIs for iOS 14+ where applicable.

## Native Libraries Used

### Core iOS Frameworks
- **AVFoundation** - Camera capture, video processing, and media composition
  - Purpose: Camera access, video recording, metadata retrieval
  - Status: ✅ Fully implemented

- **Photos/PhotosUI** - Gallery access and modern photo picker
  - Purpose: Photo library access, PHPickerViewController (iOS 14+)
  - Status: ✅ Fully implemented with fallbacks

- **UIKit** - User interface and image picker
  - Purpose: UIImagePickerController, view presentation
  - Status: ✅ Complete implementation

- **Core Graphics** - Image processing and manipulation
  - Purpose: Image cropping, watermarking, drawing operations
  - Status: ✅ Complete implementation

- **Core Animation** - Video watermark overlay
  - Purpose: CATextLayer, CALayer composition for video watermarks
  - Status: ✅ Complete implementation

- **UniformTypeIdentifiers** - File type handling (iOS 14+)
  - Purpose: Modern file type identification and filtering
  - Status: ✅ Complete with legacy fallbacks

## Implementation Status

### ✅ Fully Implemented Features (95% Complete)

#### Media Picking
- **Gallery Access**: Complete with PHPickerViewController (iOS 14+) and UIImagePickerController fallback
- **Camera Capture**: Full image and video capture with configurable quality settings
- **Permission Management**: Comprehensive permission handling for camera, microphone, and photo library
- **Document Picker**: File selection with UTType filtering (iOS 14+) and legacy document types

#### Image Processing
- **Resizing**: Max width/height with aspect ratio preservation using Core Graphics
- **Quality Control**: JPEG compression with configurable quality levels (75-90%)
- **Watermarking**: Text overlay with 9 positioning options using Core Graphics
- **Cropping**: Interactive manual cropping with normalized coordinates and aspect ratio support
- **Format Support**: Native support for JPEG, PNG, HEIF/HEIC

#### Video Processing
- **Watermarking**: Native AVFoundation-based text overlay using Core Animation
- **Cropping**: Rectangle and aspect ratio-based cropping using AVMutableVideoComposition
- **Compression**: Rotation-aware `compressVideo` with aspect ratio preservation and audio passthrough
- **Thumbnail Extraction**: `getThumbnail` using AVAssetImageGenerator with optional post-processing
- **Format Support**: MP4, MOV, QuickTime formats
- **Quality Control**: Configurable export quality and bitrate-targeted size limiting during compression

#### Permission System
- **Camera Access**: AVCaptureDevice authorization with proper status handling
- **Microphone Access**: Audio recording permissions for video capture
- **Photo Library**: PHPhotoLibrary authorization with limited/full access support
- **Runtime Requests**: Proper async permission request flows with completion handlers

### 🔄 Current Implementation Strengths

#### Native Video Processing
**Current Implementation**: Using AVFoundation's native composition and Core Animation
- **Performance**: Excellent - leverages hardware acceleration
- **Quality**: High-quality output with configurable compression
- **Memory Efficiency**: Optimized for iOS memory management
- **Integration**: Seamless with iOS media pipeline

#### Permission Management
**Current Implementation**: Proper iOS permission patterns
- **User Experience**: Native iOS permission dialogs
- **Privacy Compliance**: Follows iOS privacy guidelines
- **Status Handling**: Comprehensive permission state management
- **Graceful Degradation**: Proper fallbacks for denied permissions

#### Modern API Support
**Current Implementation**: iOS 14+ features with legacy fallbacks
- **PHPickerViewController**: Modern photo picker with better privacy
- **UniformTypeIdentifiers**: Type-safe file filtering
- **Multiple Selection**: Native multiple media selection support
- **Backward Compatibility**: Graceful fallbacks for older iOS versions

### ⚠️ Known Limitations

#### File Management
- **Temporary Files**: Created in app's temporary directory
- **Cleanup**: Manual cleanup required for processed files
- **Storage Location**: Limited to app sandbox for security
- **Large Files**: Memory pressure on older devices with limited RAM

#### Video Processing Performance
- **Synchronous Export**: Uses DispatchSemaphore for synchronous operations
- **Memory Usage**: Higher memory consumption during video composition
- **Export Time**: Processing time increases with video length and resolution
- **Background Processing**: No background processing support currently

## Developer Configuration Notes

### Preferred camera device
Use `MediaOptions(preferredCameraDevice: PreferredCameraDevice.front|back|auto)` to select a preferred camera for photo/video capture APIs.

On iOS this maps to `UIImagePickerController.cameraDevice` when that device is available; otherwise the system default camera is used. `pickMultipleMedia` remains gallery-only and now rejects non-gallery sources with `invalid_source`.


### Required Permissions
Add to `ios/Runner/Info.plist`:

```xml
<!-- Camera and microphone permissions -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture photos and videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio with videos</string>

<!-- Photo library permission -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images and videos</string>

<!-- Limited photo library access (iOS 14+) -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs photo library access to save processed media</string>
</xml>

### iOS Version Support
Minimum deployment target in `ios/Runner.xcodeproj`:
```
IPHONEOS_DEPLOYMENT_TARGET = 12.0
```

### Privacy Manifest (iOS 17+)
The plugin includes a privacy manifest in `ios/Resources/PrivacyInfo.xcprivacy` documenting:
- Camera API usage
- Photo library API usage
- Microphone API usage
- File system access patterns

### Build Configuration
No additional build settings required. The plugin automatically:
- Configures required frameworks
- Sets up proper Swift version compatibility
- Handles iOS version availability checks

## Performance Characteristics

### Image Processing
- **Memory Usage**: ~2-3x image size during processing (Core Graphics optimization)
- **Processing Time**: <500ms for typical photos on modern devices
- **Quality**: Lossless operations until final compression
- **Thread Safety**: Main thread operations for UI, background for processing

### Video Processing
- **Memory Usage**: Moderate (AVFoundation manages video memory efficiently)
- **Processing Time**: 1-5s per minute of video (device dependent)
- **Export Quality**: Maintains high quality with configurable compression
- **Hardware Acceleration**: Leverages iOS video encoding hardware

### Permission Handling
- **Response Time**: Immediate for cached permissions, 1-2s for new requests
- **User Experience**: Native iOS permission dialogs
- **Caching**: Proper permission state caching and monitoring

## Troubleshooting

### Common Issues

#### Permission Denied Errors
- Verify Info.plist entries are present and descriptive
- Check for proper permission request timing
- Ensure app is not calling APIs before permissions granted
- Use plugin's built-in permission check methods

#### Image Processing Failures
- Monitor memory usage on older devices
- Check image format compatibility
- Verify source file accessibility
- Handle Core Graphics memory warnings

#### Video Export Failures
- Check available device storage
- Monitor memory during composition operations
- Verify input video format compatibility
- Handle AVAssetExportSession error states

#### File Access Issues
- Ensure proper sandboxing compliance
- Check temporary directory permissions
- Verify file cleanup doesn't occur prematurely
- Handle security-scoped resource access properly

### Debug Information
Enable detailed logging by monitoring:
- Console output for plugin debug messages
- AVFoundation error domains
- Core Graphics warnings
- Memory pressure notifications

### Performance Monitoring
Monitor using Xcode Instruments:
- **Memory usage** during image/video processing
- **CPU utilization** during export operations
- **Energy impact** of camera and processing operations
- **Disk I/O** for file operations

## Architecture Notes

### Thread Management
- **Main Thread**: UI operations, permission dialogs, delegate callbacks
- **Background Queues**: File I/O, image processing, video export
- **Synchronization**: DispatchSemaphore for async-to-sync bridging
- **Memory Management**: ARC with proper cleanup patterns

### Error Handling
- **Graceful Degradation**: Fallbacks for failed operations
- **User Feedback**: Proper error messages via Flutter result callbacks
- **Recovery**: Automatic cleanup and state reset
- **Logging**: Comprehensive error logging for debugging

### iOS Version Compatibility
- **Modern APIs**: iOS 14+ features with availability checks
- **Legacy Support**: Fallbacks for iOS 12-13
- **Runtime Checks**: Dynamic feature availability detection
- **Graceful Degradation**: Feature reduction on older versions

## Testing Recommendations

### Unit Testing
- Permission state management logic
- Image processing operations
- File path resolution and cleanup
- Error handling scenarios

### Integration Testing
- Cross-iOS version compatibility (iOS 12-17+)
- Different device types and capabilities
- Various image/video formats and sizes
- Permission flow scenarios

### Performance Testing
- Memory usage profiling during processing
- Processing time benchmarks across devices
- Large file handling verification
- Concurrent operation handling

## Future Improvements

### Priority Enhancements
1. **Background Processing**: Support for background video processing
2. **Progressive Processing**: Chunked processing for large files
3. **Hardware Optimization**: Enhanced use of iOS hardware acceleration
4. **Cache Management**: Intelligent temporary file cleanup
5. **Streaming Support**: Live camera preview and processing
6. **PhotoKit Integration**: Enhanced photo library integration for metadata preservation
