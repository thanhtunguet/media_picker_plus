# Media Picker Plus

[![pub package](https://img.shields.io/pub/v/media_picker_plus.svg)](https://pub.dev/packages/media_picker_plus)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20macos%20%7C%20web-lightgrey.svg)](https://github.com/thanhtunguet/media_picker_plus)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![codecov](https://codecov.io/gh/thanhtunguet/media_picker_plus/graph/badge.svg?token=NIIWTKBBS2)](https://codecov.io/gh/thanhtunguet/media_picker_plus)

A comprehensive Flutter plugin for media selection with advanced processing capabilities. Pick images, videos, and files from gallery or camera with built-in watermarking, resizing, and quality control features.

## 📚 Documentation

**For complete documentation, guides, and API reference, visit:**

👉 **[https://thanhtunguet.github.io/media_picker_plus](https://thanhtunguet.github.io/media_picker_plus)**

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
- **Video Utilities**:
  - Extract video thumbnails via `getThumbnail()`
  - Compress videos via `compressVideo()` with configurable quality/bitrate
- **Permission Management**: Smart permission handling for camera and gallery access
- **Cross-Platform**: Full support for Android, iOS, macOS, and Web
- **FFmpeg Integration**: Advanced video processing capabilities

## ✅ Platform Support

| Feature           | Android |  iOS  |  Web  | macOS |
| ----------------- | :-----: | :---: | :---: | :---: |
| Pick image        |    ✅    |   ✅   |   ✅   |   ✅   |
| Capture image     |    ✅    |   ✅   |   ✅   |   ✅   |
| Pick multiple images | ✅ | ✅ | ✅ | ✅ |
| Pick multiple videos | ✅ | ✅ | ✅ | ✅ |
| Crop image        |    ✅    |   ✅   |   ✅   |   ✅   |
| Resize image      |    ✅    |   ✅   |   ✅   |   ✅   |
| Watermark image   |    ✅    |   ✅   |   ✅   |   ✅   |
| Pick video        |    ✅    |   ✅   |   ✅   |   ✅   |
| Capture video     |    ✅    |   ✅   |   ✅   |   ✅   |
| Watermark video   |    ✅    |   ✅   |  ⚠️*   |   ✅   |
| Video thumbnail   |    ✅    |   ✅   |   ✅   |   ✅   |
| Video compression |    ✅    |   ✅   |  ❌**  |   ✅   |

\* Video watermarking on web requires optional FFmpeg.js setup  
\*\* Video compression not yet implemented for web platform

## 📋 Requirements

- **Flutter SDK**: `>= 2.5.0`
- **Dart SDK**: `>= 2.17.0 < 4.0.0`
- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 11.0+
- **macOS**: macOS 11.0+
- **Web**: Modern browsers with HTML5 support

## 🔧 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  media_picker_plus: ^1.1.0-rc.4
```

Or install via command line:

```bash
flutter pub add media_picker_plus
```

## ⚡ Quick Start

```dart
import 'package:media_picker_plus/media_picker_plus.dart';

// Pick an image from gallery
final result = await MediaPickerPlus.pickImage(
  source: MediaSource.gallery,
);

if (result != null) {
  print('Image path: ${result.path}');
}
```

For detailed usage examples, platform-specific setup, and API documentation, visit the [official documentation site](https://thanhtunguet.info/media_picker_plus).

## 📖 Usage Examples

### Pick Image

```dart
String? imagePath = await MediaPickerPlus.pickImage(
  source: MediaSource.gallery,
);
```

### Capture Photo

```dart
String? imagePath = await MediaPickerPlus.pickImage(
  source: MediaSource.camera,
);
```

### Preferred Camera Device (Android/iOS)

```dart
String? imagePath = await MediaPickerPlus.capturePhoto(
  options: MediaOptions(
    preferredCameraDevice: PreferredCameraDevice.front,
  ),
);
```

```dart
String? videoPath = await MediaPickerPlus.recordVideo(
  options: MediaOptions(
    preferredCameraDevice: PreferredCameraDevice.back,
  ),
);
```

> Note: `preferredCameraDevice` is a best-effort hint. On Android, some camera apps may ignore it; on web and macOS it is currently ignored.

### Pick Video

```dart
String? videoPath = await MediaPickerPlus.pickVideo(
  source: MediaSource.gallery,
);
```

### Pick Multiple Images / Videos

```dart
final imagePaths = await MediaPickerPlus.pickMultipleImages();
final videoPaths = await MediaPickerPlus.pickMultipleVideos();
```

This is supported on Android, iOS, Web, and macOS (gallery source).

### Extract Thumbnail From Video

```dart
final thumbnailPath = await MediaPickerPlus.getThumbnail(
  videoPath,
  timeInSeconds: 1.5,
  options: const MediaOptions(
    maxWidth: 720,
    maxHeight: 720,
    imageQuality: 85,
  ),
);
```

### Compress Video

```dart
final compressedPath = await MediaPickerPlus.compressVideo(
  videoPath,
  options: const VideoCompressionOptions(
    quality: VideoCompressionQuality.p720,
    deleteOriginalFile: false,
  ),
);
```

### Advanced Features

For examples of cropping, watermarking, video compression, and more advanced features, see the [documentation](https://thanhtunguet.info/media_picker_plus).

## 🔐 Privacy and Security

- All media processing happens locally on the device
- No data is transmitted to external servers
- Temporary files are automatically cleaned up
- Requests minimal necessary permissions

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
