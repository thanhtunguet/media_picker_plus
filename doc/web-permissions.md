# Web Permission Handling Analysis

## Summary

The example project currently attempts to use `Permission.photos`, `Permission.storage`, `Permission.camera`, and `Permission.microphone` from the `permission_handler` package on web platforms. However, **these permissions are not supported on web** by the `permission_handler` package and will cause runtime errors or be silently ignored.

## Problem

In `example/lib/main.dart` (lines 45-50), the code requests permissions that don't exist on web:

```dart
await [
  Permission.camera,        // ❌ Not supported on web
  Permission.microphone,    // ❌ Not supported on web
  Permission.photos,        // ❌ Not supported on web (doesn't exist)
  Permission.storage,       // ❌ Not supported on web
].request();
```

### Why This Doesn't Work on Web

1. **`Permission.photos`** - This permission enum does not exist in `permission_handler` for web
2. **`Permission.camera`** - Not supported by `permission_handler` on web
3. **`Permission.microphone`** - Not supported by `permission_handler` on web
4. **`Permission.storage`** - Not applicable on web (web uses File API instead)

## Web Permission Model

### How Browser Permissions Actually Work

On web platforms, permissions are handled entirely by the **browser**, not by Flutter plugins:

1. **Camera Access**
   - Triggered by: `navigator.mediaDevices.getUserMedia({ video: true })`
   - Browser shows native permission dialog automatically
   - No explicit permission check needed beforehand
   - Requires **HTTPS in production** (HTTP localhost OK for development)

2. **Microphone Access**
   - Triggered by: `navigator.mediaDevices.getUserMedia({ audio: true })`
   - Browser shows native permission dialog automatically
   - Requires **HTTPS in production**

3. **File/Gallery Access**
   - Uses HTML5 File API (`<input type="file">`)
   - **No permission needed** - user explicitly selects files
   - Works with: `accept="image/*"`, `accept="video/*"`, etc.
   - Browser automatically handles file picker dialog

4. **Permission Queries (Limited)**
   - Can query via: `navigator.permissions.query({ name: 'camera' })`
   - Browser support varies
   - Not as reliable as mobile permission systems

## Current Implementation in media_picker_plus_web.dart

The web implementation correctly handles permissions:

```dart
@override
Future<bool> hasCameraPermission() async => true;

@override
Future<bool> requestCameraPermission() async => true;

@override
Future<bool> hasGalleryPermission() async => true;

@override
Future<bool> requestGalleryPermission() async => true;
```

✅ **This is correct!** The web implementation returns `true` because:
- Browser handles permissions via native dialogs when needed
- File picker requires user interaction (implicit permission)
- No pre-flight permission requests are needed

## Solutions

### Solution 1: Platform-Specific Permission Handling (Recommended)

Update `example/lib/main.dart` to skip permission requests on web:

```dart
Future<void> _requestPermissions() async {
  // Skip permission requests on web and desktop platforms
  // Web: Browser handles permissions automatically via native dialogs
  // Desktop: Handled through system settings and Info.plist/manifest
  if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return;
  }

  // Only request permissions on mobile platforms
  await [
    Permission.camera,
    Permission.microphone,
    Permission.photos,
    Permission.storage,
  ].request();
}
```

**Why this works:**
- Web: Browser shows permission dialogs when `getUserMedia()` or file picker is used
- Desktop: Permissions configured in Info.plist/manifest files
- Mobile: Runtime permission requests via `permission_handler`

### Solution 2: Use Conditional Imports (Advanced)

Create platform-specific permission handlers:

**lib/permissions/permissions.dart** (interface):
```dart
abstract class PermissionHandler {
  Future<void> requestMediaPermissions();
  static PermissionHandler create() => throw UnimplementedError();
}
```

**lib/permissions/permissions_mobile.dart**:
```dart
import 'package:permission_handler/permission_handler.dart';
import 'permissions.dart';

class MobilePermissionHandler implements PermissionHandler {
  @override
  Future<void> requestMediaPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.storage,
    ].request();
  }
}

PermissionHandler createPermissionHandler() => MobilePermissionHandler();
```

**lib/permissions/permissions_web.dart**:
```dart
import 'permissions.dart';

class WebPermissionHandler implements PermissionHandler {
  @override
  Future<void> requestMediaPermissions() async {
    // No-op: Browser handles permissions automatically
    return;
  }
}

PermissionHandler createPermissionHandler() => WebPermissionHandler();
```

## Platform-Specific Permission Requirements

### Web

| Feature | Permission Required | How It Works |
|---------|---------------------|--------------|
| Camera | ❌ No pre-request | Browser prompts when `getUserMedia()` called |
| Microphone | ❌ No pre-request | Browser prompts when `getUserMedia()` called |
| File Upload | ❌ No permission | User explicitly selects files via `<input>` |
| Gallery/Photos | ❌ No permission | Uses File API, user interaction required |

**Requirements:**
- ✅ HTTPS in production (HTTP localhost OK for dev)
- ✅ User gesture required to trigger camera/file picker
- ✅ Modern browser with WebRTC support

### Android

| Feature | Permission Required | API Level Notes |
|---------|---------------------|-----------------|
| Camera | `CAMERA` | All API levels |
| Microphone | `RECORD_AUDIO` | Required for video recording |
| Photos/Images | `READ_MEDIA_IMAGES` | API 33+ (Android 13+) |
| Photos/Images | `READ_EXTERNAL_STORAGE` | API 22-32 (Android 5.1-12) |
| Videos | `READ_MEDIA_VIDEO` | API 33+ (Android 13+) |
| Storage | `READ_EXTERNAL_STORAGE` | API 22-32 |

### iOS

| Feature | Permission Required | Key in Info.plist |
|---------|---------------------|-------------------|
| Camera | Camera Usage | `NSCameraUsageDescription` |
| Microphone | Microphone | `NSMicrophoneUsageDescription` |
| Photo Library | Photo Library | `NSPhotoLibraryUsageDescription` |

### macOS

| Feature | Permission Required | Key in Info.plist |
|---------|---------------------|-------------------|
| Camera | Camera Usage | `NSCameraUsageDescription` |
| Microphone | Microphone | `NSMicrophoneUsageDescription` |
| Photo Library | Photo Library | `NSPhotoLibraryUsageDescription` |

**Additional:** Requires entitlements in `Runner.entitlements`

## Testing

### Test on Web

1. **Development (HTTP):**
   ```bash
   flutter run -d chrome --web-port 8080 --web-hostname localhost
   ```
   - Camera access should work on localhost
   
2. **Production (HTTPS):**
   ```bash
   flutter build web --release
   # Serve with HTTPS (required for camera)
   ```

### Expected Behavior

| Action | Expected Result on Web |
|--------|------------------------|
| Click "Pick Image" | File picker opens immediately (no permission dialog) |
| Click "Capture Photo" | Browser shows "Allow camera?" dialog |
| Click "Record Video" | Browser shows "Allow camera and microphone?" dialog |
| Click "Pick Video" | File picker opens immediately (no permission dialog) |

## Recommended Changes

1. ✅ **Update `example/lib/main.dart`:**
   - Add `import 'package:flutter/foundation.dart';` for `kIsWeb`
   - Change `Platform.isMacOS` check to include `kIsWeb`
   - Skip permission requests on web

2. ✅ **Update Documentation:**
   - Clarify that web permissions are browser-managed
   - Document HTTPS requirement for camera in production
   - Add browser compatibility table

3. ✅ **Example Code Updates:**
   - Show platform-specific permission handling
   - Add error handling for permission failures
   - Demonstrate graceful degradation

## Browser Compatibility

### Permission API Support

| Browser | Camera | Microphone | File API | Permission Query API |
|---------|--------|------------|----------|---------------------|
| Chrome 63+ | ✅ | ✅ | ✅ | ✅ Full support |
| Firefox 65+ | ✅ | ✅ | ✅ | ⚠️ Limited support |
| Safari 11.1+ | ✅ | ✅ | ✅ | ❌ Not supported |
| Edge 79+ | ✅ | ✅ | ✅ | ✅ Full support |

**Note:** Even without Permission Query API support, camera/microphone work fine - the browser shows native dialogs when needed.

## Displaying Images on Web vs Native Platforms

### The Problem

On web, `media_picker_plus` returns **data URLs** (base64-encoded) or **blob URLs** for images and videos:
- Data URL format: `data:image/jpeg;base64,/9j/4AAQSkZJRg...`
- Blob URL format: `blob:http://localhost:8080/abc-123`

On native platforms (Android, iOS, macOS), it returns **file paths**:
- File path format: `/path/to/image.jpg`

**Important:** `Image.file()` does NOT work on web and will throw an assertion error:
```
Assertion failed: file:///opt/flutter/packages/flutter/lib/src/widgets/image.dart:526:10
!kIsWeb
"Image.file is not supported on Flutter Web."
```

### The Solution

Use platform-aware image loading:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Helper function to display images on both web and native platforms.
/// On web, media paths are data URLs (base64) or blob URLs, so we use Image.network().
/// On native platforms, media paths are file paths, so we use Image.file().
Widget _buildImage(String path, BoxFit fit) {
  if (kIsWeb || path.startsWith('data:') || path.startsWith('blob:')) {
    // Web: Use Image.network for data URLs and blob URLs
    return Image.network(
      path,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text('Failed to load image'),
            ],
          ),
        );
      },
    );
  } else {
    // Native platforms: Use Image.file for file paths
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text('Failed to load image'),
            ],
          ),
        );
      },
    );
  }
}
```

### Usage Example

```dart
String? imagePath = await MediaPickerPlus.pickImage();
if (imagePath != null) {
  // This works on all platforms
  _buildImage(imagePath, BoxFit.contain);
  
  // ❌ DON'T do this - will crash on web:
  // Image.file(File(imagePath))
  
  // ❌ DON'T do this - won't work on native:
  // Image.network(imagePath)
}
```

### Why This Pattern Works

1. **Web Detection**: Uses `kIsWeb` constant to detect web platform
2. **URL Detection**: Also checks for `data:` and `blob:` prefixes
3. **Appropriate Widget**: 
   - Web → `Image.network()` for URLs
   - Native → `Image.file()` for file paths
4. **Error Handling**: Provides graceful fallback for load failures

## Video Playback on Web vs Native Platforms

### The Problem

Similar to images, video playback requires different approaches on web vs native:
- **Web**: Videos are blob URLs or data URLs
- **Native**: Videos are file paths

Using `VideoPlayerController.file()` on web will cause an error:
```
DartError: Unsupported operation: Platform._operatingSystem
```

### The Solution

Use platform-aware video player initialization:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

void _setVideo(String path) {
  _videoController?.dispose();
  
  // Use appropriate VideoPlayerController based on platform
  if (kIsWeb || path.startsWith('data:') || path.startsWith('blob:')) {
    // Web: Use network controller for data/blob URLs
    _videoController = VideoPlayerController.networkUrl(Uri.parse(path))
      ..initialize().then((_) {
        setState(() {
          _mediaPath = path;
          _isVideo = true;
          _videoController!.play();
        });
      });
  } else {
    // Native platforms: Use file controller
    _videoController = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        setState(() {
          _mediaPath = path;
          _isVideo = true;
          _videoController!.play();
        });
      });
  }
}
```

### Usage Example

```dart
String? videoPath = await MediaPickerPlus.pickVideo();
if (videoPath != null) {
  // This works on all platforms
  _setVideo(videoPath);
  
  // ❌ DON'T do this - will crash on web:
  // VideoPlayerController.file(File(videoPath))
  
  // ❌ DON'T do this - won't work on native:
  // VideoPlayerController.networkUrl(Uri.parse(videoPath))
}
```

### Why This Pattern Works

1. **Platform Detection**: Uses `kIsWeb` and URL pattern matching
2. **Correct Controller**:
   - Web → `VideoPlayerController.networkUrl()` for URLs
   - Native → `VideoPlayerController.file()` for file paths
3. **Error Prevention**: Avoids Platform API calls on web
4. **Consistent Behavior**: Same user experience across platforms

## Video Watermarking on Web (Optional Feature)

### Important Note

**Video watermarking on web is OPTIONAL** and requires additional setup. By default, videos will be returned without watermarks on web.

### Expected Behavior

When you try to add watermarks to videos on web, you'll see this log message:
```
[MediaPickerPlusWeb] Video watermarking failed: Error: ffmpeg.js is not loaded. Returning original video.
```

**This is expected and correct behavior!** The plugin gracefully falls back to returning the unwatermarked video.

### How It Works

```dart
// From media_picker_plus_web.dart
Future<String?> _processVideoFileWithWatermark(
    web.File file, MediaOptions options) async {
  if (options.watermark == null || options.watermark!.isEmpty) {
    // No watermark requested
    return _createVideoObjectURL(file);
  }

  // Check if watermarking function exists
  final addWatermarkToVideo =
      globalThis.getProperty('addWatermarkToVideo'.toJS);
  if (addWatermarkToVideo.isUndefined || addWatermarkToVideo.isNull) {
    // FFmpeg.js not loaded - return video without watermark
    _log('Warning: Video watermarking not available on web. Returning video without watermark.');
    return _createVideoObjectURL(file);
  }
  
  // If FFmpeg.js is loaded, process watermark
  // ... watermarking code ...
}
```

### Why Is This Optional?

1. **Large Bundle Size**: FFmpeg.js adds ~20-30MB to your web app
2. **Loading Time**: 5-15 seconds initial load time
3. **Network Dependency**: Requires internet for initial load
4. **Complexity**: Requires additional JavaScript setup
5. **Limited Use Case**: Many apps don't need video watermarks on web

### Platform Support Summary

| Feature | Android | iOS | macOS | Web |
|---------|---------|-----|-------|-----|
| Image Watermarking | ✅ Built-in | ✅ Built-in | ✅ Built-in | ✅ Built-in |
| Video Watermarking | ✅ Built-in (FFmpegKit) | ✅ Built-in | ✅ Built-in | ⚠️ Optional (FFmpeg.js) |

### Enabling Video Watermarking on Web (Advanced)

If you **really need** video watermarking on web, see the complete setup guide in [`doc/web.md`](../doc/web.md). The setup involves:

1. Adding FFmpeg.js script tags to `web/index.html`
2. Creating a custom watermarking JavaScript function
3. Handling the ~20MB+ download size
4. Dealing with slower performance

**For most apps**: Just skip video watermarking on web. Users can still:
- ✅ Pick videos from gallery
- ✅ Record videos with camera
- ✅ Play videos in the app
- ✅ Upload videos to servers

Watermarking can be done server-side if needed!

## References

1. **MDN Web Docs:**
   - [MediaDevices.getUserMedia()](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia)
   - [Permissions API](https://developer.mozilla.org/en-US/docs/Web/API/Permissions_API)
   - [File API](https://developer.mozilla.org/en-US/docs/Web/API/File_API)

2. **permission_handler Package:**
   - [pub.dev Documentation](https://pub.dev/packages/permission_handler)
   - Platform support clearly states web limitations

3. **WebRTC Security:**
   - Requires HTTPS in production
   - User gesture requirement for camera access
   - Permission persistence across sessions

## Conclusion

The `permission_handler` package's `Permission.photos`, `Permission.camera`, and `Permission.microphone` **do not work on web**. The example app should use platform-specific checks to avoid requesting these permissions on web, as browser permissions are handled automatically through native dialogs when the user interacts with media features.

The current `media_picker_plus_web.dart` implementation is correct in returning `true` for all permission methods, as the browser manages these permissions internally.
