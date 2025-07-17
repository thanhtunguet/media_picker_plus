import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';
import 'advanced_example.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Picker Plus Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MediaPickerExample(),
    );
  }
}

class MediaPickerExample extends StatefulWidget {
  const MediaPickerExample({super.key});

  @override
  State<MediaPickerExample> createState() => _MediaPickerExampleState();
}

class _MediaPickerExampleState extends State<MediaPickerExample> {
  String? _singleMediaPath;
  List<String> _multipleMediaPaths = [];
  String? _filePath;
  List<String> _multipleFilePaths = [];
  bool _isLoading = false;

  // Single Media Operations
  Future<void> _pickImage() async {
    setState(() => _isLoading = true);
    try {
      final path = await MediaPickerPlus.pickImage(
        options: const MediaOptions(
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
          watermark: '📸 Media Picker Plus',
          watermarkFontSize: 32,
          watermarkPosition: WatermarkPosition.bottomRight,
        ),
      );
      setState(() {
        _singleMediaPath = path;
      });
    } catch (e) {
      _showError('Error picking image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickVideo() async {
    setState(() => _isLoading = true);
    try {
      final path = await MediaPickerPlus.pickVideo(
        options: const MediaOptions(
          watermark: '🎥 Media Picker Plus',
          watermarkFontSize: 28,
          watermarkPosition: WatermarkPosition.topLeft,
          maxDuration: Duration(minutes: 5),
        ),
      );
      setState(() {
        _singleMediaPath = path;
      });
    } catch (e) {
      _showError('Error picking video: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _capturePhoto() async {
    setState(() => _isLoading = true);
    try {
      final path = await MediaPickerPlus.capturePhoto(
        options: const MediaOptions(
          imageQuality: 90,
          maxWidth: 1280,
          maxHeight: 1280,
          watermark: '📷 Captured with Media Picker Plus',
          watermarkFontSize: 24,
          watermarkPosition: WatermarkPosition.bottomCenter,
        ),
      );
      setState(() {
        _singleMediaPath = path;
      });
    } catch (e) {
      _showError('Error capturing photo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recordVideo() async {
    setState(() => _isLoading = true);
    try {
      final path = await MediaPickerPlus.recordVideo(
        options: const MediaOptions(
          watermark: '🎬 Recorded with Media Picker Plus',
          watermarkFontSize: 26,
          watermarkPosition: WatermarkPosition.topRight,
          maxDuration: Duration(minutes: 2),
        ),
      );
      setState(() {
        _singleMediaPath = path;
      });
    } catch (e) {
      _showError('Error recording video: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Multiple Media Operations
  Future<void> _pickMultipleImages() async {
    setState(() => _isLoading = true);
    try {
      final paths = await MediaPickerPlus.pickMultipleImages(
        options: const MediaOptions(
          imageQuality: 80,
          maxWidth: 1080,
          maxHeight: 1080,
          watermark: '📸 Multiple Images',
          watermarkFontSize: 20,
          watermarkPosition: WatermarkPosition.bottomLeft,
        ),
      );
      setState(() {
        _multipleMediaPaths = List<String>.from(paths ?? []);
      });
    } catch (e) {
      _showError('Error picking multiple images: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMultipleVideos() async {
    setState(() => _isLoading = true);
    try {
      final paths = await MediaPickerPlus.pickMultipleVideos(
        options: const MediaOptions(
          watermark: '🎥 Multiple Videos',
          watermarkFontSize: 22,
          watermarkPosition: WatermarkPosition.middleCenter,
        ),
      );
      setState(() {
        _multipleMediaPaths = List<String>.from(paths ?? []);
      });
    } catch (e) {
      _showError('Error picking multiple videos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // File Operations
  Future<void> _pickFile() async {
    setState(() => _isLoading = true);
    try {
      final path = await MediaPickerPlus.pickFile(
        allowedExtensions: ['.pdf', '.doc', '.docx', '.txt', '.csv'],
      );
      setState(() {
        _filePath = path;
      });
    } catch (e) {
      _showError('Error picking file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMultipleFiles() async {
    setState(() => _isLoading = true);
    try {
      final paths = await MediaPickerPlus.pickMultipleFiles(
        allowedExtensions: [
          '.pdf',
          '.doc',
          '.docx',
          '.txt',
          '.csv',
          '.xls',
          '.xlsx'
        ],
      );
      setState(() {
        _multipleFilePaths = List<String>.from(paths ?? []);
      });
    } catch (e) {
      _showError('Error picking multiple files: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Permission Operations
  Future<void> _checkPermissions() async {
    final cameraPermission = await MediaPickerPlus.hasCameraPermission();
    final galleryPermission = await MediaPickerPlus.hasGalleryPermission();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Camera Permission: ${cameraPermission ? "✅ Granted" : "❌ Denied"}'),
            const SizedBox(height: 8),
            Text(
                'Gallery Permission: ${galleryPermission ? "✅ Granted" : "❌ Denied"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final cameraGranted = await MediaPickerPlus.requestCameraPermission();
    final galleryGranted = await MediaPickerPlus.requestGalleryPermission();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Request Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Camera Permission: ${cameraGranted ? "✅ Granted" : "❌ Denied"}'),
            const SizedBox(height: 8),
            Text(
                'Gallery Permission: ${galleryGranted ? "✅ Granted" : "❌ Denied"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _clearSingleMedia() {
    setState(() {
      _singleMediaPath = null;
    });
  }

  void _clearMultipleMedia() {
    setState(() {
      _multipleMediaPaths.clear();
    });
  }

  void _clearSingleFile() {
    setState(() {
      _filePath = null;
    });
  }

  void _clearMultipleFiles() {
    setState(() {
      _multipleFilePaths.clear();
    });
  }

  Widget _buildMediaPreview() {
    if (_singleMediaPath == null) return const SizedBox.shrink();

    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Single Media Preview',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (kIsWeb || _singleMediaPath!.startsWith('data:'))
            // Web implementation - data URL
            Image.network(
              _singleMediaPath!,
              height: 200,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
            )
          else
            // Mobile/Desktop implementation - file path
            Image.file(
              File(_singleMediaPath!),
              height: 200,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Path: ${_singleMediaPath!.length > 50 ? '${_singleMediaPath!.substring(0, 50)}...' : _singleMediaPath!}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: _clearSingleMedia,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleMediaPreview() {
    if (_multipleMediaPaths.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Multiple Media Preview',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _multipleMediaPaths.length,
              itemBuilder: (context, index) {
                final path = _multipleMediaPaths[index];
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: kIsWeb || path.startsWith('data:')
                      ? Image.network(
                          path,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        )
                      : Image.file(
                          File(path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('${_multipleMediaPaths.length} files selected'),
          ),
          ElevatedButton(
            onPressed: _clearMultipleMedia,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    if (_filePath == null) return const SizedBox.shrink();

    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Single File Preview',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.description, size: 64),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'File: ${_filePath!.split('/').last}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Path: ${_filePath!.length > 50 ? '${_filePath!.substring(0, 50)}...' : _filePath!}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: _clearSingleFile,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleFilePreview() {
    if (_multipleFilePaths.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Multiple Files Preview',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: _multipleFilePaths.length,
              itemBuilder: (context, index) {
                final path = _multipleFilePaths[index];
                final fileName = path.split('/').last;
                return ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(fileName),
                  subtitle: Text(
                    path.length > 50 ? '${path.substring(0, 50)}...' : path,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('${_multipleFilePaths.length} files selected'),
          ),
          ElevatedButton(
            onPressed: _clearMultipleFiles,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Picker Plus Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdvancedExample(),
                ),
              );
            },
            tooltip: 'Advanced Examples',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Media Picker Plus'),
                  content: const Text(
                    'A comprehensive Flutter plugin for:\n\n'
                    '• Picking images and videos from gallery\n'
                    '• Capturing photos and recording videos\n'
                    '• Advanced watermarking for media\n'
                    '• File picking with extension filtering\n'
                    '• Multiple selection support\n'
                    '• Cross-platform: Android, iOS, macOS, Web\n'
                    '• Permission management\n'
                    '• Image resizing and quality control',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Single Media Operations
                  const Text(
                    'Single Media Operations',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pick Image'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.video_library),
                          label: const Text('Pick Video'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _capturePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Capture Photo'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _recordVideo,
                          icon: const Icon(Icons.videocam),
                          label: const Text('Record Video'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMediaPreview(),

                  const SizedBox(height: 32),

                  // Multiple Media Operations
                  const Text(
                    'Multiple Media Operations',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickMultipleImages,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Multiple Images'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickMultipleVideos,
                          icon: const Icon(Icons.video_library),
                          label: const Text('Multiple Videos'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMultipleMediaPreview(),

                  const SizedBox(height: 32),

                  // File Operations
                  const Text(
                    'File Operations',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder),
                          label: const Text('Pick File'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickMultipleFiles,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Multiple Files'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFilePreview(),
                  _buildMultipleFilePreview(),

                  const SizedBox(height: 32),

                  // Permission Operations
                  const Text(
                    'Permission Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _checkPermissions,
                          icon: const Icon(Icons.security),
                          label: const Text('Check Permissions'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _requestPermissions,
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Request Permissions'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Feature Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Features Demonstrated',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('✅ Image and video picking from gallery'),
                          const Text(
                              '✅ Camera photo capture and video recording'),
                          const Text(
                              '✅ Advanced watermarking with positioning'),
                          const Text('✅ Image quality control and resizing'),
                          const Text('✅ Multiple media selection'),
                          const Text('✅ File picking with extension filtering'),
                          const Text('✅ Permission management'),
                          const Text(
                              '✅ Cross-platform support (Android, iOS, macOS, Web)'),
                          const SizedBox(height: 16),
                          const Text(
                            'Platform Support',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Current Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}'),
                          const Text(
                              '• Android: Full support with advanced features'),
                          const Text(
                              '• iOS: Full support with advanced features'),
                          const Text(
                              '• macOS: Full support with advanced features'),
                          const Text('• Web: Full support with HTML5 APIs'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
