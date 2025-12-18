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

| Feature         | Android | iOS | Web | macOS |
|-----------------|:-------:|:---:|:---:|:-----:|
| Pick image      |    ✅    |  ✅  |  ✅  |   ✅   |
| Capture image   |    ✅    |  ✅  |  ✅  |   ✅   |
| Crop image      |    ✅    |  ✅  |  ✅  |   ✅   |
| Resize image    |    ✅    |  ✅  |  ✅  |   ✅   |
| Watermark image |    ✅    |  ✅  |  ✅  |   ✅   |
| Pick video      |    ✅    |  ✅  |  ✅  |   ✅   |
| Capture video   |    ✅    |  ✅  |  ✅  |   ✅   |
| Watermark video |    ❌    |  ✅  |  ✅  |   ✅   |

> Note: Video watermarking on Android is currently under development. Contributions are welcome!


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

## 🎯 Usage

### Basic Import

```dart
import 'package:media_picker_plus/media_picker_plus.dart';
```

### Image Operations

#### Pick Image from Gallery

```dart
final String? imagePath = await MediaPickerPlus.pickImage(
  context: context, // Optional: enables interactive cropping UI when freeform cropping
  options: const MediaOptions(
    imageQuality: 85,
    maxWidth: 1920,
    maxHeight: 1080,
    watermark: '© My App 2024',
    watermarkPosition: WatermarkPosition.bottomRight,
    watermarkFontSize: 24,
  ),
);

if (imagePath != null) {
  // Use the processed image
  File imageFile = File(imagePath);
}
```

#### Capture Photo

```dart
final String? photoPath = await MediaPickerPlus.capturePhoto(
  context: context, // Optional: enables interactive cropping UI when freeform cropping
  options: const MediaOptions(
    imageQuality: 90,
    maxWidth: 2560,
    maxHeight: 1440,
    watermark: 'Captured with My App',
    watermarkPosition: WatermarkPosition.bottomCenter,
  ),
);
```

#### Pick Multiple Images

```dart
final List<String>? imagePaths = await MediaPickerPlus.pickMultipleImages(
  options: const MediaOptions(
    imageQuality: 80,
    maxWidth: 1920,
    maxHeight: 1080,
    watermark: 'Batch Process',
    watermarkPosition: WatermarkPosition.topLeft,
  ),
);
```

### Video Operations

#### Pick Video from Gallery

```dart
final String? videoPath = await MediaPickerPlus.pickVideo(
  options: const MediaOptions(
    maxWidth: 1920,
    maxHeight: 1080,
    watermark: '🎥 My Video App',
    watermarkPosition: WatermarkPosition.topRight,
    watermarkFontSize: 28,
    maxDuration: Duration(minutes: 5),
  ),
);
```

#### Record Video

```dart
final String? recordedPath = await MediaPickerPlus.recordVideo(
  options: const MediaOptions(
    maxWidth: 1920,
    maxHeight: 1080,
    watermark: 'Live Recording',
    watermarkPosition: WatermarkPosition.middleCenter,
    maxDuration: Duration(minutes: 2),
  ),
);
```

### Cropping Operations

The plugin supports advanced cropping functionality for both images and videos with various aspect ratio presets and freeform cropping. When using freeform cropping with a `BuildContext`, an interactive cropping UI allows manual selection of the crop area.

#### Basic Cropping

```dart
// Square cropping (1:1)
final String? imagePath = await MediaPickerPlus.pickImage(
  options: const MediaOptions(
    cropOptions: CropOptions.square, // Predefined square crop
    imageQuality: 85,
    watermark: 'Cropped Image',
  ),
);
```

#### Aspect Ratio Cropping

```dart
// Portrait crop (3:4)
final String? portraitImage = await MediaPickerPlus.pickImage(
  options: const MediaOptions(
    cropOptions: CropOptions.portrait,
    imageQuality: 90,
  ),
);

// Landscape crop (4:3)
final String? landscapeImage = await MediaPickerPlus.pickImage(
  options: const MediaOptions(
    cropOptions: CropOptions.landscape,
    imageQuality: 90,
  ),
);

// Widescreen crop (16:9)
final String? widescreenVideo = await MediaPickerPlus.pickVideo(
  options: const MediaOptions(
    cropOptions: CropOptions.widescreen,
    watermark: 'Widescreen Video',
  ),
);
```

#### Custom Aspect Ratio

```dart
// Custom aspect ratio (e.g., 5:4)
final String? customCropImage = await MediaPickerPlus.pickImage(
  options: const MediaOptions(
    cropOptions: CropOptions(
      enableCrop: true,
      aspectRatio: 5.0 / 4.0,
      lockAspectRatio: true,
      showGrid: true,
    ),
  ),
);
```

#### Freeform Cropping with Interactive UI

```dart
// Freeform cropping with interactive UI (requires BuildContext)
final String? freeformImage = await MediaPickerPlus.pickImage(
  context: context, // Required for interactive cropping UI
  options: const MediaOptions(
    cropOptions: CropOptions(
      enableCrop: true,
      freeform: true,
      showGrid: true,
      lockAspectRatio: false,
    ),
  ),
);
```

**Note:** When `freeform: true` is used with a `BuildContext`, an interactive cropping UI will appear allowing users to manually adjust the crop area with:
- Draggable corner handles for resizing
- Touch-to-move the entire crop area
- Real-time aspect ratio controls
- Visual grid overlay for better alignment
- Zoom and pan support for precise cropping

#### Specific Crop Rectangle

```dart
// Crop specific area (normalized coordinates 0.0 - 1.0)
final String? specificCropImage = await MediaPickerPlus.pickImage(
  options: const MediaOptions(
    cropOptions: CropOptions(
      enableCrop: true,
      cropRect: CropRect(
        x: 0.1,      // 10% from left
        y: 0.1,      // 10% from top
        width: 0.8,  // 80% of original width
        height: 0.8, // 80% of original height
      ),
    ),
  ),
);
```

#### Video Cropping

```dart
// Crop recorded video to square format
final String? croppedVideo = await MediaPickerPlus.recordVideo(
  options: const MediaOptions(
    cropOptions: CropOptions.square,
    maxDuration: Duration(minutes: 1),
    watermark: 'Square Video',
    watermarkPosition: WatermarkPosition.topLeft,
  ),
);
```

## 🎛️ Interactive Cropping UI

When using freeform cropping with a `BuildContext`, the plugin displays a full-screen interactive cropping interface with the following features:

### Features
- **Manual Selection**: Drag corner handles to resize the crop area
- **Move Crop Area**: Touch and drag to move the entire crop area
- **Aspect Ratio Controls**: Quick buttons for common ratios (1:1, 4:3, 3:4, 16:9)
- **Visual Grid Overlay**: Rule of thirds grid for better composition
- **Zoom & Pan**: InteractiveViewer for precise crop selection
- **Real-time Preview**: See crop dimensions and percentage coverage
- **Responsive Design**: Adapts to different screen sizes and orientations

### Usage
```dart
// Interactive cropping requires a BuildContext
final String? croppedImage = await MediaPickerPlus.pickImage(
  context: context, // This enables the interactive UI
  options: const MediaOptions(
    cropOptions: CropOptions(
      enableCrop: true,
      freeform: true, // This triggers the interactive UI
      showGrid: true,
      lockAspectRatio: false,
    ),
  ),
);
```

### UI Components
- **App Bar**: Cancel/confirm buttons with reset option
- **Crop Controls**: Aspect ratio selection chips
- **Crop Area**: Interactive image with overlay and handles
- **Bottom Actions**: Cancel and confirm buttons for easy access

The interactive UI is displayed as a full-screen modal that guides users through the cropping process with intuitive touch controls and visual feedback.

**Testing/Advanced:** `CropUI` also supports injecting a pre-decoded `ui.Image` via `initialImage` (skips loading from `imagePath`).

### File Operations

#### Pick Single File

```dart
final String? filePath = await MediaPickerPlus.pickFile(
  allowedExtensions: ['.pdf', '.doc', '.docx', '.txt'],
);
```

#### Pick Multiple Files

```dart
final List<String>? filePaths = await MediaPickerPlus.pickMultipleFiles(
  allowedExtensions: ['.pdf', '.doc', '.docx', '.txt', '.csv', '.xlsx'],
);
```

### Permission Management

```dart
// Check permissions
bool hasCameraPermission = await MediaPickerPlus.hasCameraPermission();
bool hasGalleryPermission = await MediaPickerPlus.hasGalleryPermission();

// Request permissions
if (!hasCameraPermission) {
  hasCameraPermission = await MediaPickerPlus.requestCameraPermission();
}

if (!hasGalleryPermission) {
  hasGalleryPermission = await MediaPickerPlus.requestGalleryPermission();
}
```

## 🛠️ MediaOptions Configuration

The `MediaOptions` class provides comprehensive control over media processing:

```dart
const MediaOptions({
  int imageQuality = 80,           // Image quality (0-100)
  int? maxWidth = 1280,            // Maximum width in pixels
  int? maxHeight = 1280,           // Maximum height in pixels
  String? watermark,               // Watermark text
  double? watermarkFontSize = 30,  // Watermark font size
  String? watermarkPosition = WatermarkPosition.bottomRight,
  Duration? maxDuration = const Duration(seconds: 60), // Max video duration
  CropOptions? cropOptions,        // Cropping configuration
})
```

### CropOptions Configuration

```dart
const CropOptions({
  bool enableCrop = false,         // Enable/disable cropping
  double? aspectRatio,             // Target aspect ratio (width/height)
  bool freeform = true,            // Allow freeform cropping
  bool showGrid = true,            // Show crop grid overlay
  bool lockAspectRatio = false,    // Lock aspect ratio during cropping
  CropRect? cropRect,              // Specific crop rectangle
})
```

### CropRect Configuration

```dart
const CropRect({
  required double x,               // X position (0.0 - 1.0, normalized)
  required double y,               // Y position (0.0 - 1.0, normalized)
  required double width,           // Width (0.0 - 1.0, normalized)
  required double height,          // Height (0.0 - 1.0, normalized)
})
```

### Predefined Crop Presets

```dart
// Available preset configurations
CropOptions.square      // 1:1 aspect ratio
CropOptions.portrait    // 3:4 aspect ratio
CropOptions.landscape   // 4:3 aspect ratio
CropOptions.widescreen  // 16:9 aspect ratio
```

### Watermark Positions

```dart
class WatermarkPosition {
  static const String topLeft = 'topLeft';
  static const String topCenter = 'topCenter';
  static const String topRight = 'topRight';
  static const String middleLeft = 'middleLeft';
  static const String middleCenter = 'middleCenter';
  static const String middleRight = 'middleRight';
  static const String bottomLeft = 'bottomLeft';
  static const String bottomCenter = 'bottomCenter';
  static const String bottomRight = 'bottomRight';
}
```

## 🔍 Advanced Usage

### Error Handling

```dart
try {
  final String? imagePath = await MediaPickerPlus.pickImage();
  if (imagePath != null) {
    // Process the image
  } else {
    // User cancelled the operation
  }
} catch (e) {
  // Handle errors (permission denied, etc.)
  print('Error: $e');
}
```

### Conditional Feature Usage

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  // Web-specific implementation
} else if (Platform.isAndroid) {
  // Android-specific implementation
} else if (Platform.isIOS) {
  // iOS-specific implementation
} else if (Platform.isMacOS) {
  // macOS-specific implementation
}
```

## 🎨 Example App

Check out the comprehensive example app included in the `example/` directory:

```bash
cd example
flutter run
```

The example demonstrates:
- All media picking operations
- Advanced cropping with multiple presets
- Interactive cropping UI for freeform selection
- Advanced watermarking features
- Multiple selection capabilities
- File picking with filtering
- Permission management
- Cross-platform compatibility

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
