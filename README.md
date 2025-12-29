# Media Picker Plus

[![pub package](https://img.shields.io/pub/v/media_picker_plus.svg)](https://pub.dev/packages/media_picker_plus)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20macos%20%7C%20web-lightgrey.svg)](https://github.com/thanhtunguet/media_picker_plus)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![codecov](https://codecov.io/gh/thanhtunguet/media_picker_plus/graph/badge.svg?token=NIIWTKBBS2)](https://codecov.io/gh/thanhtunguet/media_picker_plus)


A comprehensive Flutter plugin for media selection with advanced processing capabilities. Pick images, videos, and files from gallery or camera with built-in watermarking, resizing, and quality control features.


## 💡 Who is this for?

This plugin is ideal for developers building:

- Social media apps (like Instagram, TikTok clones)
- Chat/messaging apps with media features
- Document scanners or photo editing apps
- Any app requiring rich media capture and processing

## 🚀 Features

- **Media Selection**: Pick images and videos from gallery or capture using camera
- **File Picking**: Select files with extension filtering
- **Multiple Selection**: Pick multiple images, videos, or files at once
- **Advanced Processing**: 
  - Image resizing with aspect ratio preservation
  - Media cropping with aspect ratio control and freeform options
  - Interactive cropping UI for manual crop selection
  - Quality control for images and videos
  - Watermarking with customizable position and font size
- **Permission Management**: Smart permission handling for camera and gallery access
- **Cross-Platform**: Full support for Android, iOS, macOS, and Web
- **FFmpeg Integration**: Advanced video processing capabilities

## ✅ Platform Support

> **⚠️ Web Developers:** If you're targeting web, please read the [Web Platform Considerations](#️-important-web-platform-considerations) section in the Usage guide to avoid common runtime errors with `Platform` APIs, `Image.file()`, and `VideoPlayerController.file()`.

| Feature         | Android | iOS | Web | macOS |
|-----------------|:-------:|:---:|:---:|:-----:|
| Pick image      |    ✅    |  ✅  |  ✅  |   ✅   |
| Capture image   |    ✅    |  ✅  |  ✅  |   ✅   |
| Crop image      |    ✅    |  ✅  |  ✅  |   ✅   |
| Resize image    |    ✅    |  ✅  |  ✅  |   ✅   |
| Watermark image |    ✅    |  ✅  |  ✅  |   ✅   |
| Pick video      |    ✅    |  ✅  |  ✅  |   ✅   |
| Capture video   |    ✅    |  ✅  |  ✅  |   ✅   |
| Watermark video |    ✅    |  ✅  |  ⚠️*  |   ✅   |
| Video thumbnail |    ✅    |  ✅  |  ✅  |   ✅   |
| Video compression |    ✅    |  ✅  |  ❌**  |   ✅   |

* Video watermarking on web requires optional FFmpeg.js setup. See [docs/web-permissions.md](docs/web-permissions.md) for details.
** Video compression not yet implemented for web platform.



## 📋 Requirements

### Flutter Environment
- **Flutter SDK**: `>= 2.5.0`
- **Dart SDK**: `>= 2.17.0 < 4.0.0`

### Platform Requirements

#### Android
- **Supported Versions**: Android 5.1 - Android 14+ (API 22 - API 34+)
- **Minimum SDK**: API 21 (Android 5.0)
- **Compile SDK**: API 34+ (recommended)
- **Target SDK**: API 34+ (recommended)

#### iOS
- **Supported Versions**: iOS 11.0 - iOS 17+
- **Minimum Version**: iOS 11.0
- **Xcode**: 12.0+

#### macOS
- **Supported Versions**: macOS 11.0 - macOS 14+
- **Minimum Version**: macOS 11.0
- **Xcode**: 12.0+

#### Web
- **Requirements**: Modern browsers with HTML5 support
- **Features**: WebRTC for camera, File API for uploads
- **Browser Support**: Chrome 63+, Firefox 65+, Safari 11.1+, Edge 79+

## 🔧 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  media_picker_plus: ^0.0.1
```

Or install via command line:

```bash
flutter pub add media_picker_plus
```

## ⚙️ Platform Setup

### Android Configuration

1. **Add permissions to `android/app/src/main/AndroidManifest.xml`**:

The plugin requires different permissions based on the features you use and the Android API levels you support:

```xml
<!-- Required for camera capture -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Required for video recording -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Storage permissions for Android 6.0 - 12 (API 23-32) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />

<!-- Granular media permissions for Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />

<!-- Optional: Feature declarations for better Play Store filtering -->
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
<uses-feature android:name="android.hardware.microphone" android:required="false" />
```

**Permission Usage Guidelines:**
- Only add permissions for features you actually use
- `CAMERA` permission is required for photo/video capture
- `RECORD_AUDIO` permission is required for video recording with audio
- Storage permissions are required for gallery access
- For Android 13+ (API 33+), use granular media permissions instead of `READ_EXTERNAL_STORAGE`

2. **Configure FileProvider in `android/app/src/main/AndroidManifest.xml`**:

```xml
<application>
    <provider
        android:name="androidx.core.content.FileProvider"
        android:authorities="${applicationId}.fileprovider"
        android:exported="false"
        android:grantUriPermissions="true">
        <meta-data
            android:name="android.support.FILE_PROVIDER_PATHS"
            android:resource="@xml/file_paths" />
    </provider>
</application>
```

3. **Create `android/app/src/main/res/xml/file_paths.xml`**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-files-path name="my_images" path="Pictures" />
</paths>
```

**Detailed API Level Compatibility:**

| Android Version | API Level | Permission Model         | Required Permissions                                                                  |
|-----------------|-----------|--------------------------|---------------------------------------------------------------------------------------|
| Android 5.0-5.1 | 21-22     | Install-time             | All permissions granted at install                                                    |
| Android 6.0-8.1 | 23-27     | Runtime                  | `READ_EXTERNAL_STORAGE`, `CAMERA`, `RECORD_AUDIO`                                     |
| Android 9       | 28        | Runtime                  | `READ_EXTERNAL_STORAGE`, `CAMERA`, `RECORD_AUDIO`                                     |
| Android 10      | 29        | Runtime + Scoped Storage | `READ_EXTERNAL_STORAGE`, `CAMERA`, `RECORD_AUDIO`                                     |
| Android 11      | 30        | Runtime + Scoped Storage | `READ_EXTERNAL_STORAGE`, `CAMERA`, `RECORD_AUDIO`                                     |
| Android 12      | 31-32     | Runtime + Scoped Storage | `READ_EXTERNAL_STORAGE`, `CAMERA`, `RECORD_AUDIO`                                     |
| Android 13+     | 33+       | Runtime + Granular Media | `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`, `CAMERA`, `RECORD_AUDIO` |

**Key Changes by Version:**
- **API 23+**: Runtime permissions introduced
- **API 29+**: Scoped storage, app-specific directories preferred
- **API 33+**: Granular media permissions, modern Photo Picker API
- **API 34+**: Enhanced Photo Picker features

**Feature Availability:**
- **Modern Photo Picker**: Android 13+ (API 33+) - automatically used when available
- **Legacy Gallery Picker**: All versions - fallback for older Android versions
- **Camera Capture**: All versions
- **Video Recording**: All versions
- **File Picking**: All versions

### iOS Configuration

**Supported iOS Versions: 11.0 - 17+**

1. **Add permissions to `ios/Runner/Info.plist`**:

```xml
<!-- Required for camera capture (all iOS versions) -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos and videos.</string>

<!-- Required for photo library access (all iOS versions) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images and videos.</string>

<!-- Required for video recording with audio (all iOS versions) -->
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record videos with audio.</string>

<!-- Optional: Required for adding photos to library (if you implement save functionality) -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs permission to save photos to your photo library.</string>
```

2. **Set minimum iOS version in `ios/Podfile`**:

```ruby
platform :ios, '11.0'
```

3. **Configure deployment target in `ios/Runner.xcodeproj`**:
   - Open `ios/Runner.xcodeproj` in Xcode
   - Select "Runner" target
   - Set "iOS Deployment Target" to "11.0" or higher

**iOS Version Compatibility:**

| iOS Version   | Features Available                                     | Notes                          |
|---------------|--------------------------------------------------------|--------------------------------|
| iOS 11.0-12.x | Basic camera, photo library access                     | Core functionality             |
| iOS 13.0+     | Enhanced camera features, improved permission handling | Better user experience         |
| iOS 14.0+     | Limited photo library access, improved privacy         | PHPickerViewController support |
| iOS 15.0+     | Enhanced photo picker, camera improvements             | Optimized performance          |
| iOS 16.0+     | Camera improvements, better privacy controls           | Latest features                |
| iOS 17.0+     | Advanced camera features, enhanced privacy             | Cutting-edge support           |

**Permission Behavior by iOS Version:**
- **iOS 11.0-13.x**: Traditional permission model
- **iOS 14.0+**: Limited photo library access by default
- **iOS 14.0+**: PHPickerViewController available (automatically used when beneficial)
- **iOS 15.0+**: Enhanced privacy controls
- **iOS 16.0+**: Improved camera authorization states

### macOS Configuration

**Supported macOS Versions: 11.0 - 14+**

1. **Add permissions to `macos/Runner/Info.plist`**:

```xml
<!-- Required for camera capture (all macOS versions) -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos and videos.</string>

<!-- Required for microphone access during video recording (all macOS versions) -->
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record videos with audio.</string>

<!-- Required for photo library access (macOS 11.0+) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images and videos.</string>

<!-- Optional: Required for file system access beyond user-selected files -->
<key>NSDesktopFolderUsageDescription</key>
<string>This app needs access to the Desktop folder to save media files.</string>
<key>NSDocumentsFolderUsageDescription</key>
<string>This app needs access to the Documents folder to save media files.</string>
<key>NSDownloadsFolderUsageDescription</key>
<string>This app needs access to the Downloads folder to save media files.</string>
```

2. **Set minimum macOS version in `macos/Podfile`**:

```ruby
platform :osx, '11.0'
```

3. **Configure deployment target in `macos/Runner.xcodeproj`**:
   - Open `macos/Runner.xcodeproj` in Xcode
   - Select "Runner" target
   - Set "macOS Deployment Target" to "11.0" or higher

4. **Enable necessary capabilities in `macos/Runner/Runner.entitlements`**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Required for camera access -->
    <key>com.apple.security.device.camera</key>
    <true/>
    
    <!-- Required for microphone access -->
    <key>com.apple.security.device.microphone</key>
    <true/>
    
    <!-- Required for file system access -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Optional: Required for broader file system access -->
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
</dict>
</plist>
```

**macOS Version Compatibility:**

| macOS Version       | Features Available                            | Notes                     |
|---------------------|-----------------------------------------------|---------------------------|
| macOS 11.0 Big Sur  | Core functionality, basic permissions         | Minimum supported version |
| macOS 12.0 Monterey | Enhanced camera support, improved file access | Better performance        |
| macOS 13.0 Ventura  | Advanced camera features, refined permissions | Enhanced user experience  |
| macOS 14.0 Sonoma   | Continuity Camera support, latest features    | Cutting-edge support      |

**Permission Behavior by macOS Version:**
- **macOS 11.0+**: Modern permission system, app sandboxing
- **macOS 12.0+**: Enhanced camera and microphone permission handling
- **macOS 13.0+**: Improved file system access controls
- **macOS 14.0+**: Continuity Camera support, enhanced privacy controls

**File Access Methods:**
- **User-Selected Files**: No special permissions required (NSOpenPanel)
- **App-Specific Directories**: Automatic access to app sandbox directories
- **System Directories**: Requires explicit entitlements and user permission
- **Photo Library**: Requires NSPhotoLibraryUsageDescription for programmatic access

### Web Configuration

**Supported Browsers and Versions:**

| Browser     | Minimum Version | Camera Support | File API Support | Notes             |
|-------------|-----------------|----------------|------------------|-------------------|
| **Chrome**  | 63+             | ✅ Full         | ✅ Full           | Best performance  |
| **Firefox** | 65+             | ✅ Full         | ✅ Full           | Excellent support |
| **Safari**  | 11.1+           | ✅ Full         | ✅ Full           | iOS Safari 11.1+  |
| **Edge**    | 79+             | ✅ Full         | ✅ Full           | Chromium-based    |
| **Opera**   | 50+             | ✅ Full         | ✅ Full           | Good support      |

**No additional configuration required for basic functionality.**

**Optional Configuration for Enhanced Features:**

1. **Enable HTTPS for camera access** (required for camera in production):
   - Camera access requires HTTPS in production
   - Use `flutter run --web-port 8080 --web-hostname localhost` for local testing

2. **Configure Content Security Policy (CSP)** if using strict CSP:

```html
<!-- Add to web/index.html <head> section -->
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               media-src 'self' blob:; 
               img-src 'self' data: blob:; 
               script-src 'self' 'unsafe-inline';">
```

3. **Web App Manifest** for PWA features (optional):

```json
{
  "name": "Media Picker Plus App",
  "short_name": "MediaPicker",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#000000",
  "permissions": [
    "camera",
    "microphone"
  ]
}
```

**Browser Feature Support:**

| Feature            | Chrome | Firefox | Safari | Edge | Notes                        |
|--------------------|--------|---------|--------|------|------------------------------|
| Camera Capture     | ✅      | ✅       | ✅      | ✅    | Requires HTTPS in production |
| Video Recording    | ✅      | ✅       | ✅      | ✅    | MediaRecorder API            |
| File Upload        | ✅      | ✅       | ✅      | ✅    | HTML5 File API               |
| Multiple Selection | ✅      | ✅       | ✅      | ✅    | Native browser support       |
| Image Processing   | ✅      | ✅       | ✅      | ✅    | Canvas API                   |
| Watermarking       | ✅      | ✅       | ✅      | ✅    | Client-side processing       |
| Cropping           | ✅      | ✅       | ✅      | ✅    | Canvas-based                 |

**Web Limitations:**
- File system access is limited to user-selected files
- Camera access requires user interaction
- Some advanced video processing features may be limited
- Performance depends on browser and device capabilities

**Development vs Production:**
- **Development**: HTTP localhost allowed for camera access
- **Production**: HTTPS required for camera and microphone access
- **Mobile browsers**: May have different permission behaviors

## 📖 Usage

### Import the package

```dart
import 'package:media_picker_plus/media_picker_plus.dart';
```

### ⚠️ Important: Web Platform Considerations

**If your app targets web, read this section carefully to avoid runtime errors.**

#### The Problem

On web, many Flutter APIs that work on mobile/desktop will throw errors:
- ❌ `Platform.isAndroid`, `Platform.isIOS` → "Unsupported operation: Platform._operatingSystem"
- ❌ `Image.file()` → "Image.file is not supported on Flutter Web"
- ❌ `VideoPlayerController.file()` → Runtime error
- ❌ `Permission.photos`, `Permission.camera` from `permission_handler` → Not supported

#### The Solution

**Always check `kIsWeb` BEFORE using platform-specific code:**

```dart
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb

// ✅ CORRECT: Check kIsWeb first
if (kIsWeb) {
  // Use web-specific code
} else if (Platform.isAndroid) {
  // Use Android-specific code
}

// ❌ WRONG: Will crash on web
if (Platform.isAndroid) {  // This line crashes on web!
  // ...
}
```

#### Displaying Images (Web vs Native)

On web, `media_picker_plus` returns **data URLs** or **blob URLs**. You must use `Image.network()`:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

Widget _buildImage(String path, BoxFit fit) {
  if (kIsWeb || path.startsWith('data:') || path.startsWith('blob:')) {
    // Web: Use Image.network for URLs
    return Image.network(path, fit: fit);
  } else {
    // Native: Use Image.file for file paths
    return Image.file(File(path), fit: fit);
  }
}

// Usage:
String? imagePath = await MediaPickerPlus.pickImage();
if (imagePath != null) {
  _buildImage(imagePath, BoxFit.contain);
}
```

#### Playing Videos (Web vs Native)

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

void _setVideo(String path) {
  _videoController?.dispose();
  
  if (kIsWeb || path.startsWith('data:') || path.startsWith('blob:')) {
    // Web: Use network controller for URLs
    _videoController = VideoPlayerController.networkUrl(Uri.parse(path));
  } else {
    // Native: Use file controller for file paths
    _videoController = VideoPlayerController.file(File(path));
  }
  
  _videoController!.initialize().then((_) {
    setState(() {
      _videoController!.play();
    });
  });
}
```

#### Permission Handling (Web vs Native)

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> _requestPermissions() async {
  // Skip permission requests on web and desktop
  // Web: Browser handles permissions automatically
  // Desktop: Configured via Info.plist/manifest
  if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return;
  }

  // Only request on mobile (Android/iOS)
  await [
    Permission.camera,
    Permission.microphone,
    Permission.photos,
    Permission.storage,
  ].request();
}
```

#### Key Takeaways for Web

1. **Always check `kIsWeb` first** before using `Platform` APIs
2. **Use `Image.network()`** for images on web (data URLs)
3. **Use `VideoPlayerController.networkUrl()`** for videos on web
4. **Skip permission requests** on web - browser handles them automatically
5. **Video watermarks are optional** on web (requires FFmpeg.js setup)

**See full web platform guide:** [`docs/web-permissions.md`](docs/web-permissions.md)

### Permission Handling

Before using any media picking functionality, it's recommended to check and request permissions:

```dart
// Check camera permission
bool hasCameraPermission = await MediaPickerPlus.hasCameraPermission();
if (!hasCameraPermission) {
  bool granted = await MediaPickerPlus.requestCameraPermission();
  if (!granted) {
    // Handle permission denied
    return;
  }
}

// Check gallery permission
bool hasGalleryPermission = await MediaPickerPlus.hasGalleryPermission();
if (!hasGalleryPermission) {
  bool granted = await MediaPickerPlus.requestGalleryPermission();
  if (!granted) {
    // Handle permission denied
    return;
  }
}
```

### Basic Image Picking

#### Pick Image from Gallery

```dart
// Simple image picking
String? imagePath = await MediaPickerPlus.pickImage();

// With custom options
String? imagePath = await MediaPickerPlus.pickImage(
  options: const MediaOptions(
    imageQuality: 90,
    maxWidth: 1920,
    maxHeight: 1080,
  ),
);
```

#### Capture Photo with Camera

```dart
// Simple photo capture
String? imagePath = await MediaPickerPlus.capturePhoto();

// With custom options
String? imagePath = await MediaPickerPlus.capturePhoto(
  options: const MediaOptions(
    imageQuality: 85,
    maxWidth: 1600,
    maxHeight: 1200,
  ),
);
```

### Basic Video Handling

#### Pick Video from Gallery

```dart
// Simple video picking
String? videoPath = await MediaPickerPlus.pickVideo();

// With duration limit
String? videoPath = await MediaPickerPlus.pickVideo(
  options: const MediaOptions(
    maxDuration: Duration(minutes: 5),
  ),
);
```

#### Record Video with Camera

```dart
// Simple video recording
String? videoPath = await MediaPickerPlus.recordVideo();

// With custom options
String? videoPath = await MediaPickerPlus.recordVideo(
  options: const MediaOptions(
    maxDuration: Duration(minutes: 2),
  ),
);
```

### Multiple Media Selection

#### Pick Multiple Images

```dart
List<String>? imagePaths = await MediaPickerPlus.pickMultipleImages();

// With custom options
List<String>? imagePaths = await MediaPickerPlus.pickMultipleImages(
  options: const MediaOptions(
    imageQuality: 80,
    maxWidth: 1280,
    maxHeight: 1280,
  ),
);
```

#### Pick Multiple Videos

```dart
List<String>? videoPaths = await MediaPickerPlus.pickMultipleVideos();

// With duration limits
List<String>? videoPaths = await MediaPickerPlus.pickMultipleVideos(
  options: const MediaOptions(
    maxDuration: Duration(minutes: 3),
  ),
);
```

### File Picking

#### Pick Single File

```dart
// Pick any file
String? filePath = await MediaPickerPlus.pickFile();

// Pick specific file types
String? pdfPath = await MediaPickerPlus.pickFile(
  allowedExtensions: ['pdf', 'doc', 'docx'],
);
```

#### Pick Multiple Files

```dart
// Pick multiple files
List<String>? filePaths = await MediaPickerPlus.pickMultipleFiles();

// Pick multiple files with specific extensions
List<String>? imagePaths = await MediaPickerPlus.pickMultipleFiles(
  allowedExtensions: ['jpg', 'png', 'gif', 'bmp'],
);
```

### Advanced Image Cropping

#### Interactive Cropping

For interactive cropping with a built-in UI, provide a `BuildContext`:

```dart
// Enable interactive cropping with square aspect ratio
String? croppedImage = await MediaPickerPlus.pickImage(
  context: context,
  options: MediaOptions(
    cropOptions: CropOptions.square, // 1:1 aspect ratio
  ),
);

// Enable interactive cropping with custom aspect ratio
String? croppedImage = await MediaPickerPlus.capturePhoto(
  context: context,
  options: const MediaOptions(
    cropOptions: CropOptions(
      enableCrop: true,
      aspectRatio: 16.0 / 9.0, // Widescreen
      lockAspectRatio: true,
      showGrid: true,
    ),
  ),
);

// Freeform cropping (no aspect ratio constraints)
String? croppedImage = await MediaPickerPlus.pickImage(
  context: context,
  options: const MediaOptions(
    cropOptions: CropOptions(
      enableCrop: true,
      freeform: true,
      showGrid: true,
    ),
  ),
);
```

#### Pre-defined Crop Ratios

```dart
// Square crop (1:1)
String? squareImage = await MediaPickerPlus.pickImage(
  context: context,
  options: const MediaOptions(cropOptions: CropOptions.square),
);

// Portrait crop (3:4)
String? portraitImage = await MediaPickerPlus.pickImage(
  context: context,
  options: const MediaOptions(cropOptions: CropOptions.portrait),
);

// Landscape crop (4:3)
String? landscapeImage = await MediaPickerPlus.pickImage(
  context: context,
  options: const MediaOptions(cropOptions: CropOptions.landscape),
);

// Widescreen crop (16:9)
String? widescreenImage = await MediaPickerPlus.pickImage(
  context: context,
  options: const MediaOptions(cropOptions: CropOptions.widescreen),
);
```

#### Programmatic Cropping

```dart
// Define crop area manually (values are normalized 0.0-1.0)
String? croppedImage = await MediaPickerPlus.pickImage(
  options: const MediaOptions(
    cropOptions: CropOptions(
      enableCrop: true,
      cropRect: CropRect(
        x: 0.1,      // 10% from left
        y: 0.1,      // 10% from top
        width: 0.8,  // 80% of image width
        height: 0.8, // 80% of image height
      ),
    ),
  ),
);
```

### Watermarking

#### Image Watermarking

```dart
// Add watermark during image picking
String? watermarkedImage = await MediaPickerPlus.pickImage(
  options: const MediaOptions(
    watermark: "© 2024 MyApp",
    watermarkPosition: WatermarkPosition.bottomRight,
    watermarkFontSizePercentage: 5.0, // 5% of shorter edge
  ),
);

// Add watermark to existing image
String? watermarkedImage = await MediaPickerPlus.addWatermarkToImage(
  existingImagePath,
  options: const MediaOptions(
    watermark: "© 2024 MyApp",
    watermarkPosition: WatermarkPosition.bottomLeft,
    watermarkFontSize: 24.0, // Fixed font size
  ),
);
```

#### Video Watermarking

```dart
// Add watermark during video recording
String? watermarkedVideo = await MediaPickerPlus.recordVideo(
  options: const MediaOptions(
    watermark: "© 2024 MyApp",
    watermarkPosition: WatermarkPosition.topRight,
    watermarkFontSizePercentage: 3.0,
  ),
);

// Add watermark to existing video
String? watermarkedVideo = await MediaPickerPlus.addWatermarkToVideo(
  existingVideoPath,
  options: const MediaOptions(
    watermark: "© 2024 MyApp",
    watermarkPosition: WatermarkPosition.bottomCenter,
    watermarkFontSizePercentage: 4.0,
  ),
);
```

### Video Thumbnail Extraction

Extract thumbnail images from video files at specified times:

```dart
// Extract thumbnail at 1 second (default)
String? thumbnailPath = await MediaPickerPlus.getThumbnail(videoPath);

// Extract thumbnail at specific time
String? thumbnailPath = await MediaPickerPlus.getThumbnail(
  videoPath,
  timeInSeconds: 5.0, // Extract at 5 seconds
);

// Extract with processing options
String? thumbnailPath = await MediaPickerPlus.getThumbnail(
  videoPath,
  timeInSeconds: 2.5,
  options: const MediaOptions(
    maxWidth: 300,
    maxHeight: 300,
    imageQuality: 85,
    watermark: "Thumbnail",
    watermarkPosition: WatermarkPosition.bottomRight,
  ),
);
```

### Video Compression

Compress videos to reduce file size with customizable quality settings and output parameters:

#### Basic Video Compression

```dart
// Simple compression with default settings
String? compressedVideo = await MediaPickerPlus.compressVideo('path/to/input/video.mp4');

// Compress with custom output path
String? compressedVideo = await MediaPickerPlus.compressVideo(
  'path/to/input/video.mp4',
  outputPath: 'path/to/output/compressed_video.mp4',
);
```

#### Quality Presets

```dart
// Use predefined quality presets
String? compressedVideo = await MediaPickerPlus.compressVideo(
  inputVideoPath,
  options: const VideoCompressionOptions(
    quality: VideoCompressionQuality.p720, // Default preset (720p HD)
  ),
);

// Available quality presets:
// - VideoCompressionQuality.p360 (360p, 400kbps) - Mobile/basic quality
// - VideoCompressionQuality.p480 (480p, 800kbps) - Standard definition
// - VideoCompressionQuality.p640 (640p, 1.2Mbps) - Quarter HD
// - VideoCompressionQuality.p720 (720p, 2Mbps) - High definition (default)
// - VideoCompressionQuality.p1080 (1080p, 4Mbps) - Full HD
// - VideoCompressionQuality.p1280 (1280p, 6Mbps) - HD Plus
// - VideoCompressionQuality.p1440 (1440p, 8Mbps) - Quad HD
// - VideoCompressionQuality.p1920 (1920p, 12Mbps) - High resolution
// - VideoCompressionQuality.k2 (2K, 10Mbps) - Cinema standard
// - VideoCompressionQuality.original (No compression) - Preserve original
```

#### Custom Compression Settings

```dart
// Custom resolution and bitrate
String? compressedVideo = await MediaPickerPlus.compressVideo(
  inputVideoPath,
  options: const VideoCompressionOptions(
    customWidth: 1280,
    customHeight: 720,
    customBitrate: 2000000, // 2 Mbps
    outputFormat: 'mp4',
    deleteOriginalFile: false,
  ),
);
```

#### Advanced Compression Options

```dart
// Full configuration example
String? compressedVideo = await MediaPickerPlus.compressVideo(
  inputVideoPath,
  outputPath: 'custom/output/path.mp4',
  options: VideoCompressionOptions(
    quality: VideoCompressionQuality.p1080,
    customBitrate: 2500000, // Override quality preset bitrate
    customWidth: 1920,      // Override quality preset width
    customHeight: 1080,     // Override quality preset height
    outputFormat: 'mp4',
    deleteOriginalFile: true, // Delete input file after compression
    onProgress: (progress) {
      print('Compression progress: ${(progress * 100).toStringAsFixed(1)}%');
    },
  ),
);
```

#### Platform Support

- **iOS**: Uses AVFoundation's AVAssetExportSession with high-quality compression
- **Android**: Uses MediaMetadataRetriever and MediaCodec for efficient compression  
- **macOS**: Same implementation as iOS with AVFoundation
- **Web**: Not yet implemented

#### Compression Examples

```dart
// Compress for social media (Instagram/TikTok style)
String? socialVideo = await MediaPickerPlus.compressVideo(
  inputPath,
  options: const VideoCompressionOptions(
    customWidth: 1080,
    customHeight: 1920, // Vertical format
    customBitrate: 3000000,
    outputFormat: 'mp4',
  ),
);

// Compress for messaging apps (smaller file size)
String? messageVideo = await MediaPickerPlus.compressVideo(
  inputPath,
  options: const VideoCompressionOptions(
    quality: VideoCompressionQuality.p480, // Standard definition
    deleteOriginalFile: true,
  ),
);

// High quality for professional use
String? professionalVideo = await MediaPickerPlus.compressVideo(
  inputPath,
  options: const VideoCompressionOptions(
    quality: VideoCompressionQuality.p1440, // Quad HD
    customBitrate: 10000000, // 10 Mbps for high quality
  ),
);
```

#### Watermark Positions

```dart
// Available watermark positions
WatermarkPosition.topLeft
WatermarkPosition.topCenter
WatermarkPosition.topRight
WatermarkPosition.middleLeft
WatermarkPosition.middleCenter
WatermarkPosition.middleRight
WatermarkPosition.bottomLeft
WatermarkPosition.bottomCenter
WatermarkPosition.bottomRight
```

### Complete MediaOptions Configuration

```dart
const MediaOptions(
  // Image quality (0-100, higher = better quality)
  imageQuality: 90,
  
  // Maximum dimensions (pixels)
  maxWidth: 1920,
  maxHeight: 1080,
  
  // Video duration limit
  maxDuration: Duration(minutes: 5),
  
  // Watermark settings
  watermark: "© 2024 MyApp",
  watermarkPosition: WatermarkPosition.bottomRight,
  
  // Font size options (use one or the other)
  watermarkFontSize: 24.0, // Fixed pixel size
  watermarkFontSizePercentage: 4.0, // Percentage of shorter edge
  
  // Cropping options
  cropOptions: CropOptions(
    enableCrop: true,
    aspectRatio: 16.0 / 9.0,
    lockAspectRatio: true,
    freeform: false,
    showGrid: true,
    cropRect: CropRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
  ),
)
```

### Error Handling

```dart
try {
  String? imagePath = await MediaPickerPlus.pickImage();
  if (imagePath != null) {
    // Process the selected image
    print('Image selected: $imagePath');
  } else {
    // User cancelled the picker
    print('No image selected');
  }
} catch (e) {
  // Handle errors (permission denied, camera not available, etc.)
  print('Error picking image: $e');
}
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';

class MediaPickerExample extends StatefulWidget {
  @override
  _MediaPickerExampleState createState() => _MediaPickerExampleState();
}

class _MediaPickerExampleState extends State<MediaPickerExample> {
  String? _selectedImagePath;

  Future<void> _pickImageWithCropping() async {
    try {
      // Check permissions first
      bool hasPermission = await MediaPickerPlus.hasGalleryPermission();
      if (!hasPermission) {
        bool granted = await MediaPickerPlus.requestGalleryPermission();
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gallery permission denied')),
          );
          return;
        }
      }

      // Pick image with interactive cropping and watermark
      String? imagePath = await MediaPickerPlus.pickImage(
        context: context,
        options: const MediaOptions(
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1080,
          watermark: "© 2024 MyApp",
          watermarkPosition: WatermarkPosition.bottomRight,
          watermarkFontSizePercentage: 4.0,
          cropOptions: CropOptions(
            enableCrop: true,
            freeform: true,
            showGrid: true,
          ),
        ),
      );

      if (imagePath != null) {
        setState(() {
          _selectedImagePath = imagePath;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Media Picker Plus Example'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickImageWithCropping,
            child: Text('Pick & Crop Image'),
          ),
          if (_selectedImagePath != null)
            Expanded(
              child: Image.file(File(_selectedImagePath!)),
            ),
        ],
      ),
    );
  }
}
```

### Tips and Best Practices

1. **Always check permissions** before using camera or gallery features
2. **Use appropriate image quality** settings to balance file size and quality
3. **Set reasonable maximum dimensions** to prevent memory issues
4. **Provide user feedback** during media processing operations
5. **Handle null returns** gracefully (user cancellation)
6. **Use percentage-based watermark font sizes** for consistent appearance across different media sizes
7. **Test interactive cropping UI** on different screen sizes and orientations

## 🔐 Privacy and Security

### Data Handling
- All media processing happens locally on the device
- No data is transmitted to external servers
- Temporary files are automatically cleaned up
- Watermarking is applied offline

### Permissions
- Requests minimal necessary permissions
- Graceful handling of permission denials
- Clear usage descriptions for all permissions

## 🐛 Troubleshooting

### Common Issues

**Android Build Issues**:
- Ensure `minSdkVersion` is at least 21
- Check FileProvider configuration
- Verify permissions in AndroidManifest.xml

**iOS Build Issues**:
- Ensure iOS deployment target is 11.0+
- Check Info.plist permission descriptions
- Verify Podfile configuration

**Permission Issues**:
- Always check permissions before using features
- Handle permission denials gracefully
- Provide clear user feedback

### Performance Optimization

- Use appropriate image quality settings
- Set reasonable max dimensions
- Consider file size for watermarking
- Implement progress indicators for long operations

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 🌟 Support

If you find this plugin helpful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs
- 💡 Suggesting new features
- 📝 Contributing to documentation

For support, please open an issue on [GitHub](https://github.com/thanhtunguet/media_picker_plus/issues).

---

**Made with ❤️ by thanhtunguet**
