---
sidebar_position: 5
---

# API Reference

Complete API reference for Media Picker Plus.

## MediaPickerPlus

The main class for picking and capturing media.

### Methods

#### pickImage

Picks or captures an image.

```dart
static Future<MediaResult?> pickImage({
  required MediaSource source,
  CropOptions? cropOptions,
  int? maxWidth,
  int? maxHeight,
  int? quality,
  WatermarkOptions? watermark,
})
```

**Parameters:**
- `source`: The source to pick from (`MediaSource.gallery` or `MediaSource.camera`)
- `cropOptions`: Optional cropping options
- `maxWidth`: Maximum width for resizing
- `maxHeight`: Maximum height for resizing
- `quality`: Image quality (0-100)
- `watermark`: Optional watermark options

**Returns:** `MediaResult?` containing the picked image path and metadata

#### pickVideo

Picks or captures a video.

```dart
static Future<MediaResult?> pickVideo({
  required MediaSource source,
  WatermarkOptions? watermark,
  VideoCompressionOptions? compressionOptions,
})
```

**Parameters:**
- `source`: The source to pick from (`MediaSource.gallery` or `MediaSource.camera`)
- `watermark`: Optional watermark options
- `compressionOptions`: Optional video compression options

**Returns:** `MediaResult?` containing the picked video path and metadata

#### pickImages

Picks multiple images.

```dart
static Future<List<MediaResult>> pickImages({
  required MediaSource source,
  int? maxCount,
  CropOptions? cropOptions,
  int? maxWidth,
  int? maxHeight,
  int? quality,
})
```

**Parameters:**
- `source`: The source to pick from
- `maxCount`: Maximum number of images to pick
- `cropOptions`: Optional cropping options
- `maxWidth`: Maximum width for resizing
- `maxHeight`: Maximum height for resizing
- `quality`: Image quality (0-100)

**Returns:** `List<MediaResult>` containing the picked images

## Enums

### MediaSource

```dart
enum MediaSource {
  gallery,
  camera,
}
```

### WatermarkPosition

```dart
enum WatermarkPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}
```

## Classes

### MediaResult

Represents a picked media file.

```dart
class MediaResult {
  final String path;
  final int? size;
  final Duration? duration;
  final int? width;
  final int? height;
}
```

### CropOptions

Options for image cropping.

```dart
class CropOptions {
  final CropAspectRatio? aspectRatio;
  final bool allowFreeform;
}
```

### WatermarkOptions

Options for adding watermarks.

```dart
class WatermarkOptions {
  final String text;
  final WatermarkPosition position;
  final int fontSize;
}
```
