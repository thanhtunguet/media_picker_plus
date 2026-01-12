---
sidebar_position: 1
---

# Introduction

**Media Picker Plus** is a comprehensive Flutter plugin for media selection with advanced processing capabilities. Pick images, videos, and files from gallery or camera with built-in watermarking, resizing, and quality control features.

## Who is this for?

This plugin is ideal for developers building:

- Social media apps (like Instagram, TikTok clones)
- Chat/messaging apps with media features
- Document scanners or photo editing apps
- Any app requiring rich media capture and processing

## Features

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

## Platform Support

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

\* Video watermarking on web requires optional FFmpeg.js setup  
\*\* Video compression not yet implemented for web platform

## Quick Start

### Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  media_picker_plus: ^1.1.0-rc.4
```

Or install via command line:

```bash
flutter pub add media_picker_plus
```

### Basic Usage

```dart
import 'package:media_picker_plus/media_picker_plus.dart';

// Pick an image
final result = await MediaPickerPlus.pickImage(
  source: MediaSource.gallery,
);

if (result != null) {
  // Use the picked image
  print('Image path: ${result.path}');
}
```

## Next Steps

- [Installation Guide](/docs/installation)
- [Getting Started](/docs/getting-started)
- [API Reference](/docs/api-reference)
- [Platform-Specific Guides](/docs/platforms)
