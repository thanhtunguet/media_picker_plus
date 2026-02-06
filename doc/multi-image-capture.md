# Multi-Image Capture

## Overview

The multi-image capture feature provides two ways to pick multiple images:

1. **Camera multi-capture** — A hub screen that continuously loops the native camera for a batch capture experience.
2. **Gallery multi-pick** — The existing `pickMultipleImages()` with optional watermark processing.

Cropping is intentionally skipped for multi-image operations; only quality and watermark processing are applied.

## Camera Multi-Capture

### Usage

```dart
final paths = await MediaPickerPlus.captureMultiplePhotos(
  context: context,
  options: MediaOptions(
    imageQuality: 80,
    watermark: 'My Watermark',
    watermarkPosition: WatermarkPosition.bottomRight,
  ),
  multiImageOptions: MultiImageOptions(
    maxImages: 10,    // null = unlimited
    minImages: 1,     // minimum before "Done" is enabled
    confirmOnDiscard: true, // dialog on back with photos
  ),
);

if (paths != null) {
  // paths is List<String> of processed image file paths
  for (final path in paths) {
    print('Captured: $path');
  }
}
```

### Flow

1. `captureMultiplePhotos()` pushes a `MultiCaptureScreen` hub screen.
2. The hub immediately opens the native camera.
3. After each photo, the camera auto-reopens for continuous capture.
4. The user cancels the native camera (back button) to stay on the hub.
5. On the hub screen, the user can:
   - Review thumbnails in a grid
   - Tap a thumbnail for full-screen preview
   - Delete unwanted photos (X button)
   - Tap "Take More" to reopen the camera
   - Tap "Done" to confirm
6. On "Done", all images are processed (quality + watermark) and returned.

### Hub Screen

```
┌──────────────────────────────┐
│ [←] Photos (3)       [Done] │
├──────────────────────────────┤
│  ┌────┐  ┌────┐  ┌────┐    │
│  │img1│  │img2│  │img3│    │
│  │ [×]│  │ [×]│  │ [×]│    │
│  └────┘  └────┘  └────┘    │
│                              │
│              [📷 Take More]  │
└──────────────────────────────┘
```

## MultiImageOptions

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `maxImages` | `int?` | `null` | Maximum images allowed. `null` = unlimited. |
| `minImages` | `int` | `1` | Minimum images required before "Done" is enabled. |
| `confirmOnDiscard` | `bool` | `true` | Show confirmation dialog when discarding captured photos. |

## Processing

- **Quality**: Applied via `imageQuality`, `maxWidth`, `maxHeight` from `MediaOptions`.
- **Watermark**: Applied if `watermark` is set in `MediaOptions`.
- **Crop**: Ignored for multi-image operations. Use single-image `capturePhoto()` or `pickImage()` for cropping.

## Platform Support

No native code changes are needed. The feature works by looping the existing `pickMedia()` call with `MediaSource.camera`, which uses the native camera on each platform:

| Platform | Camera | Gallery Multi-Pick |
|----------|--------|--------------------|
| Android  | Native camera intent | Native gallery picker |
| iOS      | UIImagePickerController | PHPickerViewController |
| macOS    | Native camera preview | File dialog |
| Web      | getUserMedia API | File input |

## Cross-Platform Thumbnails

Thumbnails use conditional imports for platform compatibility:
- **IO (mobile/desktop)**: `Image.file()` with `cacheWidth: 200` for memory efficiency
- **Web**: `Image.network()` for data/blob URLs
