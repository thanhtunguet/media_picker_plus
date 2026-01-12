---
sidebar_position: 4
---

# Platform-Specific Guides

Media Picker Plus supports multiple platforms. Each platform has its own considerations and setup requirements.

## Android

Android platform is fully supported with all features available. The plugin handles permissions automatically and provides native Android implementations for all media operations.

**Key Features:**
- Full camera and gallery access
- Image cropping and resizing
- Video watermarking and compression
- Permission management

For detailed Android-specific documentation, see the [Android documentation](https://github.com/thanhtunguet/media_picker_plus/blob/main/doc/android.md) in the project repository.

## iOS

iOS platform is fully supported with all features available. Make sure to add the required permission descriptions in your `Info.plist` file.

**Key Features:**
- Full camera and gallery access
- Image cropping and resizing
- Video watermarking and compression
- Permission management

For detailed iOS-specific documentation, see the [iOS documentation](https://github.com/thanhtunguet/media_picker_plus/blob/main/doc/ios.md) in the project repository.

## macOS

macOS platform is fully supported with all features available. Make sure to add the required permission descriptions in your `Info.plist` file.

**Key Features:**
- Full camera and gallery access
- Image cropping and resizing
- Video watermarking and compression
- Permission management

For detailed macOS-specific documentation, see the [macOS documentation](https://github.com/thanhtunguet/media_picker_plus/blob/main/doc/macos.md) in the project repository.

## Web

Web platform support includes most features with some limitations. The plugin uses browser APIs for media access.

**Supported Features:**
- Image picking and capture
- Image cropping and resizing
- Image watermarking
- Video picking and capture
- Video thumbnail generation

**Limitations:**
- Video watermarking requires optional FFmpeg.js setup
- Video compression is not yet implemented

> **⚠️ Important:** Web developers should be aware of platform-specific considerations. See the [Web documentation](https://github.com/thanhtunguet/media_picker_plus/blob/main/doc/web.md) for detailed information about web-specific features, limitations, and how to avoid common runtime errors with `Platform` APIs, `Image.file()`, and `VideoPlayerController.file()`.
