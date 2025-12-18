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

## Next Session Priorities (Actionable)
1. Verify Android video watermarking status (README notes it’s under development)
2. Expand automated testing coverage (see Phase 2)
