# Media Picker Plus Plugin Setup Guide

## Installation

### 1. Adding the plugin to your project

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  media_picker_plus: 
    path: ../path_to_plugin # For local development
    # OR
    # git: https://github.com/yourusername/media_picker_plus.git
```

### 2. Android Setup

1. Ensure you have the required permissions in your app's `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

2. Configure FileProvider in your app's `AndroidManifest.xml`:

```xml
<application ...>
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

3. Create a `file_paths.xml` file in `android/app/src/main/res/xml/`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-files-path name="my_images" path="Pictures" />
</paths>
```

### 3. iOS Setup

1. Add the following keys to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app requires access to the camera to take photos and videos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app requires access to the photo library to select images and videos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app requires access to the microphone to record videos.</string>
```

2. Set the minimum iOS version to 11.0 in your `Podfile`:

```ruby
platform :ios, '11.0'
```

## Usage

Import the plugin in your Dart code:

```dart
import 'package:media_picker_plus/media_picker_plus.dart';
```

### Basic Usage Examples

#### Pick an Image from Gallery

```dart
final MediaOptions options = MediaOptions(
  imageQuality: 80,
  width: 720,
  height: 1280,
);

final String? imagePath = await MediaPickerPlus.pickImage(options: options);
if (imagePath != null) {
  // Use the image path
}
```

#### Capture a Photo

```dart
final MediaOptions options = MediaOptions(
  imageQuality: 90,
  width: 1080,
  height: 1920,
);

final String? photoPath = await MediaPickerPlus.capturePhoto(options: options);
if (photoPath != null) {
  // Use the photo path
}
```

#### Pick a Video from Gallery

```dart
final String? videoPath = await MediaPickerPlus.pickVideo();
if (videoPath != null) {
  // Use the video path
}
```

#### Record a Video

```dart
final MediaOptions options = MediaOptions(
  videoBitrate: 8000000, // 8 Mbps
);

final String? recordedVideoPath = await MediaPickerPlus.recordVideo(options: options);
if (recordedVideoPath != null) {
  // Use the recorded video path
}
```

### Handling Permissions

Always check for permissions before accessing camera or gallery:

```dart
// Check camera permission
bool hasCameraAccess = await MediaPickerPlus.hasCameraPermission();
if (!hasCameraAccess) {
  hasCameraAccess = await MediaPickerPlus.requestCameraPermission();
  if (!hasCameraAccess) {
    // Handle permission denied
    return;
  }
}

// Now you can use camera features
```

```dart
// Check gallery permission
bool hasGalleryAccess = await MediaPickerPlus.hasGalleryPermission();
if (!hasGalleryAccess) {
  hasGalleryAccess = await MediaPickerPlus.requestGalleryPermission();
  if (!hasGalleryAccess) {
    // Handle permission denied
    return;
  }
}

// Now you can use gallery features
```