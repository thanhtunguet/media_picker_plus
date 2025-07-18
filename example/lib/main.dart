import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';

import 'media_preview_widgets.dart';

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
      home: const AdvancedMediaPickerExample(),
    );
  }
}

class AdvancedMediaPickerExample extends StatefulWidget {
  const AdvancedMediaPickerExample({super.key});

  @override
  State<AdvancedMediaPickerExample> createState() =>
      _AdvancedMediaPickerExampleState();
}

class _AdvancedMediaPickerExampleState
    extends State<AdvancedMediaPickerExample> {
  // Media Results
  String? _singleMediaPath;
  List<String> _multipleMediaPaths = [];
  String? _filePath;
  List<String> _multipleFilePaths = [];
  bool _isLoading = false;

  // Settings
  int _imageQuality = 85;
  int _maxWidth = 2560;
  int _maxHeight = 1440;
  double _watermarkFontSize = 32;
  String _watermarkPosition = WatermarkPosition.bottomRight;
  int _maxDurationMinutes = 5;
  String _customWatermark = 'Media Picker Plus';
  bool _enableImageResize = true;
  
  // Crop Settings
  bool _enableCrop = false;
  double? _cropAspectRatio;
  String _cropPreset = 'none';

  // Permission states
  bool _hasCameraPermission = false;
  bool _hasGalleryPermission = false;

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  /// Check all required permissions
  Future<void> _checkAllPermissions() async {
    try {
      final cameraPermission = await MediaPickerPlus.hasCameraPermission();
      final galleryPermission = await MediaPickerPlus.hasGalleryPermission();

      setState(() {
        _hasCameraPermission = cameraPermission == true;
        _hasGalleryPermission = galleryPermission == true;
      });
    } catch (e) {
      _showError('Error checking permissions: $e');
    }
  }

  /// Generate current MediaOptions based on settings
  MediaOptions get _currentOptions => MediaOptions(
        imageQuality: _imageQuality,
        maxWidth: _enableImageResize ? _maxWidth : null,
        maxHeight: _enableImageResize ? _maxHeight : null,
        watermark: _customWatermark,
        watermarkFontSize: _watermarkFontSize,
        watermarkPosition: _watermarkPosition,
        maxDuration: Duration(minutes: _maxDurationMinutes),
        cropOptions: _enableCrop ? CropOptions(
          enableCrop: true,
          aspectRatio: _cropAspectRatio,
          freeform: _cropAspectRatio == null,
          showGrid: true,
          lockAspectRatio: _cropAspectRatio != null,
        ) : null,
      );

  /// Generate MediaOptions with custom watermark
  MediaOptions _getOptionsWithWatermark(String watermark) => MediaOptions(
        imageQuality: _imageQuality,
        maxWidth: _enableImageResize ? _maxWidth : null,
        maxHeight: _enableImageResize ? _maxHeight : null,
        watermark: watermark,
        watermarkFontSize: _watermarkFontSize,
        watermarkPosition: _watermarkPosition,
        maxDuration: Duration(minutes: _maxDurationMinutes),
        cropOptions: _enableCrop ? CropOptions(
          enableCrop: true,
          aspectRatio: _cropAspectRatio,
          freeform: _cropAspectRatio == null,
          showGrid: true,
          lockAspectRatio: _cropAspectRatio != null,
        ) : null,
      );

  /// Generate timestamp watermark
  String _generateTimestampWatermark() {
    final now = DateTime.now();
    return '$_customWatermark • ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// Set crop preset
  void _setCropPreset(String preset) {
    setState(() {
      _cropPreset = preset;
      switch (preset) {
        case 'square':
          _enableCrop = true;
          _cropAspectRatio = 1.0;
          break;
        case 'portrait':
          _enableCrop = true;
          _cropAspectRatio = 3.0 / 4.0;
          break;
        case 'landscape':
          _enableCrop = true;
          _cropAspectRatio = 4.0 / 3.0;
          break;
        case 'widescreen':
          _enableCrop = true;
          _cropAspectRatio = 16.0 / 9.0;
          break;
        case 'freeform':
          _enableCrop = true;
          _cropAspectRatio = null;
          break;
        case 'none':
        default:
          _enableCrop = false;
          _cropAspectRatio = null;
          break;
      }
    });
  }

  // Single Media Operations
  Future<void> _pickImage() async {
    setState(() => _isLoading = true);
    try {
      final path = await MediaPickerPlus.pickImage(
        options: _currentOptions,
        context: mounted ? context : null, // Pass context for interactive cropping
      );
      if (mounted) {
        setState(() {
          _singleMediaPath = path;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Error picking image: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickVideo() async {
    setState(() => _isLoading = true);
    try {
      final path = await MediaPickerPlus.pickVideo(
        options: _currentOptions,
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
      // Check camera permission first
      if (!_hasCameraPermission) {
        final granted = await MediaPickerPlus.requestCameraPermission();
        if (!granted) {
          _showError('Camera permission is required');
          return;
        }
        setState(() => _hasCameraPermission = true);
      }

      final path = await MediaPickerPlus.capturePhoto(
        options: _getOptionsWithWatermark(_generateTimestampWatermark()),
        context: mounted ? context : null, // Pass context for interactive cropping
      );
      if (mounted) {
        setState(() {
          _singleMediaPath = path;
        });
      }
    } catch (e) {
      _showError('Error capturing photo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recordVideo() async {
    setState(() => _isLoading = true);
    try {
      // Check camera permission first
      if (!_hasCameraPermission) {
        final granted = await MediaPickerPlus.requestCameraPermission();
        if (!granted) {
          _showError('Camera permission is required');
          return;
        }
        setState(() => _hasCameraPermission = true);
      }

      final path = await MediaPickerPlus.recordVideo(
        options: _getOptionsWithWatermark(_generateTimestampWatermark()),
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
        options:
            _getOptionsWithWatermark('$_customWatermark • Multiple Images'),
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
        options:
            _getOptionsWithWatermark('$_customWatermark • Multiple Videos'),
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
        allowedExtensions: [
          '.pdf',
          '.doc',
          '.docx',
          '.txt',
          '.csv',
          '.xlsx',
          '.pptx'
        ],
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
          '.xlsx',
          '.pptx',
          '.zip',
          '.json'
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
  Future<void> _requestCameraPermission() async {
    try {
      final granted = await MediaPickerPlus.requestCameraPermission();
      setState(() {
        _hasCameraPermission = granted == true;
      });
      _showMessage(
          granted ? 'Camera permission granted' : 'Camera permission denied');
    } catch (e) {
      _showError('Error requesting camera permission: $e');
    }
  }

  Future<void> _requestGalleryPermission() async {
    try {
      final granted = await MediaPickerPlus.requestGalleryPermission();
      setState(() {
        _hasGalleryPermission = granted == true;
      });
      _showMessage(
          granted ? 'Gallery permission granted' : 'Gallery permission denied');
    } catch (e) {
      _showError('Error requesting gallery permission: $e');
    }
  }

  Future<void> _requestAllPermissions() async {
    await _requestCameraPermission();
    await _requestGalleryPermission();
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionRow('Camera', _hasCameraPermission),
            _buildPermissionRow('Gallery', _hasGalleryPermission),
            const SizedBox(height: 16),
            const Text(
              'Note: Microphone permission for video recording is handled automatically.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestAllPermissions();
            },
            child: const Text('Request All'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String permission, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text('$permission: ${granted ? "Granted" : "Denied"}'),
        ],
      ),
    );
  }

  Widget _buildCropPresetChip(String label, String preset) {
    final isSelected = _cropPreset == preset;
    final isInteractive = preset == 'freeform' && isSelected;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isInteractive) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.touch_app,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _setCropPreset(preset);
        }
      },
      backgroundColor: isSelected ? Theme.of(context).primaryColor.withAlpha(51) : null,
      selectedColor: Theme.of(context).primaryColor.withAlpha(102),
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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

    final isVideo = _singleMediaPath!.toLowerCase().endsWith('.mp4') ||
        _singleMediaPath!.toLowerCase().endsWith('.mov');

    if (isVideo) {
      return EnhancedVideoPlayer(
        videoPath: _singleMediaPath!,
        title: 'Single Video Preview',
        onClear: _clearSingleMedia,
        maxWidth: _enableImageResize ? _maxWidth : null,
        maxHeight: _enableImageResize ? _maxHeight : null,
        resizeEnabled: _enableImageResize,
      );
    } else {
      return EnhancedImagePreview(
        imagePath: _singleMediaPath!,
        title: 'Single Image Preview',
        onClear: _clearSingleMedia,
        maxWidth: _enableImageResize ? _maxWidth : null,
        maxHeight: _enableImageResize ? _maxHeight : null,
        resizeEnabled: _enableImageResize,
      );
    }
  }

  Widget _buildMultipleMediaPreview() {
    if (_multipleMediaPaths.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(26),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.collections, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Multiple Media Preview',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: _clearMultipleMedia,
                  tooltip: 'Clear all',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _multipleMediaPaths.length,
              itemBuilder: (context, index) {
                final path = _multipleMediaPaths[index];
                final isVideo = path.toLowerCase().endsWith('.mp4') ||
                    path.toLowerCase().endsWith('.mov');
                return Container(
                  width: 120,
                  margin: const EdgeInsets.all(8),
                  child: isVideo
                      ? EnhancedVideoPlayer(
                          videoPath: path,
                          height: 100,
                          showControls: false,
                          autoPlay: false,
                          maxWidth: _enableImageResize ? _maxWidth : null,
                          maxHeight: _enableImageResize ? _maxHeight : null,
                          resizeEnabled: _enableImageResize,
                        )
                      : EnhancedImagePreview(
                          imagePath: path,
                          height: 100,
                          showControls: false,
                          maxWidth: _enableImageResize ? _maxWidth : null,
                          maxHeight: _enableImageResize ? _maxHeight : null,
                          resizeEnabled: _enableImageResize,
                        ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('${_multipleMediaPaths.length} files selected'),
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Media Picker Plus - Complete Example'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.photo_camera), text: 'Media'),
              Tab(icon: Icon(Icons.folder), text: 'Files'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.security,
                color: _hasCameraPermission && _hasGalleryPermission
                    ? Colors.green
                    : Colors.red,
              ),
              onPressed: _showPermissionDialog,
              tooltip: 'Permission Status',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showAboutDialog,
              tooltip: 'About',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildMediaTab(),
                  _buildFilesTab(),
                  _buildSettingsTab(),
                ],
              ),
      ),
    );
  }

  void _showAboutDialog() {
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
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Settings Summary
          Card(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Quality: $_imageQuality% | Resize: ${_enableImageResize ? "${_maxWidth}x$_maxHeight" : "Original"}'),
                  Text(
                      'Watermark: "$_customWatermark" (${_watermarkFontSize}px)'),
                  Text(
                      'Position: $_watermarkPosition | Duration: ${_maxDurationMinutes}min'),
                  Text(
                      'Crop: ${_enableCrop ? (_cropAspectRatio != null ? "Aspect ${_cropAspectRatio!.toStringAsFixed(2)}" : "Freeform") : "Disabled"}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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

          // Interactive Cropping Demo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.crop, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Interactive Cropping',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'When you select "Freeform" cropping, an interactive UI will appear '
                  'allowing you to manually adjust the crop area with drag handles, '
                  'aspect ratio controls, and real-time preview.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _setCropPreset('freeform'),
                  icon: const Icon(Icons.crop_free),
                  label: const Text('Try Interactive Cropping'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Crop Presets
          const Text(
            'Quick Crop Presets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildCropPresetChip('None', 'none'),
              _buildCropPresetChip('Square', 'square'),
              _buildCropPresetChip('Portrait 3:4', 'portrait'),
              _buildCropPresetChip('Landscape 4:3', 'landscape'),
              _buildCropPresetChip('Widescreen 16:9', 'widescreen'),
              _buildCropPresetChip('Freeform', 'freeform'),
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
        ],
      ),
    );
  }

  Widget _buildFilesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

          // Supported File Types
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Supported File Types',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Documents: .pdf, .doc, .docx, .txt, .csv'),
                  const Text('Spreadsheets: .xls, .xlsx'),
                  const Text('Presentations: .pptx'),
                  const Text('Archives: .zip'),
                  const Text('Data: .json'),
                  const SizedBox(height: 16),
                  const Text(
                    'Note: File types can be customized by modifying the allowedExtensions parameter.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Permission Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permission Management',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionRow('Camera', _hasCameraPermission),
                  _buildPermissionRow('Gallery', _hasGalleryPermission),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _checkAllPermissions,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _requestAllPermissions,
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Request All'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Media Options Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Media Options Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Image Resize Toggle
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Enable Image Resizing',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch(
                        value: _enableImageResize,
                        onChanged: (value) {
                          setState(() {
                            _enableImageResize = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _enableImageResize
                        ? 'Images will be resized to fit within the specified dimensions while preserving aspect ratio'
                        : 'Images will be kept at their original size',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Image Quality
                  Text('Image Quality: $_imageQuality%'),
                  Slider(
                    value: _imageQuality.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 90,
                    label: '$_imageQuality%',
                    onChanged: (value) {
                      setState(() {
                        _imageQuality = value.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Max Width (only show if resize is enabled)
                  if (_enableImageResize) ...[
                    Text('Max Width: $_maxWidth px'),
                    Slider(
                      value: _maxWidth.toDouble(),
                      min: 480,
                      max: 4096,
                      divisions: 36,
                      label: '$_maxWidth px',
                      onChanged: (value) {
                        setState(() {
                          _maxWidth = value.toInt();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Max Height
                    Text('Max Height: $_maxHeight px'),
                    Slider(
                      value: _maxHeight.toDouble(),
                      min: 480,
                      max: 4096,
                      divisions: 36,
                      label: '$_maxHeight px',
                      onChanged: (value) {
                        setState(() {
                          _maxHeight = value.toInt();
                        });
                      },
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.grey[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Image dimensions will not be modified. Original resolution will be preserved. The displayed file info shows the actual processed image dimensions.',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Watermark Text
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Watermark Text',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _customWatermark = value;
                      });
                    },
                    controller: TextEditingController(text: _customWatermark),
                  ),
                  const SizedBox(height: 16),

                  // Watermark Font Size
                  Text('Watermark Font Size: ${_watermarkFontSize.toInt()}px'),
                  Slider(
                    value: _watermarkFontSize,
                    min: 12,
                    max: 72,
                    divisions: 60,
                    label: '${_watermarkFontSize.toInt()}px',
                    onChanged: (value) {
                      setState(() {
                        _watermarkFontSize = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Watermark Position
                  const Text('Watermark Position:'),
                  DropdownButton<String>(
                    value: _watermarkPosition,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: WatermarkPosition.topLeft,
                          child: Text('Top Left')),
                      DropdownMenuItem(
                          value: WatermarkPosition.topCenter,
                          child: Text('Top Center')),
                      DropdownMenuItem(
                          value: WatermarkPosition.topRight,
                          child: Text('Top Right')),
                      DropdownMenuItem(
                          value: WatermarkPosition.middleLeft,
                          child: Text('Middle Left')),
                      DropdownMenuItem(
                          value: WatermarkPosition.middleCenter,
                          child: Text('Middle Center')),
                      DropdownMenuItem(
                          value: WatermarkPosition.middleRight,
                          child: Text('Middle Right')),
                      DropdownMenuItem(
                          value: WatermarkPosition.bottomLeft,
                          child: Text('Bottom Left')),
                      DropdownMenuItem(
                          value: WatermarkPosition.bottomCenter,
                          child: Text('Bottom Center')),
                      DropdownMenuItem(
                          value: WatermarkPosition.bottomRight,
                          child: Text('Bottom Right')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _watermarkPosition = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Crop Configuration
                  const Divider(),
                  const Text(
                    'Cropping Configuration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Enable Crop Toggle
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Enable Cropping',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch(
                        value: _enableCrop,
                        onChanged: (value) {
                          setState(() {
                            _enableCrop = value;
                            if (!value) {
                              _cropPreset = 'none';
                              _cropAspectRatio = null;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _enableCrop
                        ? 'Media will be cropped based on the selected aspect ratio or freeform'
                        : 'Media will not be cropped',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),

                  if (_enableCrop) ...[
                    const SizedBox(height: 16),
                    const Text('Crop Presets:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildCropPresetChip('Square', 'square'),
                        _buildCropPresetChip('Portrait 3:4', 'portrait'),
                        _buildCropPresetChip('Landscape 4:3', 'landscape'),
                        _buildCropPresetChip('Widescreen 16:9', 'widescreen'),
                        _buildCropPresetChip('Freeform', 'freeform'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current: ${_cropAspectRatio != null ? "Aspect ratio ${_cropAspectRatio!.toStringAsFixed(2)}" : "Freeform cropping"}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Max Duration
                  Text('Max Video Duration: $_maxDurationMinutes minutes'),
                  Slider(
                    value: _maxDurationMinutes.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$_maxDurationMinutes min',
                    onChanged: (value) {
                      setState(() {
                        _maxDurationMinutes = value.toInt();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Feature Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Features Demonstrated',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('✅ Image and video picking from gallery'),
                  const Text('✅ Camera photo capture and video recording'),
                  const Text('✅ Advanced watermarking with positioning'),
                  const Text('✅ Image quality control and optional resizing'),
                  const Text('✅ Media cropping with aspect ratio control'),
                  const Text('✅ Configurable resize settings (enable/disable)'),
                  const Text('✅ Multiple media selection'),
                  const Text('✅ File picking with extension filtering'),
                  const Text('✅ Permission management'),
                  const Text('✅ Real-time settings configuration'),
                  const Text(
                      '✅ Cross-platform support (Android, iOS, macOS, Web)'),
                  const SizedBox(height: 16),
                  const Text(
                    'Platform Support',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Current Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}'),
                  const Text('• Android: Full support with advanced features'),
                  const Text('• iOS: Full support with advanced features'),
                  const Text('• macOS: Full support with advanced features'),
                  const Text('• Web: Full support with HTML5 APIs'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
