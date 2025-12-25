# Media Picker Plus - Project Overview

## Purpose
A comprehensive Flutter plugin for media selection with advanced processing capabilities. Pick images, videos, and files from gallery or camera with built-in watermarking, resizing, and quality control features.

## Tech Stack
- **Primary Language**: Dart (Flutter)
- **Platform Implementations**:
  - Android: Kotlin
  - iOS/macOS: Swift  
  - Web: TypeScript
- **Key Dependencies**: flutter, plugin_platform_interface, web
- **Min SDK**: Dart >=2.17.0 <4.0.0, Flutter >=2.5.0

## Platform Support
- Android (API 21+)
- iOS (11.0+)
- macOS (11.0+)
- Web

## Key Features
- Media selection (images/videos/files)
- Camera capture
- Image cropping with interactive UI
- Watermarking (images and videos)
- Image resizing
- Quality control
- FFmpeg integration for video processing

## Current Known Limitations
- **Video watermarking on Android is NOT implemented** (marked as ❌ in README)
- Images can be watermarked properly on all platforms
- Videos can be watermarked on iOS, macOS, and Web but not Android
