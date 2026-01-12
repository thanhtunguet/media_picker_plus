---
sidebar_position: 3
---

# Getting Started

This guide will help you get started with Media Picker Plus in your Flutter app.

## Basic Usage

### Pick an Image

```dart
import 'package:media_picker_plus/media_picker_plus.dart';

// Pick an image from gallery
final result = await MediaPickerPlus.pickImage(
  source: MediaSource.gallery,
);

if (result != null) {
  print('Image path: ${result.path}');
  // Use the image path as needed
}
```

### Capture an Image

```dart
// Capture an image using camera
final result = await MediaPickerPlus.pickImage(
  source: MediaSource.camera,
);

if (result != null) {
  print('Captured image: ${result.path}');
}
```

### Pick a Video

```dart
// Pick a video from gallery
final result = await MediaPickerPlus.pickVideo(
  source: MediaSource.gallery,
);

if (result != null) {
  print('Video path: ${result.path}');
  print('Video duration: ${result.duration}');
}
```

### Pick Multiple Images

```dart
// Pick multiple images
final results = await MediaPickerPlus.pickImages(
  source: MediaSource.gallery,
  maxCount: 5, // Maximum number of images to pick
);

for (var result in results) {
  print('Image: ${result.path}');
}
```

## Advanced Features

### Image Cropping

```dart
final result = await MediaPickerPlus.pickImage(
  source: MediaSource.gallery,
  cropOptions: CropOptions(
    aspectRatio: CropAspectRatio.square, // 1:1 aspect ratio
    allowFreeform: false,
  ),
);
```

### Image Resizing

```dart
final result = await MediaPickerPlus.pickImage(
  source: MediaSource.gallery,
  maxWidth: 1920,
  maxHeight: 1080,
  quality: 85,
);
```

### Watermarking

```dart
final result = await MediaPickerPlus.pickImage(
  source: MediaSource.gallery,
  watermark: WatermarkOptions(
    text: 'My Watermark',
    position: WatermarkPosition.bottomRight,
    fontSize: 24,
  ),
);
```

## Next Steps

- Learn about [Platform-Specific Guides](/docs/platforms)
- Explore [API Reference](/docs/api-reference)
