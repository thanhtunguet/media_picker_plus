# media_picker_plus — Project Overview

## Purpose
A Flutter plugin to pick or capture images and videos with quality control options.
Supports Android, iOS, macOS, and Web platforms.

## Tech Stack
- **Language**: Dart / Flutter
- **Version**: 1.1.0-rc.11 (semver with rc tags)
- **Platform targets**: Android (Kotlin), iOS (Swift), macOS (Swift), Web (Dart)
- **Key dependencies**: `plugin_platform_interface`, `flutter_web_plugins`, `web: ^1.1.1`

## Architecture
- Platform interface pattern: abstract (`MediaPickerPlusPlatformInterface`) → method channel (`MediaPickerPlusMethodChannel`) → web (`MediaPickerPlusWeb`)
- Conditional imports: files ending in `_io.dart` / `_web.dart` for platform-specific code
- Public API: static methods on `MediaPickerPlus` class in `lib/media_picker_plus.dart`
- Method channel name: `info.thanhtunguet.media_picker_plus`

## Key Files in `lib/`
- `media_picker_plus.dart` — Public API
- `media_picker_plus_platform_interface.dart` — Abstract interface
- `media_picker_plus_method_channel.dart` — Method channel implementation
- `media_picker_plus_web.dart` — Web implementation
- `crop_ui.dart`, `crop_helper.dart` — Crop UI widgets
- `multi_capture_screen.dart`, `multi_image_helper.dart` — Multi-image capture
- `*_io.dart` / `*_web.dart` — Platform conditional implementations

## Code Style
- Follows `flutter_lints` (flutter.yaml)
- `doc/` directory excluded from analyzer
- Dart formatting via `dart format`
