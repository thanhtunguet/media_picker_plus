import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';

import '../widgets/media_preview_widget.dart';
import '../widgets/permission_status_widget.dart';

class CameraFeature extends StatefulWidget {
  const CameraFeature({super.key});

  @override
  State<CameraFeature> createState() => _CameraFeatureState();
}

class _CameraFeatureState extends State<CameraFeature> {
  String? _capturedMediaPath;
  bool _isLoading = false;
  bool _hasCameraPermission = false;

  // Camera settings
  int _imageQuality = 85;
  bool _usePercentageFontSize = true; // Default to percentage-based
  double _watermarkFontSize = 32;
  double _watermarkFontSizePercentage = 4.0; // 4% of shorter edge
  final String _watermarkPosition = WatermarkPosition.bottomRight;
  final int _maxDurationMinutes = 5;
  String _customWatermark = 'Media Picker Plus';

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    try {
      final permission = await MediaPickerPlus.hasCameraPermission();
      setState(() => _hasCameraPermission = permission == true);
    } catch (e) {
      _showError('Error checking camera permission: $e');
    }
  }

  MediaOptions get _currentOptions => MediaOptions(
        imageQuality: _imageQuality,
        watermark: _generateTimestampWatermark(),
        watermarkFontSize: _usePercentageFontSize ? null : _watermarkFontSize,
        watermarkFontSizePercentage:
            _usePercentageFontSize ? _watermarkFontSizePercentage : null,
        watermarkPosition: _watermarkPosition,
        maxDuration: Duration(minutes: _maxDurationMinutes),
      );

  String _generateTimestampWatermark() {
    final now = DateTime.now();
    return '$_customWatermark • ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _requestCameraPermission() async {
    try {
      final granted = await MediaPickerPlus.requestCameraPermission();
      setState(() => _hasCameraPermission = granted == true);
      _showMessage(
          granted ? 'Camera permission granted' : 'Camera permission denied');
    } catch (e) {
      _showError('Error requesting camera permission: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (!_hasCameraPermission) {
      final granted = await MediaPickerPlus.requestCameraPermission();
      if (!granted) {
        _showError('Camera permission is required');
        return;
      }
      setState(() => _hasCameraPermission = true);
    }

    setState(() => _isLoading = true);
    try {
      final path = await MediaPickerPlus.capturePhoto(
        options: _currentOptions,
        context: mounted ? context : null,
      );
      if (mounted) {
        setState(() => _capturedMediaPath = path);
      }
    } catch (e) {
      _showError('Error capturing photo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recordVideo() async {
    if (!_hasCameraPermission) {
      final granted = await MediaPickerPlus.requestCameraPermission();
      if (!granted) {
        _showError('Camera permission is required');
        return;
      }
      setState(() => _hasCameraPermission = true);
    }

    setState(() => _isLoading = true);
    try {
      final path = await MediaPickerPlus.recordVideo(options: _currentOptions);
      setState(() => _capturedMediaPath = path);
    } catch (e) {
      _showError('Error recording video: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _clearMedia() => setState(() => _capturedMediaPath = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera & Recording'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Permission Status
                  PermissionStatusWidget(
                    hasCameraPermission: _hasCameraPermission,
                    onRequestPermission: _requestCameraPermission,
                  ),

                  // Camera Settings
                  Container(
                    margin: const EdgeInsets.all(8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Camera Settings',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Quality: $_imageQuality%'),
                                  Slider(
                                    value: _imageQuality.toDouble(),
                                    min: 10,
                                    max: 100,
                                    divisions: 90,
                                    onChanged: (value) => setState(
                                        () => _imageQuality = value.toInt()),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: const Text('Percentage-Based Font Size'),
                                subtitle: Text(
                                  _usePercentageFontSize
                                      ? 'Scales with media dimensions'
                                      : 'Fixed pixel size',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                value: _usePercentageFontSize,
                                onChanged: (value) {
                                  setState(
                                      () => _usePercentageFontSize = value);
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_usePercentageFontSize
                                      ? 'Font Size: ${_watermarkFontSizePercentage.toStringAsFixed(1)}%'
                                      : 'Font Size: ${_watermarkFontSize.toInt()}px'),
                                  if (_usePercentageFontSize)
                                    Slider(
                                      value: _watermarkFontSizePercentage,
                                      min: 1,
                                      max: 20,
                                      divisions: 190,
                                      onChanged: (value) => setState(() =>
                                          _watermarkFontSizePercentage = value),
                                    )
                                  else
                                    Slider(
                                      value: _watermarkFontSize,
                                      min: 12,
                                      max: 72,
                                      divisions: 60,
                                      onChanged: (value) => setState(
                                          () => _watermarkFontSize = value),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Watermark Text',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) =>
                                    setState(() => _customWatermark = value),
                                controller: TextEditingController(
                                    text: _customWatermark),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _hasCameraPermission ? _capturePhoto : null,
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text('Capture Photo',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _hasCameraPermission ? _recordVideo : null,
                            icon: const Icon(Icons.videocam, size: 18),
                            label: const Text('Record Video',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Preview Section
                  Container(
                    child: _capturedMediaPath != null
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(8),
                            child: MediaPreviewWidget(
                              mediaPath: _capturedMediaPath!,
                              title: 'Captured Media Preview',
                              onClear: _clearMedia,
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No media captured yet',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap capture or record to get started',
                                  style: TextStyle(color: Colors.grey),
                                ),
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
