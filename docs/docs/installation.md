---
sidebar_position: 2
---

# Installation

## Requirements

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

## Install the Package

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  media_picker_plus: ^1.1.0-rc.4
```

Or install via command line:

```bash
flutter pub add media_picker_plus
```

Then run:

```bash
flutter pub get
```

## Platform-Specific Setup

### Android

No additional setup required. The plugin handles permissions automatically.

### iOS

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take photos and videos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to select images and videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone to record videos</string>
```

### macOS

Add the following to your `macos/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take photos and videos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to select images and videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone to record videos</string>
```

### Web

No additional setup required. The plugin uses browser APIs for media access.

## Verify Installation

Create a simple test to verify the installation:

```dart
import 'package:media_picker_plus/media_picker_plus.dart';

void main() async {
  // Test that the plugin is available
  final result = await MediaPickerPlus.pickImage(
    source: MediaSource.gallery,
  );
  print('Plugin installed successfully!');
}
```
