# Web Camera API Enhancement Proposal

## Executive Summary

This document proposes enhancing the web implementation of `media_picker_plus` to use modern browser Camera APIs (getUserMedia, ImageCapture, MediaRecorder) instead of relying solely on file input dialogs. This will provide users with:
- Live camera preview
- Direct photo capture with camera controls
- Direct video recording with start/stop controls
- Better user experience matching native mobile apps
- Graceful fallback to file picker for unsupported browsers

## Current Implementation

The current web implementation (`lib/media_picker_plus_web.dart`) uses:

```dart
Future<String?> _captureFromCamera(MediaType type, MediaOptions options) async {
  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.capture = 'environment'; // Hints to open camera
  input.accept = type == MediaType.image ? 'image/*' : 'video/*';
  // ... opens file picker dialog
}
```

**Limitations:**
- ❌ No live camera preview
- ❌ No camera controls (zoom, flash, etc.)
- ❌ Opens system camera app or file picker (varies by browser/device)
- ❌ Users can't see what they're capturing in real-time within the app
- ⚠️ Inconsistent behavior across browsers and devices

## Proposed Implementation

### Architecture Overview

```
┌─────────────────────────────────────────┐
│   User calls capturePhoto/recordVideo   │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│   Check Browser Capability              │
│   (getUserMedia available?)             │
└────┬──────────────────────────┬─────────┘
     │                          │
     │ Yes                      │ No
     ▼                          ▼
┌──────────────────┐    ┌─────────────────┐
│  Camera API      │    │  File Input     │
│  (Modern)        │    │  (Fallback)     │
└──────────────────┘    └─────────────────┘
```

### 1. Photo Capture Flow

```dart
// Pseudo-code flow
async function capturePhoto() {
  if (supportsGetUserMedia()) {
    // Modern approach
    stream = await getUserMedia({ video: { facingMode: 'environment' }})
    showCameraPreview(stream)
    
    if (supportsImageCapture()) {
      // Best quality
      imageCapture = new ImageCapture(stream.track)
      blob = await imageCapture.takePhoto()
    } else {
      // Fallback: snapshot from video
      drawVideoFrameToCanvas()
      blob = await canvas.toBlob()
    }
    
    return processImageBlob(blob)
  } else {
    // Legacy fallback
    return useFileInputCapture()
  }
}
```

### 2. Video Recording Flow

```dart
// Pseudo-code flow
async function recordVideo() {
  if (supportsGetUserMedia() && supportsMediaRecorder()) {
    // Modern approach
    stream = await getUserMedia({ video: true, audio: true })
    showCameraPreview(stream)
    
    recorder = new MediaRecorder(stream)
    chunks = []
    
    recorder.ondataavailable = (e) => chunks.push(e.data)
    recorder.start()
    
    // Show recording UI with stop button
    await waitForUserToStop()
    
    recorder.stop()
    blob = new Blob(chunks, { type: 'video/webm' })
    
    return processVideoBlob(blob)
  } else {
    // Legacy fallback
    return useFileInputCapture()
  }
}
```

### 3. Camera Preview UI

Create a Flutter Widget overlay that shows:
- Live camera feed (`<video>` element)
- Capture/Record button
- Cancel button
- Optional: Camera switch (front/back)
- Optional: Flash toggle
- Optional: Zoom control
- Recording timer (for video)

## Browser Support Matrix

| Feature | Chrome | Firefox | Safari | Edge | Fallback |
|---------|--------|---------|--------|------|----------|
| getUserMedia | 63+ | 65+ | 11.1+ | 79+ | File input |
| ImageCapture | 59+ | Partial* | Yes | Yes | Canvas snapshot |
| MediaRecorder | 49+ | 29+ | 14.1+ | 79+ | File input |

*Firefox has partial ImageCapture support (takePhoto works but some settings don't)

### HTTPS Requirement

⚠️ **Important**: getUserMedia requires HTTPS in production (or localhost for development)

## Implementation Plan

### Phase 1: Camera Detection & Capability Check ✅
- [ ] Add helper method `_supportsGetUserMedia()`
- [ ] Add helper method `_supportsImageCapture()`
- [ ] Add helper method `_supportsMediaRecorder()`
- [ ] Add helper method `_requestCameraPermission()` using getUserMedia

### Phase 2: Photo Capture with Camera API ✅
- [ ] Create camera preview UI component
- [ ] Implement getUserMedia() for camera stream
- [ ] Implement ImageCapture.takePhoto() path
- [ ] Implement canvas snapshot fallback
- [ ] Preserve existing file input fallback
- [ ] Add camera controls (switch camera, close)
- [ ] Ensure watermarking still works

### Phase 3: Video Recording with Camera API ✅
- [ ] Create video recording UI component
- [ ] Implement getUserMedia() for video stream
- [ ] Implement MediaRecorder for recording
- [ ] Add recording controls (start, stop, timer)
- [ ] Handle audio track from microphone
- [ ] Preserve existing file input fallback
- [ ] Ensure watermarking still works

### Phase 4: Enhanced Features 🎯
- [ ] Camera switching (front/back)
- [ ] Flash control (if available)
- [ ] Zoom control
- [ ] Focus/tap-to-focus
- [ ] Resolution selection
- [ ] Format selection (WebM, MP4 if supported)

## Code Structure

```
lib/
  media_picker_plus_web.dart           # Main implementation
  web/
    camera_preview_widget.dart         # Camera preview UI
    camera_api_helper.dart             # getUserMedia helper
    image_capture_helper.dart          # ImageCapture API wrapper
    media_recorder_helper.dart         # MediaRecorder API wrapper
    capability_detector.dart           # Browser capability detection
```

## Example Usage (No API Changes)

The beauty of this proposal is that **no changes to the public API are required**. Existing code continues to work:

```dart
// This works exactly as before, but with better UX on modern browsers
String? photo = await MediaPickerPlus.capturePhoto();
String? video = await MediaPickerPlus.recordVideo();
```

## Benefits

✅ **Better User Experience**: Live preview, real-time feedback
✅ **More Control**: Users can frame shots properly before capturing
✅ **Native-like Feel**: Similar to mobile camera apps
✅ **Progressive Enhancement**: Modern browsers get better UX, others still work
✅ **No Breaking Changes**: Existing API remains unchanged
✅ **Backward Compatible**: Automatic fallback to file input

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Browser incompatibility | Medium | Feature detection + fallback |
| HTTPS requirement | Medium | Documentation, localhost dev support |
| Increased complexity | Low | Modular design, clear separation |
| Permissions denial | Low | Graceful fallback to file picker |

## Security & Privacy

- ✅ getUserMedia requires user permission (browser handles this)
- ✅ HTTPS requirement ensures secure context
- ✅ Camera/mic indicators shown by browser
- ✅ Stream must be stopped when done
- ✅ No persistent access without user action

## Performance Considerations

- Camera preview requires video decoding (GPU accelerated in modern browsers)
- MediaRecorder encoding is hardware accelerated on most devices
- Memory: One video stream + recording buffer
- Cleanup: Must stop tracks and release resources

## Testing Strategy

1. **Unit Tests**: Capability detection logic
2. **Integration Tests**: Mock browser APIs
3. **Manual Testing Matrix**:
   - Chrome (desktop, mobile)
   - Firefox (desktop, mobile)
   - Safari (desktop, iOS)
   - Edge
   - With/without HTTPS
   - With/without camera permission

## Documentation Updates Required

- [ ] Update README.md web section
- [ ] Update docs/web-permissions.md
- [ ] Add camera API usage guide
- [ ] Update example app
- [ ] Add troubleshooting section

## Open Questions

1. Should we allow users to choose between camera API and file input?
2. What should be the default camera (front vs back)?
3. Should we provide zoom controls by default?
4. Should we support multiple formats (WebM, MP4)?
5. What's the maximum video recording duration?

## References

- [MDN: getUserMedia](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia)
- [MDN: ImageCapture](https://developer.mozilla.org/en-US/docs/Web/API/ImageCapture)
- [MDN: MediaRecorder](https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder)
- [Can I Use: getUserMedia](https://caniuse.com/stream)
- [Can I Use: MediaRecorder](https://caniuse.com/mediarecorder)

## Conclusion

This enhancement will significantly improve the web experience for `media_picker_plus` users while maintaining full backward compatibility. The progressive enhancement approach ensures that all users benefit, with modern browsers getting the best experience and older browsers continuing to work with the file picker fallback.

**Recommendation**: Proceed with implementation in phases, starting with photo capture (Phase 2) as it's simpler and provides immediate value.
