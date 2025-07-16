# Media Picker Plus - API Usage Guide

A comprehensive Flutter plugin for picking, capturing, and processing media files across all platforms.

## 🚀 Features

- **Media Picking**: Pick images and videos from gallery
- **Camera Capture**: Capture photos and record videos
- **Advanced Watermarking**: Add text watermarks to images and videos
- **File Picking**: Pick documents and files with extension filtering
- **Multiple Selection**: Select multiple media files at once
- **Cross-Platform**: Android, iOS, macOS, and Web support
- **Permission Management**: Handle camera and gallery permissions
- **Image Processing**: Resize images and control quality

## 📋 Table of Contents

1. [Installation](#installation)
2. [Basic Usage](#basic-usage)
3. [Advanced Features](#advanced-features)
4. [API Reference](#api-reference)
5. [Platform Support](#platform-support)
6. [Examples](#examples)

## 🔧 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  media_picker_plus: ^1.0.0
```

Import in your Dart code:

```dart
import 'package:media_picker_plus/media_picker_plus.dart';
```

## 🎯 Basic Usage

### Pick Image from Gallery

```dart
Future<void> pickImage() async {
  try {
    final path = await MediaPickerPlus.pickImage();
    if (path != null) {
      // Use the image path
      print('Image picked: $path');
    }
  } catch (e) {
    print('Error picking image: $e');
  }
}
```

### Capture Photo with Camera

```dart
Future<void> capturePhoto() async {
  try {
    final path = await MediaPickerPlus.capturePhoto();
    if (path != null) {
      // Use the captured photo path
      print('Photo captured: $path');
    }
  } catch (e) {
    print('Error capturing photo: $e');
  }
}
```

### Pick Video from Gallery

```dart
Future<void> pickVideo() async {
  try {
    final path = await MediaPickerPlus.pickVideo();
    if (path != null) {
      // Use the video path
      print('Video picked: $path');
    }
  } catch (e) {
    print('Error picking video: $e');
  }
}
```

### Record Video with Camera

```dart
Future<void> recordVideo() async {
  try {
    final path = await MediaPickerPlus.recordVideo();
    if (path != null) {
      // Use the recorded video path
      print('Video recorded: $path');
    }
  } catch (e) {
    print('Error recording video: $e');
  }
}
```

## 🎨 Advanced Features

### Image with Watermark and Quality Control

```dart
Future<void> pickImageWithWatermark() async {
  try {
    final path = await MediaPickerPlus.pickImage(
      options: const MediaOptions(
        imageQuality: 85,          // 0-100, higher = better quality
        maxWidth: 1920,            // Maximum width in pixels
        maxHeight: 1080,           // Maximum height in pixels
        watermark: '© MyApp 2025', // Watermark text
        watermarkFontSize: 32,     // Font size for watermark
        watermarkPosition: WatermarkPosition.bottomRight,
      ),
    );
    if (path != null) {
      print('Image with watermark: $path');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Video with Watermark and Duration Limit

```dart
Future<void> recordVideoWithWatermark() async {
  try {
    final path = await MediaPickerPlus.recordVideo(
      options: const MediaOptions(
        watermark: '🎬 MyApp',
        watermarkFontSize: 28,
        watermarkPosition: WatermarkPosition.topLeft,
        maxDuration: Duration(minutes: 5), // Max recording duration
      ),
    );
    if (path != null) {
      print('Video with watermark: $path');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Multiple Media Selection

```dart
Future<void> pickMultipleImages() async {
  try {
    final paths = await MediaPickerPlus.pickMultipleImages(
      options: const MediaOptions(
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
        watermark: '📸 Gallery',
        watermarkPosition: WatermarkPosition.bottomCenter,
      ),
    );
    if (paths != null && paths.isNotEmpty) {
      print('Picked ${paths.length} images');
      for (final path in paths) {
        print('Image: $path');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> pickMultipleVideos() async {
  try {
    final paths = await MediaPickerPlus.pickMultipleVideos(
      options: const MediaOptions(
        watermark: '🎥 Video Collection',
        watermarkPosition: WatermarkPosition.middleCenter,
      ),
    );
    if (paths != null && paths.isNotEmpty) {
      print('Picked ${paths.length} videos');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### File Picking with Extension Filtering

```dart
Future<void> pickDocument() async {
  try {
    final path = await MediaPickerPlus.pickFile(
      allowedExtensions: ['.pdf', '.doc', '.docx', '.txt'],
    );
    if (path != null) {
      print('Document picked: $path');
    }
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> pickMultipleFiles() async {
  try {
    final paths = await MediaPickerPlus.pickMultipleFiles(
      allowedExtensions: ['.pdf', '.doc', '.docx', '.txt', '.csv', '.xlsx'],
    );
    if (paths != null && paths.isNotEmpty) {
      print('Picked ${paths.length} files');
      for (final path in paths) {
        print('File: $path');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Permission Management

```dart
Future<void> checkPermissions() async {
  // Check current permission status
  final cameraPermission = await MediaPickerPlus.hasCameraPermission();
  final galleryPermission = await MediaPickerPlus.hasGalleryPermission();
  
  print('Camera permission: $cameraPermission');
  print('Gallery permission: $galleryPermission');
  
  // Request permissions if needed
  if (!cameraPermission) {
    final granted = await MediaPickerPlus.requestCameraPermission();
    print('Camera permission granted: $granted');
  }
  
  if (!galleryPermission) {
    final granted = await MediaPickerPlus.requestGalleryPermission();
    print('Gallery permission granted: $granted');
  }
}
```

## 📚 API Reference

### MediaPickerPlus Class

#### Single Media Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `pickImage({MediaOptions? options})` | Pick an image from gallery | `Future<String?>` |
| `pickVideo({MediaOptions? options})` | Pick a video from gallery | `Future<String?>` |
| `capturePhoto({MediaOptions? options})` | Capture a photo with camera | `Future<String?>` |
| `recordVideo({MediaOptions? options})` | Record a video with camera | `Future<String?>` |

#### Multiple Media Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `pickMultipleImages({MediaOptions? options})` | Pick multiple images | `Future<List<String>?>` |
| `pickMultipleVideos({MediaOptions? options})` | Pick multiple videos | `Future<List<String>?>` |

#### File Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `pickFile({MediaOptions? options, List<String>? allowedExtensions})` | Pick a single file | `Future<String?>` |
| `pickMultipleFiles({MediaOptions? options, List<String>? allowedExtensions})` | Pick multiple files | `Future<List<String>?>` |

#### Permission Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `hasCameraPermission()` | Check camera permission | `Future<bool>` |
| `hasGalleryPermission()` | Check gallery permission | `Future<bool>` |
| `requestCameraPermission()` | Request camera permission | `Future<bool>` |
| `requestGalleryPermission()` | Request gallery permission | `Future<bool>` |

### MediaOptions Class

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `imageQuality` | `int` | `80` | Image quality (0-100) |
| `maxWidth` | `int?` | `1280` | Maximum image width |
| `maxHeight` | `int?` | `1280` | Maximum image height |
| `watermark` | `String?` | `null` | Watermark text |
| `watermarkFontSize` | `double?` | `30` | Watermark font size |
| `watermarkPosition` | `String?` | `bottomRight` | Watermark position |
| `maxDuration` | `Duration?` | `60 seconds` | Maximum video duration |

### WatermarkPosition Constants

| Constant | Description |
|----------|-------------|
| `topLeft` | Top-left corner |
| `topCenter` | Top-center |
| `topRight` | Top-right corner |
| `middleLeft` | Middle-left |
| `middleCenter` | Center |
| `middleRight` | Middle-right |
| `bottomLeft` | Bottom-left corner |
| `bottomCenter` | Bottom-center |
| `bottomRight` | Bottom-right corner |

## 🌍 Platform Support

### Android
- ✅ Full support with advanced features
- ✅ Camera capture and gallery picking
- ✅ Image and video watermarking
- ✅ Permission handling (including Android 13+)
- ✅ File picking with extension filtering
- ✅ Multiple selection support

### iOS
- ✅ Full support with advanced features
- ✅ Camera capture and gallery picking
- ✅ Image and video watermarking
- ✅ Permission handling
- ✅ File picking with extension filtering
- ✅ Multiple selection support

### macOS
- ✅ Full support with advanced features
- ✅ File dialogs for media and file picking
- ✅ Camera access and recording
- ✅ Image and video watermarking
- ✅ Permission handling
- ✅ Multiple selection support

### Web
- ✅ Full support with HTML5 APIs
- ✅ File input for media and file picking
- ✅ Camera access via getUserMedia
- ✅ Client-side image processing
- ✅ Canvas-based watermarking
- ✅ Multiple selection support

## 🎨 Advanced Examples

### Custom Watermark Styling

```dart
Future<void> advancedWatermark() async {
  final path = await MediaPickerPlus.pickImage(
    options: const MediaOptions(
      watermark: '🎯 Advanced Watermark',
      watermarkFontSize: 36,
      watermarkPosition: WatermarkPosition.middleCenter,
      imageQuality: 95,
      maxWidth: 2048,
      maxHeight: 2048,
    ),
  );
}
```

### Video Recording with Constraints

```dart
Future<void> constrainedVideoRecording() async {
  final path = await MediaPickerPlus.recordVideo(
    options: const MediaOptions(
      watermark: '🎬 Professional Video',
      watermarkFontSize: 24,
      watermarkPosition: WatermarkPosition.topRight,
      maxDuration: Duration(minutes: 10),
    ),
  );
}
```

### Batch File Processing

```dart
Future<void> batchFileProcessing() async {
  final paths = await MediaPickerPlus.pickMultipleImages(
    options: const MediaOptions(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
      watermark: '📸 Batch ${DateTime.now().year}',
      watermarkPosition: WatermarkPosition.bottomLeft,
    ),
  );
  
  if (paths != null) {
    print('Processing ${paths.length} images...');
    for (int i = 0; i < paths.length; i++) {
      print('Processing image ${i + 1}: ${paths[i]}');
      // Process each image
    }
  }
}
```

### Error Handling Pattern

```dart
Future<String?> safeMediaPicking() async {
  try {
    // Check permissions first
    final hasPermission = await MediaPickerPlus.hasGalleryPermission();
    if (!hasPermission) {
      final granted = await MediaPickerPlus.requestGalleryPermission();
      if (!granted) {
        throw Exception('Gallery permission denied');
      }
    }
    
    // Pick media with error handling
    final path = await MediaPickerPlus.pickImage(
      options: const MediaOptions(
        imageQuality: 80,
        watermark: '📱 Safe Picking',
      ),
    );
    
    if (path == null) {
      throw Exception('No image selected');
    }
    
    return path;
  } catch (e) {
    print('Error in safe media picking: $e');
    return null;
  }
}
```

## 🔧 Platform-Specific Configuration

### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture photos and videos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to pick images and videos</string>
```

### macOS
Add to `macos/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture photos and videos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to pick images and videos</string>
```

## 🎯 Best Practices

1. **Always handle errors**: Wrap media picker calls in try-catch blocks
2. **Check permissions**: Verify permissions before accessing camera/gallery
3. **Optimize for performance**: Use appropriate image quality and size limits
4. **User feedback**: Show loading indicators during media processing
5. **Test across platforms**: Ensure consistent behavior on all target platforms
6. **Memory management**: Dispose of resources properly, especially on mobile

## 🤝 Contributing

This plugin is open source and welcomes contributions. Please check the repository for contribution guidelines.

## 📄 License

This plugin is released under the MIT License. See the LICENSE file for details.