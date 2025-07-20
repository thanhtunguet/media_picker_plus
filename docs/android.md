# Android Platform - Technical Documentation

## Overview
The Android implementation provides comprehensive media picking, camera capture, and processing capabilities with modern Android API support from API 23 (Android 6.0) to API 34+ (Android 14+).

## Native Libraries Used

### Core Dependencies
- **FFmpegKit** - Advanced video processing and watermarking
  - Version: Latest stable
  - Purpose: Video watermark overlay, transcoding, cropping
  - Status: ✅ Fully implemented and tested

### Android Framework APIs
- **MediaStore** - System media access and modern Photo Picker
- **Camera2 API** - Camera capture functionality
- **Canvas/Bitmap** - Image processing and watermarking
- **FileProvider** - Secure file sharing between apps
- **MediaMetadataRetriever** - Video metadata extraction

## Implementation Status

### ✅ Fully Implemented Features (95% Complete)

#### Media Picking
- **Gallery Access**: Complete with modern Photo Picker API (Android 13+) fallback
- **Camera Capture**: Full image and video capture with proper file management
- **Permission Management**: Granular permissions for Android 13+ with fallbacks
- **File Selection**: Document picker with MIME type filtering

#### Image Processing
- **Resizing**: Max width/height with aspect ratio preservation
- **Quality Control**: JPEG compression (75-90% quality levels)
- **Watermarking**: Text overlay with 9 positioning options
- **Cropping**: Interactive manual cropping with aspect ratio control
- **Format Support**: JPEG, PNG, WebP, GIF

#### Video Processing
- **Watermarking**: Advanced FFmpeg-based overlay system
- **Resizing**: Maintains aspect ratio during scaling
- **Cropping**: Rectangle and aspect ratio-based cropping
- **Format Support**: MP4, MOV, AVI, MKV

#### Permission System
- **Android 13+ (API 33+)**: Granular media permissions (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`)
- **Android 6-12 (API 23-32)**: Standard `READ_EXTERNAL_STORAGE`
- **Legacy Support**: Install-time permissions for older versions
- **Runtime Requests**: Proper permission request flows

### 🔄 Temporary Workarounds

#### Video Watermarking Architecture
**Current Implementation**: Using FFmpeg for video processing
- **Reason**: Android's native MediaComposer doesn't provide robust text overlay
- **Performance**: Good but requires FFmpeg dependency
- **Quality**: Excellent results with configurable compression
- **Future**: Consider MediaComposer alternatives for lighter dependency

#### File Path Resolution
**Current Implementation**: Content URI copying for Android 10+
- **Reason**: Scoped storage restrictions prevent direct file access
- **Performance**: Additional I/O overhead for large files
- **Compatibility**: Ensures consistent behavior across API levels
- **Alternative**: Direct URI processing where possible

### ⚠️ Known Limitations

#### Storage Management
- **Temporary Files**: Created in app-specific external directory
- **Cleanup**: Manual cleanup required for processed files
- **Large Files**: Memory pressure on devices with limited RAM
- **Best Practice**: Implement file cleanup in host applications

#### Video Processing Performance
- **FFmpeg Dependency**: Adds ~15-20MB to APK size
- **Processing Time**: Varies significantly based on video length and resolution
- **Memory Usage**: High memory consumption for large videos
- **Optimization**: Consider background processing for large files

## Developer Configuration Notes

### Required Permissions
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Camera permissions -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Storage permissions (Android 12 and below) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Granular media permissions (Android 13+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

<!-- Feature declarations -->
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

### FileProvider Configuration
The plugin automatically configures FileProvider. Ensure no conflicts in your `AndroidManifest.xml`:

```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

### ProGuard/R8 Configuration
Add to `android/app/proguard-rules.pro`:

```proguard
# FFmpegKit
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class org.ffmpeg.** { *; }

# Media Picker Plus
-keep class info.thanhtunguet.media_picker_plus.** { *; }
```

### Build Configuration
Minimum requirements in `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 23
        targetSdkVersion 34
    }
}
```

## Performance Characteristics

### Image Processing
- **Memory Usage**: ~3x image size during processing
- **Processing Time**: <1s for typical mobile photos
- **Quality**: Excellent with configurable compression

### Video Processing
- **Memory Usage**: High (consider background processing)
- **Processing Time**: 2-10s per minute of video
- **Output Quality**: Maintains original quality with configurable compression

## Troubleshooting

### Common Issues

#### Permission Denied Errors
- Verify manifest permissions are correctly declared
- Check runtime permission grants for Android 6+
- Use plugin's built-in permission methods

#### File Not Found Errors
- Ensure proper FileProvider configuration
- Check external storage availability
- Verify file cleanup isn't premature

#### Video Processing Failures
- Check available device storage
- Monitor memory usage during processing
- Implement timeout handling for long operations

#### FFmpeg Issues
- Verify FFmpegKit dependency is properly included
- Check device architecture compatibility
- Monitor logcat for FFmpeg-specific errors

### Debug Logging
Enable detailed logging by filtering for "MediaPickerPlus" tag:

```bash
adb logcat | grep MediaPickerPlus
```

## Testing Recommendations

### Unit Testing
- Permission state management
- File path resolution logic
- Option parsing and validation

### Integration Testing
- Cross-API level compatibility (API 23-34+)
- Different device manufacturers
- Various storage configurations
- Large file handling

### Performance Testing
- Memory usage profiling
- Processing time benchmarks
- APK size impact analysis

## Future Improvements

### Priority Enhancements
1. **Background Processing**: Implement WorkManager for large video processing
2. **Memory Optimization**: Stream-based processing for large files
3. **Native Video Processing**: Explore MediaComposer alternatives
4. **File Management**: Automatic cleanup and cache management