# macOS Camera Preview Implementation

## Overview
Implemented native camera preview windows for macOS that display live camera feed with manual capture controls, providing a user experience similar to iOS `UIImagePickerController`.

## What Changed

### Before
- Camera capture was automatic and silent (no preview)
- Photo capture: Waited 2 seconds then automatically captured
- Video recording: Started automatically and stopped after max duration
- Users couldn't see what they were capturing
- No manual control over when to capture/record

### After
- **Camera Preview Window** (`CameraPreviewWindow`):
  - Shows live camera feed using `AVCaptureVideoPreviewLayer`
  - Manual "Capture" button to take photo
  - "Cancel" button to abort
  - Keyboard shortcuts: Enter to capture, Escape to cancel
  - Window size: 640x520 pixels

- **Video Preview Window** (`VideoPreviewWindow`):
  - Shows live camera feed during recording
  - "Record" button to start recording (changes to "Stop" when recording)
  - Live recording timer (00:00 format)
  - Auto-stops at max duration
  - "Cancel" button to abort
  - Keyboard shortcuts: Enter to record/stop, Escape to cancel
  - Window size: 640x520 pixels

## Technical Implementation

### Files Modified
- `/macos/Classes/MediaPickerPlusPlugin.swift`

### New Classes Added

#### 1. `CameraPreviewWindow`
- Extends `NSWindow`
- Uses `AVCaptureVideoPreviewLayer` for live preview
- Properties:
  - `captureSession`: The AVFoundation capture session
  - `photoOutput`: Photo output for capturing
  - `photoDelegate`: Delegate to handle captured photos
  - `onCapture`: Callback when capture button is pressed
  - `onCancel`: Callback when cancel button is pressed
  - `previewLayer`: Video preview layer

#### 2. `VideoPreviewWindow`
- Extends `NSWindow`
- Uses `AVCaptureVideoPreviewLayer` for live preview
- Properties:
  - `captureSession`: The AVFoundation capture session
  - `movieOutput`: Movie output for recording
  - `movieDelegate`: Delegate to handle recorded videos
  - `outputURL`: File URL for saving video
  - `maxDuration`: Maximum recording duration
  - `onCancel`: Callback when cancel button is pressed
  - `isRecording`: Recording state
  - `recordingTimer`: Timer for updating duration display
  - `timerLabel`: Label showing recording duration

### Key Methods Modified

#### `capturePhoto()`
- Removed automatic 2-second delay capture
- Removed timeout mechanism
- Now creates and shows `CameraPreviewWindow`
- User manually triggers capture via UI button

#### `performVideoRecording()`
- Removed automatic 3-second delay start
- Removed automatic timeout
- Now creates and shows `VideoPreviewWindow`
- User manually starts/stops recording via UI buttons

#### `cleanupCaptureSession()`
- Added cleanup for preview windows
- Properly closes and releases window resources

## User Experience

### Photo Capture Flow
1. User calls `MediaPickerPlus.pickMedia()` with camera source
2. Camera permission is checked/requested
3. Camera preview window appears showing live feed
4. User sees themselves on camera
5. User clicks "Capture" button (or presses Enter)
6. Photo is captured
7. Preview window closes
8. Image is processed (crop, resize, watermark if specified)
9. Result is returned to Flutter

### Video Recording Flow
1. User calls `MediaPickerPlus.pickMedia()` with camera source for video
2. Camera and microphone permissions are checked/requested
3. Video preview window appears showing live feed
4. User sees themselves on camera
5. User clicks "Record" button (or presses Enter)
6. Recording starts, button changes to "Stop"
7. Timer shows elapsed time (00:00, 00:01, etc.)
8. User clicks "Stop" or waits for max duration
9. Recording stops
10. Preview window closes
11. Video is processed (watermark if specified)
12. Result is returned to Flutter

### Cancellation
- User can click "Cancel" or press Escape at any time
- Window closes immediately
- User receives cancellation error
- No media is captured/returned

## Platform Comparison

| Feature | iOS | macOS (Before) | macOS (After) |
|---------|-----|----------------|---------------|
| Camera Preview | ✅ UIImagePickerController | ❌ Silent capture | ✅ Custom NSWindow |
| Manual Control | ✅ OnScreen buttons | ❌ Automatic | ✅ OnScreen buttons |
| Live Feed | ✅ Yes | ❌ No | ✅ Yes |
| Capture Button | ✅ Yes | ❌ N/A | ✅ Yes |
| Cancel Option | ✅ Yes | ❌ No | ✅ Yes |
| Video Timer | ✅ Yes | ❌ No | ✅ Yes |

## Testing Recommendations

To test the new camera preview:

1. **Photo Capture Test**:
   ```dart
   final result = await MediaPickerPlus.pickMedia(
     source: MediaSource.camera,
     type: MediaType.image,
   );
   ```
   - Verify preview window appears
   - Check that live camera feed is visible
   - Test "Capture" button captures photo
   - Test "Cancel" button cancels operation
   - Test Enter/Escape keyboard shortcuts

2. **Video Recording Test**:
   ```dart
   final result = await MediaPickerPlus.pickMedia(
     source: MediaSource.camera,
     type: MediaType.video,
     options: MediaOptions(maxDuration: 30),
   );
   ```
   - Verify preview window appears
   - Check that live camera feed is visible
   - Test "Record" button starts recording
   - Verify timer updates correctly
   - Test "Stop" button stops recording
   - Test auto-stop at max duration
   - Test "Cancel" button aborts recording
   - Test Enter/Escape keyboard shortcuts

## Known Limitations

1. Window size is fixed at 640x520 (not resizable in current implementation)
2. No flash control UI (can be added if needed)
3. No camera switching UI for devices with multiple cameras (uses best available)
4. No zoom controls (can be added if needed)

## Future Enhancements

Potential improvements that could be added:
- Resizable preview windows
- Camera selection dropdown (for devices with multiple cameras)
- Zoom slider
- Flash toggle button
- Countdown timer for photo capture
- Video quality selector
- Custom window styling/theming
