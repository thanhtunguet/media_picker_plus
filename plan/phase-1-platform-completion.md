# Phase 1 — Platform Completion (High Priority)

Goal: bring macOS and Web implementations up to feature parity with Android/iOS.

## macOS Implementation
- [x] **Complete macOS implementation - Add media picking, camera access, and permissions**
  - Implement NSOpenPanel for gallery selection
  - Add AVCaptureDevice for camera access
  - Handle camera and photo library permissions
  - Create native Swift implementation following iOS patterns
  - Verification: `README.md` documents macOS setup and lists macOS ✅ for pick/capture/crop/resize/watermark.

- [x] **Implement macOS image processing and watermarking functionality**
  - Add image resizing and quality control
  - Implement watermarking with text overlay
  - Add video processing and watermarking
  - Ensure proper file management and cleanup
  - Verification: `README.md` platform support table + usage sections imply macOS processing is supported.

- [x] **Add macOS camera preview with manual controls**
  - Implemented `CameraPreviewWindow` class with `AVCaptureVideoPreviewLayer` for live camera preview
  - Implemented `VideoPreviewWindow` class with recording timer and start/stop controls
  - Added Capture/Cancel buttons for photo capture similar to iOS `UIImagePickerController`
  - Added Record/Stop/Cancel buttons for video recording with duration timer
  - Replaced previous silent automatic capture behavior with user-controlled experience
  - Verification: Users can now see live camera preview and manually control when to capture/record on macOS.

## Web Implementation
- [x] **Complete web implementation - Add HTML5 media APIs and file picking**
  - Implement HTML5 getUserMedia for camera access
  - Add file input for gallery selection
  - Handle web permissions and security constraints
  - Create JavaScript implementation with proper error handling
  - Verification: `README.md` documents Web configuration and lists Web ✅ for pick/capture/crop/resize/watermark.

- [x] **Implement web-based image/video processing and watermarking**
  - Add canvas-based image processing
  - Implement client-side image resizing and quality control
  - Add canvas-based watermarking
  - Implement video processing using WebRTC/MediaRecorder APIs
  - Verification: `README.md` describes Canvas-based processing and shows Web capabilities.

## Android Fixes
- [x] **Fix Android video watermarking**
  - Verified FFmpeg-kit integration exists and is properly configured
  - Fixed FFmpeg command incompatibility with ffmpeg-kit-https variant
  - Changed from libx264 encoder (with unsupported preset options) to mpeg4 encoder with quality parameter
  - Resolved "Unrecognized option 'preset'" error
  - Added camera capture URI fallback when the output file is empty
  - Removed semi-transparent background from video watermark bitmap
  - Adjusted watermark positioning for rotated portrait videos so right-edge placements remain visible
  - Updated README.md platform support table to show Android video watermarking as ✅
  - Verification: Android video watermarking now working for both gallery-picked and camera-recorded videos

## Next Session Priorities (Actionable)
1. Expand automated testing coverage (see Phase 2)
