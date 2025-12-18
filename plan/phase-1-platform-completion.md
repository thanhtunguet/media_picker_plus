# Phase 1 — Platform Completion (High Priority)

Goal: bring macOS and Web implementations up to feature parity with Android/iOS.

## macOS Implementation
- [ ] **Complete macOS implementation - Add media picking, camera access, and permissions**
  - Implement NSOpenPanel for gallery selection
  - Add AVCaptureDevice for camera access
  - Handle camera and photo library permissions
  - Create native Swift implementation following iOS patterns

- [ ] **Implement macOS image processing and watermarking functionality**
  - Add image resizing and quality control
  - Implement watermarking with text overlay
  - Add video processing and watermarking
  - Ensure proper file management and cleanup

## Web Implementation
- [ ] **Complete web implementation - Add HTML5 media APIs and file picking**
  - Implement HTML5 getUserMedia for camera access
  - Add file input for gallery selection
  - Handle web permissions and security constraints
  - Create JavaScript implementation with proper error handling

- [ ] **Implement web-based image/video processing and watermarking**
  - Add canvas-based image processing
  - Implement client-side image resizing and quality control
  - Add canvas-based watermarking
  - Implement video processing using WebRTC/MediaRecorder APIs

## Next Session Priorities (Actionable)
1. macOS: start with basic media picking (`NSOpenPanel`)
2. Web: implement client-side image processing (Canvas)

