# Media Picker Plus - Example App

A comprehensive example app demonstrating all features of the Media Picker Plus Flutter plugin.

## 🎯 Features Demonstrated

### 📸 Media Operations
- **Single Media Selection**
  - Pick images from gallery with watermarks
  - Pick videos from gallery with watermarks
  - Capture photos with camera
  - Record videos with camera

- **Multiple Media Selection**
  - Pick multiple images with batch processing
  - Pick multiple videos with batch processing
  - Progress tracking for multiple selections

### 📁 File Operations
- **Single File Selection**
  - Pick documents with extension filtering
  - Support for PDF, DOC, DOCX, TXT, CSV files

- **Multiple File Selection**
  - Pick multiple files with extension filtering
  - Support for office documents and spreadsheets

### 🔐 Permission Management
- Check camera and gallery permissions
- Request permissions with user-friendly dialogs
- Handle permission denied scenarios

### 🎨 Advanced Features
- **Watermarking**
  - 9 different watermark positions
  - Customizable font sizes
  - Text watermarks with emoji support
  - **🕒 Timestamp watermarking** with multiple formats
  - Real-time timestamp generation

- **Image Processing**
  - Quality control (0-100%)
  - Resizing with aspect ratio preservation
  - Maximum width/height constraints

- **Video Processing**
  - Duration limits for recording
  - Video watermarking
  - Quality optimization
  - **🎤 Smart microphone permission handling**

- **🔒 Intelligent Permission Management**
  - Automatic microphone permission for video recording
  - Smart permission flow to prevent user experience interruptions
  - Visual permission status indicators
  - Fallback handling for denied permissions

## 🚀 Running the Example

### Prerequisites
- Flutter SDK (3.19.0 or later)
- Platform-specific requirements:
  - **Android**: Android SDK, Android Studio
  - **iOS**: Xcode, iOS Simulator
  - **macOS**: Xcode, macOS development tools
  - **Web**: Chrome browser

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/thanhtunguet/media_picker_plus.git
   cd media_picker_plus/example
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the example**:
   ```bash
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   
   # For macOS
   flutter run -d macos
   
   # For Web
   flutter run -d chrome
   ```

## 📱 Platform-Specific Setup

### Android Setup

1. **Add permissions** to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   
   <!-- For Android 13+ -->
   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
   <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
   ```

2. **Minimum SDK version**: Ensure `minSdkVersion` is 21 or higher in `android/app/build.gradle`

### iOS Setup

1. **Add permissions** to `ios/Runner/Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app needs camera access to capture photos and videos</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>This app needs photo library access to pick images and videos</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>This app needs microphone access to record videos</string>
   ```

2. **Minimum iOS version**: Ensure iOS deployment target is 12.0 or higher

### macOS Setup

1. **Add permissions** to `macos/Runner/Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app needs camera access to capture photos and videos</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>This app needs photo library access to pick images and videos</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>This app needs microphone access to record videos</string>
   ```

2. **Enable camera and file access** in `macos/Runner/Release.entitlements`:
   ```xml
   <key>com.apple.security.device.camera</key>
   <true/>
   <key>com.apple.security.files.user-selected.read-write</key>
   <true/>
   ```

### Web Setup

1. **HTTPS requirement**: Camera access requires HTTPS in production
2. **Browser compatibility**: Tested with Chrome, Firefox, Safari, Edge
3. **File access**: Uses HTML5 File API for file selection

## 🎮 How to Use the Example

The example app includes two main sections:

### 📱 **Main Screen** - Basic Operations
Access basic media and file operations with standard watermarking.

### 🧪 **Advanced Examples** - Timestamp & Permissions
Tap the lab flask icon (🧪) in the app bar to access advanced features:
- **🕒 Timestamp Watermarking**: Automatic timestamp generation in multiple formats
- **🔒 Smart Permission Management**: Intelligent microphone permission handling

### 1. Single Media Operations

**Pick Image with Watermark**:
- Tap "Pick Image" button
- Select an image from gallery
- Image will be processed with watermark and resizing
- Preview shows the processed image

**Pick Image with Timestamp** (Advanced):
- Use "Pick Image" in Advanced Examples
- Image automatically gets timestamped watermark
- Timestamp format: `📸 2024-07-17 14:30:25`

**Capture Photo**:
- Tap "Capture Photo" button
- Grant camera permission if prompted
- Take a photo using the camera
- Photo will be processed with watermark

**Capture Photo with Detailed Timestamp** (Advanced):
- Use "Capture Photo" in Advanced Examples
- Photo gets detailed timestamp: `📷 Captured: Jul 17, 2024 • 14:30:25`

**Pick/Record Video**:
- Tap "Pick Video" or "Record Video"
- Select/record a video
- Video will be processed with watermark overlay

**Record Video with Smart Permissions** (Advanced):
- Use "Record Video" in Advanced Examples
- App automatically handles microphone permission
- Shows permission info dialog before recording
- Timestamp format: `🎬 Recorded: Jul 17, 2024 • 14:30:25`

### 2. Multiple Media Operations

**Pick Multiple Images**:
- Tap "Multiple Images" button
- Select multiple images from gallery
- All images will be processed with watermarks
- Preview shows thumbnails of all selected images

**Pick Multiple Videos**:
- Tap "Multiple Videos" button
- Select multiple videos from gallery
- All videos will be processed with watermarks

### 3. File Operations

**Pick Single File**:
- Tap "Pick File" button
- Select a document (PDF, DOC, DOCX, TXT, CSV)
- File path will be displayed

**Pick Multiple Files**:
- Tap "Multiple Files" button
- Select multiple documents
- All file paths will be displayed

### 4. Permission Management

**Check Permissions**:
- Tap "Check Permissions" button
- View current permission status
- See camera and gallery permission states

**Request Permissions**:
- Tap "Request Permissions" button
- Grant permissions for camera and gallery
- Permission results will be displayed

## 🔧 Code Examples

### Basic Image Picking
```dart
Future<void> pickImage() async {
  try {
    final path = await MediaPickerPlus.pickImage(
      options: const MediaOptions(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
        watermark: '📸 Media Picker Plus',
        watermarkPosition: WatermarkPosition.bottomRight,
      ),
    );
    if (path != null) {
      print('Image picked: $path');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### 🕒 Timestamp Watermarking
```dart
/// Generate timestamp: 2024-07-17 14:30:25
String _generateTimestamp() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
         '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
}

/// Pick image with real-time timestamp
Future<void> pickImageWithTimestamp() async {
  try {
    final timestamp = _generateTimestamp();
    final path = await MediaPickerPlus.pickImage(
      options: MediaOptions(
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1080,
        watermark: '📸 $timestamp',
        watermarkFontSize: 24,
        watermarkPosition: WatermarkPosition.bottomRight,
      ),
    );
    if (path != null) {
      print('Timestamped image: $path');
    }
  } catch (e) {
    print('Error: $e');
  }
}

/// Generate detailed timestamp: Jul 17, 2024 • 14:30:25
String _generateDetailedTimestamp() {
  final now = DateTime.now();
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[now.month - 1]} ${now.day}, ${now.year} • '
         '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
}
```

### 🎤 Smart Video Recording with Permission Handling
```dart
Future<void> recordVideoWithSmartPermissions() async {
  // Check camera permission first
  if (!await MediaPickerPlus.hasCameraPermission()) {
    final granted = await MediaPickerPlus.requestCameraPermission();
    if (!granted) {
      _showError('Camera permission is required');
      return;
    }
  }

  // Show microphone permission info dialog
  final shouldContinue = await _showMicrophonePermissionDialog();
  if (!shouldContinue) return;

  try {
    final timestamp = _generateDetailedTimestamp();
    final path = await MediaPickerPlus.recordVideo(
      options: MediaOptions(
        watermark: '🎬 Recorded: $timestamp',
        watermarkFontSize: 26,
        watermarkPosition: WatermarkPosition.topLeft,
        maxDuration: Duration(minutes: 5),
      ),
    );
    if (path != null) {
      print('Video recorded with timestamp: $path');
    }
  } catch (e) {
    print('Error: $e');
  }
}

/// Show informative microphone permission dialog
Future<bool> _showMicrophonePermissionDialog() async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Microphone Permission Info'),
      content: Text(
        'For video recording with audio, the app will automatically request '
        'microphone permission when needed. On some platforms, audio recording '
        'may require additional permissions to be granted manually in device settings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Continue Recording'),
        ),
      ],
    ),
  );
  return result ?? false;
}
```

### Multiple Selection
```dart
Future<void> pickMultipleImages() async {
  try {
    final paths = await MediaPickerPlus.pickMultipleImages(
      options: const MediaOptions(
        imageQuality: 80,
        watermark: '📸 Multiple Images',
        watermarkPosition: WatermarkPosition.bottomLeft,
      ),
    );
    if (paths != null && paths.isNotEmpty) {
      print('Picked ${paths.length} images');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### File Picking with Extensions
```dart
Future<void> pickDocument() async {
  try {
    final path = await MediaPickerPlus.pickFile(
      allowedExtensions: ['.pdf', '.doc', '.docx', '.txt'],
    );
    if (path != null) {
      print('Document picked: $path');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Permission Handling
```dart
Future<void> checkAndRequestPermissions() async {
  // Check current permissions
  final cameraPermission = await MediaPickerPlus.hasCameraPermission();
  final galleryPermission = await MediaPickerPlus.hasGalleryPermission();
  
  // Request permissions if needed
  if (!cameraPermission) {
    await MediaPickerPlus.requestCameraPermission();
  }
  
  if (!galleryPermission) {
    await MediaPickerPlus.requestGalleryPermission();
  }
}
```

## 🎨 UI Components

### Preview Components
- **Single Media Preview**: Shows selected image/video with clear button
- **Multiple Media Preview**: Horizontal scrollable list of thumbnails
- **File Preview**: Shows file icon with name and path
- **Multiple File Preview**: Vertical list of selected files

### Action Buttons
- **Material Design**: Consistent button styling with icons
- **Loading States**: Loading indicators during operations
- **Error Handling**: User-friendly error messages

### Responsive Design
- **Mobile-first**: Optimized for mobile devices
- **Tablet Support**: Responsive layout for tablets
- **Desktop Support**: Adapted for desktop screens
- **Web Support**: Touch and mouse interaction

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Platform-Specific Tests
```bash
# Android
flutter test --platform android

# iOS
flutter test --platform ios

# Web
flutter test --platform chrome
```

## 📊 Performance Considerations

### Memory Management
- Images are processed efficiently with streaming
- Large files are handled with progress callbacks
- Memory usage is optimized for mobile devices

### File Size Optimization
- Image quality settings reduce file sizes
- Watermarking is applied without quality loss
- Video compression maintains quality

### Platform Performance
- **Android**: Native Java implementation with optimal performance
- **iOS**: Swift implementation with AVFoundation
- **macOS**: Swift implementation with native file dialogs
- **Web**: JavaScript implementation with HTML5 APIs

## 🔍 Debugging

### Common Issues

1. **Permission Denied**:
   - Check platform-specific permission configurations
   - Ensure proper permission descriptions are added
   - Test permission request flow

2. **Camera Not Available**:
   - Check if running on physical device (not simulator)
   - Verify camera permissions are granted
   - Check device camera functionality

3. **File Not Found**:
   - Verify file path validity
   - Check file system permissions
   - Ensure proper file handling

### Debug Mode
```bash
flutter run --debug
```

### Verbose Logging
```bash
flutter logs --verbose
```

## 📚 Additional Resources

- [API Usage Guide](API_USAGE.md) - Comprehensive API documentation
- [Plugin Repository](https://github.com/thanhtunguet/media_picker_plus) - Source code and issues
- [pub.dev Package](https://pub.dev/packages/media_picker_plus) - Package information
- [Flutter Documentation](https://flutter.dev/docs) - Flutter framework docs

## 🤝 Contributing

We welcome contributions to improve the example app:

1. **Report Issues**: Create issues for bugs or feature requests
2. **Submit PRs**: Contribute code improvements or new examples
3. **Documentation**: Help improve documentation and examples
4. **Testing**: Add test cases for better coverage

## 📄 License

This example app is part of the Media Picker Plus plugin and is released under the MIT License.