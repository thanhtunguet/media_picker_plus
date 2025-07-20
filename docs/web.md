# Web Platform - Technical Documentation

## Overview
The Web implementation provides basic media picking and processing capabilities using browser APIs and JavaScript libraries. Currently at ~10% completion with fundamental functionality implemented but many features requiring full implementation or browser compatibility workarounds.

## Native Libraries Used

### Browser APIs
- **File API** - File selection and reading
  - Purpose: HTMLInputElement file picker, FileReader for processing
  - Status: ✅ Complete implementation

- **Canvas API** - Image processing and watermarking
  - Purpose: Image cropping, resizing, watermark overlay
  - Status: ✅ Basic implementation complete

- **MediaDevices API** - Camera access (planned)
  - Purpose: getUserMedia for camera capture
  - Status: ❌ Not implemented

### External JavaScript Libraries
- **FFmpeg.js** - Video processing (optional dependency)
  - Purpose: Video watermarking and transcoding
  - Status: ⚠️ Basic integration, requires manual setup
  - Size: ~20MB when loaded
  - Loading: Asynchronous, impacts initial performance

### Web Standards
- **URL.createObjectURL()** - Blob URL generation
- **dart:js_interop** - Dart-JavaScript interoperability
- **flutter_web_plugins** - Flutter web plugin system

## Implementation Status

### ✅ Fully Implemented Features (10% Complete)

#### File Selection
- **Gallery Picker**: Complete HTMLInputElement-based file selection
- **File Type Filtering**: MIME type filtering for images, videos, documents
- **Multiple Selection**: Support for selecting multiple files
- **Extension Filtering**: Custom file extension filtering

#### Basic Image Processing
- **Resizing**: Max width/height with aspect ratio preservation
- **Quality Control**: JPEG compression using Canvas API
- **Watermarking**: Text overlay with basic positioning (4 positions)
- **Cropping**: Manual rectangle and aspect ratio-based cropping
- **Format Support**: Canvas-based JPEG output

### 🔄 Partially Implemented Features

#### Camera Access (Simulation)
- **Capture Attribute**: Uses `capture="environment"` on file input
- **Browser Camera**: ⚠️ Basic file input with camera preference
- **Real Camera API**: ❌ No getUserMedia implementation
- **Live Preview**: ❌ No real-time camera preview

#### Video Processing
- **Video Selection**: ✅ Complete video file selection
- **Video Watermarking**: ⚠️ FFmpeg.js integration (requires setup)
- **Format Support**: ⚠️ Limited by browser codec support
- **Processing Quality**: ❌ No quality control options

### ❌ Missing Features (90% Incomplete)

#### Advanced Camera Features
- **Real Camera Access**: No getUserMedia implementation
- **Camera Selection**: No device enumeration
- **Camera Controls**: No focus, zoom, flash controls
- **Live Streaming**: No real-time preview capabilities

#### Advanced Image Processing
- **Batch Processing**: No multiple image processing optimization
- **Advanced Filters**: No color correction, effects, or filters
- **RAW Support**: Limited to standard web image formats
- **Performance Optimization**: No Web Workers for heavy processing

#### Advanced Video Processing
- **Video Editing**: No trimming, cutting, or advanced editing
- **Multiple Tracks**: No audio/video track management
- **Streaming Support**: No video streaming capabilities
- **Hardware Acceleration**: No WebGL or GPU acceleration

#### Browser Compatibility
- **Safari Support**: Limited codec and API support
- **Mobile Browser**: Inconsistent camera access
- **Progressive Enhancement**: No fallbacks for older browsers
- **Cross-Origin**: CORS limitations for file processing

## Developer Configuration Notes

### Basic Setup
Include in `web/index.html` for video watermarking support:

```html
<!-- FFmpeg.js for video processing (optional) -->
<script src="https://unpkg.com/@ffmpeg/ffmpeg@0.11.6/dist/ffmpeg.min.js"></script>
<script src="https://unpkg.com/@ffmpeg/core@0.11.0/dist/ffmpeg-core.js"></script>

<!-- Custom video watermarking function -->
<script src="ffmpeg_watermark.js"></script>
```

### File Size Considerations
- **FFmpeg.js**: ~20MB download impact
- **Core Bundle**: ~8MB additional for ffmpeg-core.js
- **Total Impact**: ~28MB for video processing capabilities
- **Loading Strategy**: Consider lazy loading for video features only

### Browser Support Requirements
```yaml
Minimum Browser Versions:
  Chrome: 76+ (File API, Canvas API)
  Firefox: 69+ (File API, Canvas API)
  Safari: 12+ (Limited support)
  Edge: 79+ (Chromium-based)

Camera Access Requirements:
  HTTPS: Required for getUserMedia
  Permissions: User gesture required
  Mobile Support: Variable across browsers
```

### CORS Configuration
For cross-origin file processing:

```yaml
# Example server configuration
Access-Control-Allow-Origin: "*"
Access-Control-Allow-Methods: "GET, POST, PUT, DELETE"
Access-Control-Allow-Headers: "Content-Type, Authorization"
```

### Performance Optimization
```html
<!-- Preload FFmpeg if video features are expected -->
<link rel="preload" href="ffmpeg.min.js" as="script">
<link rel="preload" href="ffmpeg-core.js" as="script">

<!-- Service Worker for caching (recommended) -->
<script>
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js');
}
</script>
```

## Performance Characteristics

### File Operations
- **File Selection**: Near-instant (native browser dialog)
- **File Reading**: Depends on file size and browser performance
- **Multiple Files**: Linear performance degradation with count

### Image Processing
- **Canvas Operations**: Good performance for typical web images
- **Memory Usage**: ~3-4x image size during processing
- **Processing Time**: 100-500ms for typical photos
- **Large Images**: Performance degrades significantly with size

### Video Processing
- **FFmpeg Loading**: 5-15 seconds initial load time
- **Processing Time**: 2-5x real-time (highly variable)
- **Memory Usage**: Very high (can cause tab crashes)
- **Browser Limitations**: Some browsers may timeout on large files

## Known Issues & Limitations

### Browser Compatibility Issues
- **Safari Limitations**: 
  - Limited codec support for video processing
  - iOS Safari camera access restrictions
  - Different Canvas API behavior

- **Mobile Browser Issues**:
  - Inconsistent camera access implementation
  - Memory limitations for large file processing
  - Touch interaction differences

### Performance Limitations
- **Single-threaded Processing**: No Web Workers implementation
- **Memory Constraints**: Large files can crash browser tabs
- **No Hardware Acceleration**: CPU-only processing
- **Network Dependency**: FFmpeg.js requires internet for initial load

### Security Restrictions
- **HTTPS Requirement**: Camera access requires secure context
- **CORS Limitations**: Cross-origin file access restrictions
- **File Size Limits**: Browser-imposed memory limitations
- **User Gesture Required**: Permissions require user interaction

### Feature Gaps
- **Real Camera Preview**: No live camera preview implementation
- **Advanced Video Editing**: Very limited video processing capabilities
- **Background Processing**: No support for background tasks
- **Progressive Upload**: No streaming or chunked upload support

## Troubleshooting

### Common Issues

#### FFmpeg.js Loading Failures
```javascript
// Check FFmpeg availability
if (!window.createFFmpeg) {
  console.error('FFmpeg.js not loaded. Check script tags.');
}

// Handle loading timeout
const loadTimeout = setTimeout(() => {
  console.error('FFmpeg loading timeout');
}, 30000);

ffmpeg.load().then(() => {
  clearTimeout(loadTimeout);
}).catch(error => {
  console.error('FFmpeg load failed:', error);
});
```

#### Camera Access Issues
```javascript
// Check HTTPS requirement
if (location.protocol !== 'https:' && location.hostname !== 'localhost') {
  console.warn('Camera access requires HTTPS');
}

// Feature detection
if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
  console.error('getUserMedia not supported');
}
```

#### File Processing Errors
```javascript
// Handle large file limitations
const MAX_FILE_SIZE = 100 * 1024 * 1024; // 100MB
if (file.size > MAX_FILE_SIZE) {
  console.error('File too large for browser processing');
}

// Memory monitoring
const memoryInfo = performance.memory;
if (memoryInfo && memoryInfo.usedJSHeapSize > memoryInfo.jsHeapSizeLimit * 0.8) {
  console.warn('High memory usage detected');
}
```

### Debug Information
Enable debug logging:

```dart
// In MediaPickerPlusWeb
void _log(String message) {
  if (kDebugMode) {
    print('[MediaPickerPlusWeb] $message');
  }
}
```

Monitor browser developer tools:
- **Console**: JavaScript errors and warnings
- **Network**: FFmpeg.js loading performance
- **Memory**: Memory usage during processing
- **Performance**: Processing time profiling

## Architecture Notes

### File Processing Strategy
- **Client-side Only**: All processing happens in browser
- **No Server Required**: No backend dependency for basic features
- **Blob URLs**: Temporary object URLs for processed files
- **Memory Management**: Manual cleanup of object URLs required

### Threading Model
- **Main Thread**: All operations currently on main thread
- **Future Enhancement**: Web Workers for heavy processing
- **Async Operations**: Promise-based API for non-blocking operations
- **Event-driven**: File input change events drive processing

### Error Handling Strategy
- **Graceful Degradation**: Fallback to original files on processing failure
- **User Feedback**: Console logging for debugging
- **Recovery**: Automatic cleanup on errors
- **Validation**: File type and size validation before processing

## Testing Recommendations

### Cross-browser Testing
- Test on Chrome, Firefox, Safari, Edge
- Mobile browser testing (iOS Safari, Chrome Mobile)
- Various OS combinations (Windows, macOS, Linux, iOS, Android)
- Different file sizes and types

### Performance Testing
- Large file handling (>50MB images, >100MB videos)
- Multiple file selection performance
- Memory usage monitoring
- Processing timeout scenarios

### Feature Testing
- File type filtering accuracy
- Image processing quality verification
- Video processing functionality (if FFmpeg.js enabled)
- Error handling and recovery

## Future Development Priorities

### Phase 1: Core Camera Implementation (High Priority)
1. **Real Camera Access**: Implement getUserMedia for actual camera capture
2. **Live Preview**: Camera preview with capture controls
3. **Device Selection**: Multiple camera support and switching
4. **Mobile Optimization**: Better mobile browser support

### Phase 2: Performance & Quality (Medium Priority)
1. **Web Workers**: Move heavy processing off main thread
2. **Progressive Loading**: Chunked processing for large files
3. **Hardware Acceleration**: WebGL/GPU acceleration where possible
4. **Streaming Support**: Real-time processing capabilities

### Phase 3: Advanced Features (Low Priority)
1. **Advanced Video Editing**: Trimming, effects, transitions
2. **Real-time Filters**: Live camera effects and filters
3. **Collaborative Features**: Multi-user processing capabilities
4. **PWA Support**: Offline processing and background sync

### Phase 4: Enterprise Features (Future)
1. **CDN Integration**: Optimized asset delivery
2. **Analytics**: Usage and performance monitoring
3. **Accessibility**: Screen reader and keyboard navigation support
4. **Internationalization**: Multi-language support

## Browser-Specific Notes

### Chrome/Chromium
- **Best Support**: Most features work reliably
- **Performance**: Good Canvas and File API performance
- **Limitations**: Memory usage can be high for large files

### Firefox
- **Good Support**: Most features functional
- **Performance**: Similar to Chrome for most operations
- **Limitations**: Some Canvas behavior differences

### Safari
- **Limited Support**: Reduced codec support
- **iOS Specific**: Camera access restrictions
- **Performance**: Slower Canvas operations
- **Limitations**: Video processing severely limited

### Edge (Legacy)
- **Not Supported**: Modern features require Chromium Edge
- **Migration**: Recommend upgrading to Chromium-based Edge
- **Fallbacks**: Basic file selection may work

## Security Considerations

### Content Security Policy
```html
<!-- Recommended CSP for video processing -->
<meta http-equiv="Content-Security-Policy" 
      content="script-src 'self' 'unsafe-eval' https://unpkg.com; 
               worker-src 'self' blob:; 
               connect-src 'self' https:;">
```

### Privacy Implications
- **Local Processing**: All processing happens client-side
- **No Server Upload**: Files don't leave user's device
- **Temporary URLs**: Object URLs are cleaned up automatically
- **Camera Permissions**: Require explicit user consent

### Data Handling
- **Memory Cleanup**: Properly dispose of large objects
- **URL Revocation**: Clean up blob URLs to prevent memory leaks
- **Error Information**: Avoid logging sensitive file information
- **User Consent**: Clear communication about camera/file access