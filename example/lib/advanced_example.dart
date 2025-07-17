import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';

import 'media_preview_widgets.dart';

/// Advanced example demonstrating timestamp watermarking and microphone permissions
class AdvancedExample extends StatefulWidget {
  const AdvancedExample({super.key});

  @override
  State<AdvancedExample> createState() => _AdvancedExampleState();
}

class _AdvancedExampleState extends State<AdvancedExample> {
  String? _timestampedImagePath;
  String? _timestampedVideoPath;
  bool _isLoading = false;

  // Permission states
  bool _hasCameraPermission = false;
  bool _hasGalleryPermission = false;

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  /// Generate a formatted timestamp for watermarking
  String _generateTimestamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  /// Generate a detailed timestamp with timezone
  String _generateDetailedTimestamp() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year} • '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  /// Pick image with timestamp watermark
  Future<void> _pickImageWithTimestamp() async {
    setState(() => _isLoading = true);
    try {
      final timestamp = _generateTimestamp();

      final path = await MediaPickerPlus.pickImage(
        options: MediaOptions(
          imageQuality: 90,
          maxWidth: 2560,
          maxHeight: 1440,
          watermark: 'PICKED: $timestamp',
          watermarkFontSize: 48,
          watermarkPosition: WatermarkPosition.bottomRight,
        ),
      );

      setState(() {
        _timestampedImagePath = path;
      });
      if (path != null) {
        _showSuccessMessage('Image picked and watermarked with timestamp');
      }
    } catch (e) {
      _showError('Error picking image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Capture photo with detailed timestamp watermark
  Future<void> _capturePhotoWithTimestamp() async {
    setState(() => _isLoading = true);

    try {
      // Check camera permission with robust error handling
      bool hasCameraAccess = false;
      try {
        hasCameraAccess = await MediaPickerPlus.hasCameraPermission();
      } catch (e) {
        _showError('Error checking camera permission: $e');
        return;
      }

      if (!hasCameraAccess) {
        try {
          hasCameraAccess = await MediaPickerPlus.requestCameraPermission();
        } catch (e) {
          _showError('Error requesting camera permission: $e');
          return;
        }

        if (!hasCameraAccess) {
          _showError('Camera permission is required to capture photos');
          return;
        }
      }

      final detailedTimestamp = _generateDetailedTimestamp();

      final path = await MediaPickerPlus.capturePhoto(
        options: MediaOptions(
          imageQuality: 95,
          maxWidth: 2560,
          maxHeight: 1440,
          watermark: 'CAPTURED: $detailedTimestamp',
          watermarkFontSize: 56,
          watermarkPosition: WatermarkPosition.bottomCenter,
        ),
      );

      setState(() {
        _timestampedImagePath = path;
        _hasCameraPermission = hasCameraAccess;
      });

      if (path != null) {
        _showSuccessMessage('Photo captured with timestamp watermark');
      }
    } catch (e) {
      _showError('Error capturing photo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Record video with timestamp and permission check
  Future<void> _recordVideoWithTimestamp() async {
    setState(() => _isLoading = true);

    try {
      // Check required permissions with robust error handling
      bool hasCameraAccess = false;
      try {
        hasCameraAccess = await MediaPickerPlus.hasCameraPermission();
      } catch (e) {
        _showError('Error checking camera permission: $e');
        return;
      }

      if (!hasCameraAccess) {
        try {
          hasCameraAccess = await MediaPickerPlus.requestCameraPermission();
        } catch (e) {
          _showError('Error requesting camera permission: $e');
          return;
        }

        if (!hasCameraAccess) {
          _showError('Camera permission is required to record video');
          return;
        }
      }

      // Show microphone permission info dialog
      final shouldContinue = await _showMicrophonePermissionDialog();
      if (!shouldContinue) return;

      final timestamp = _generateDetailedTimestamp();

      final path = await MediaPickerPlus.recordVideo(
        options: MediaOptions(
          maxWidth: 2560,
          maxHeight: 1440,
          watermark: 'RECORDED: $timestamp',
          watermarkFontSize: 64,
          watermarkPosition: WatermarkPosition.topLeft,
          maxDuration: const Duration(minutes: 5),
        ),
      );

      setState(() {
        _timestampedVideoPath = path;
        _hasCameraPermission = hasCameraAccess;
      });

      if (path != null) {
        _showSuccessMessage('Video recorded with timestamp watermark');
      }
    } catch (e) {
      _showError('Error recording video: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Pick video with custom timestamp format
  Future<void> _pickVideoWithCustomTimestamp() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      final customFormat =
          '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day} • '
          '${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:'
          '${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
      final path = await MediaPickerPlus.pickVideo(
        options: MediaOptions(
          maxWidth: 2560,
          maxHeight: 1440,
          watermark: '🎥 Selected: $customFormat',
          watermarkFontSize: 22,
          watermarkPosition: WatermarkPosition.topRight,
          maxDuration: const Duration(minutes: 10),
        ),
      );
      setState(() {
        _timestampedVideoPath = path;
      });
      if (path != null) {
        _showSuccessMessage('Video picked with custom timestamp format');
      }
    } catch (e) {
      _showError('Error picking video: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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

  /// Request camera permission
  Future<void> _requestCameraPermission() async {
    try {
      final granted = await MediaPickerPlus.requestCameraPermission();
      setState(() {
        _hasCameraPermission = granted == true;
      });
    } catch (e) {
      _showError('Error requesting camera permission: $e');
    }
  }

  /// Request gallery permission
  Future<void> _requestGalleryPermission() async {
    try {
      final granted = await MediaPickerPlus.requestGalleryPermission();
      setState(() {
        _hasGalleryPermission = granted == true;
      });
    } catch (e) {
      _showError('Error requesting gallery permission: $e');
    }
  }

  /// Show microphone permission dialog
  Future<bool> _showMicrophonePermissionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Info'),
        content: const Text(
          'For video recording with audio, the app will automatically request microphone permission when needed. '
          'On some platforms, audio recording may require additional permissions to be granted manually in device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue Recording'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show comprehensive permission status
  Future<void> _showPermissionStatus() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionStatusRow('Camera', _hasCameraPermission),
            _buildPermissionStatusRow('Gallery', _hasGalleryPermission),
            const SizedBox(height: 16),
            const Text(
              'Note: Microphone permission for video recording is handled automatically by the system when recording starts.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            const Text(
              'Additional permissions may be required on some platforms and will be requested as needed.',
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
            child: const Text('Request Available'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStatusRow(String permission, bool granted) {
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

  /// Request all permissions
  Future<void> _requestAllPermissions() async {
    await _requestCameraPermission();
    await _requestGalleryPermission();

    _showSuccessMessage(
        'Available permission requests completed. Check status for results.');
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

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'INFO',
          textColor: Colors.white,
          onPressed: () {
            if (_timestampedImagePath != null ||
                _timestampedVideoPath != null) {
              _showMediaInfo();
            }
          },
        ),
      ),
    );
  }

  void _showMediaInfo() {
    final imagePath = _timestampedImagePath;
    final videoPath = _timestampedVideoPath;

    String info = 'Media Information:\n\n';
    if (imagePath != null) {
      info += 'Image: ${imagePath.split('/').last}\n';
      info += 'Max Resolution: 2560x1440 (1440p)\n';
      info += 'Watermark: Large font size (56px)\n';
      info += 'Full path: $imagePath\n\n';
    }
    if (videoPath != null) {
      info += 'Video: ${videoPath.split('/').last}\n';
      info += 'Max Resolution: 2560x1440 (1440p)\n';
      info += 'Watermark: Large font size (64px)\n';
      info += 'Full path: $videoPath\n\n';
    }
    info += 'Media is resized to 1440p before watermarking.\n';
    info += 'Watermarks should be clearly visible.\n';
    info += 'Check the preview widgets below to verify.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media Information'),
        content: SingleChildScrollView(
          child: Text(info),
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

  Widget _buildTimestampedMediaPreview() {
    if (_timestampedImagePath == null && _timestampedVideoPath == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.preview, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: const Text(
                'Media Preview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            if (_timestampedImagePath != null || _timestampedVideoPath != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _timestampedImagePath = null;
                    _timestampedVideoPath = null;
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All'),
              ),
          ],
        ),

        // Image Preview
        if (_timestampedImagePath != null) ...[
          EnhancedImagePreview(
            imagePath: _timestampedImagePath!,
            title: '📸 Timestamped Image Preview',
            height: 320,
            onClear: () => setState(() => _timestampedImagePath = null),
          ),
          const SizedBox(height: 16),
        ],

        // Video Preview
        if (_timestampedVideoPath != null) ...[
          EnhancedVideoPlayer(
            videoPath: _timestampedVideoPath!,
            title: '🎬 Timestamped Video Preview',
            height: 320,
            autoPlay: false,
            onClear: () => setState(() => _timestampedVideoPath = null),
          ),
          const SizedBox(height: 16),
        ],

        // Feature highlights
        if (_timestampedImagePath != null || _timestampedVideoPath != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✨ Enhanced Preview Features',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('🔍 Zoom and pan support for images'),
                  const Text('🎮 Full video player controls'),
                  const Text('📱 Fullscreen viewing mode'),
                  const Text('ℹ️ Detailed media information'),
                  const Text('💧 Watermark visualization'),
                  const Text('🎯 Cross-platform compatibility'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Media Picker Example'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.security,
              color: _hasCameraPermission && _hasGalleryPermission
                  ? Colors.green
                  : Colors.red,
            ),
            onPressed: _showPermissionStatus,
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
                  // Timestamp Watermarking Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🕒 Timestamp Watermarking',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Automatically add current date and time as watermark',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickImageWithTimestamp,
                                  icon: const Icon(Icons.image),
                                  label: const Text('Pick Image'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _capturePhotoWithTimestamp,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Capture Photo'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickVideoWithCustomTimestamp,
                                  icon: const Icon(Icons.video_library),
                                  label: const Text('Pick Video'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _recordVideoWithTimestamp,
                                  icon: const Icon(Icons.videocam),
                                  label: const Text('Record Video'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Permission Management Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🔒 Advanced Permission Management',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Smart permission checking with automatic microphone handling for video recording',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          _buildPermissionStatusRow(
                              'Camera', _hasCameraPermission),
                          _buildPermissionStatusRow(
                              'Gallery', _hasGalleryPermission),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      'Microphone: Auto-requested for video recording'),
                                ),
                              ],
                            ),
                          ),
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

                  // Preview Section
                  _buildTimestampedMediaPreview(),

                  const SizedBox(height: 16),

                  // Features Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✨ Advanced Features Demonstrated',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text('🕒 Automatic timestamp watermarking'),
                          const Text(
                              '📱 Custom timestamp formats (multiple styles)'),
                          const Text('🎤 Smart microphone permission handling'),
                          const Text('🔒 Intelligent permission management'),
                          const Text(
                              '⚡ Automatic permission flow for video recording'),
                          const Text('🎨 Dynamic watermark positioning'),
                          const Text(
                              '📋 Real-time permission status monitoring'),
                          const SizedBox(height: 16),
                          const Text(
                            '💡 Tips:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                              '• Timestamps are generated in real-time with multiple format options'),
                          const Text(
                              '• Microphone permissions are handled transparently by the system'),
                          const Text(
                              '• Permission status shows with intuitive color-coded indicators'),
                          const Text(
                              '• Custom timestamp formats: ISO, detailed, and conversational styles'),
                          const Text(
                              '• Smart permission flows prevent interrupting user experience'),
                          const Text(
                              '• Automatic fallback handling for denied permissions'),
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
