# Multi-Capture Screen UI Layout

## Overview
The multi-capture screen provides a professional camera interface with live preview, zoom controls, and intuitive photo management.

## Layout Structure

```
┌─────────────────────────────────────────┐
│ [X]              [2/10]           [Done] │  Top bar
│                                          │
│                                          │
│                                          │
│         LIVE CAMERA PREVIEW              │
│                                          │
│                                          │
│                                          │
│                                          │
│──────────────────────────────────────────│
│       [0.5x] [1x] [2x] [3x]              │  Zoom controls
│                                          │
│   [📸²]         [●]            [↻]       │  Controls
│   Stack       Capture         Switch     │
└──────────────────────────────────────────┘
```

## Components

### Top Bar
- **Close Button (Left)**: Exit with discard confirmation
- **Counter Badge (Center)**: Shows "X/Y" current count and max limit
- **Done Button (Right)**: Confirm selection (enabled when min count met)

### Camera Preview
- Full-screen native camera preview
- Platform-specific implementation:
  - iOS: `AVCaptureVideoPreviewLayer` in `CameraPreviewView`
  - Android: CameraX `PreviewView`

### Bottom Controls Area

#### 1. Zoom Controls (Top Row)
```
[0.5x]  [1x]  [2x]  [3x]
```
- Four preset zoom levels
- Active level highlighted with white background
- Rounded pill buttons
- Native zoom + lens behavior:
  - `0.5x` switches to the back ultrawide lens when available (iOS/Android)
  - `1x+` switches back to the standard back wide lens
  - If ultrawide is unavailable, falls back to the standard back camera

#### 2. Main Control Row (Bottom Row)
```
[Thumbnails]    [Capture]    [Switch]
    90px           70px         90px
```

**Left: Grouped Thumbnails (90×70px)**
- Stacked effect showing depth:
  - Layer 1 (bottom): Faint outline (3+ photos)
  - Layer 2 (middle): Semi-transparent outline (2+ photos)
  - Layer 3 (top): Latest photo with full border
- Blue badge showing total count
- Tap to open grid view

**Center: Capture Button (70×70px)**
- Large circular button
- White inner circle with outer ring
- Shows spinner when capturing
- Disabled (gray) when max reached

**Right: Camera Switch (90×70px)**
- Flip camera icon
- Circular button with semi-transparent background
- Switches between front/back cameras
- Resets zoom to 1x on switch

## Interaction Flow

### Taking Photos
1. User sees live camera preview
2. Select desired zoom level (optional)
3. Tap capture button
4. Photo appears in thumbnail stack with count badge
5. Repeat until max reached or user taps "Done"

### Viewing Photos
1. Tap the thumbnail stack
2. Opens grid view (3 columns)
3. Shows all captured photos
4. Tap any photo for full-screen preview
5. Delete icon on each thumbnail

### Switching Camera
1. Tap flip camera button
2. Camera view disposes and recreates
3. Zoom resets to 1x
4. Preview updates to new camera

## Styling

### Colors
- Background: Black (`Colors.black`)
- Active elements: White (`Colors.white`)
- Semi-transparent overlays: `Colors.white.withValues(alpha: 0.3)`
- Badge count: Blue (`Colors.blue`)
- Disabled state: Gray (`Colors.grey`)

### Gradients
- Top bar: Black (70% alpha) → Transparent
- Bottom controls: Black (70% alpha) → Transparent

### Spacing
- Outer padding: 16px
- Element spacing: 8-24px
- Badge offset: -8px (top/right)

## Accessibility

- All buttons are tappable with sufficient size (minimum 44×44px)
- Visual feedback on active states
- Clear hierarchy with size and positioning
- High contrast white on dark background
- Counter badge provides clear status information

## State Management

```dart
List<String> _capturedPaths         // All captured photo paths
bool _isCapturing                   // Currently taking photo
double _currentZoom                 // Selected zoom level (0.5-3.0)
PreferredCameraDevice _currentDevice // front/back
```

## Performance Considerations

- Native camera views for optimal performance
- Thumbnail caching with `cacheWidth` parameter
- Lazy loading in grid view
- Efficient state updates with targeted `setState()`
- Proper disposal of camera resources

## Future Enhancements

### Additional Features (Optional)
- Flash control toggle
- Grid overlay for composition
- Timer/countdown before capture
- Burst mode
- Photo filters/effects preview
