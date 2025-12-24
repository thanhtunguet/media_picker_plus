import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

class CamerAwesomeFeature extends StatefulWidget {
  const CamerAwesomeFeature({super.key});

  @override
  State<CamerAwesomeFeature> createState() => _CamerAwesomeFeatureState();
}

class _CamerAwesomeFeatureState extends State<CamerAwesomeFeature> {
  final List<String> _capturedPhotos = [];
  bool _isWatermarking = false;

  Widget _buildCapturedPhotosGrid() {
    if (_capturedPhotos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No photos captured yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use CamerAwesome to capture photos',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Captured Photos (${_capturedPhotos.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _capturedPhotos.length,
                itemBuilder: (context, index) {
                  final photoPath = _capturedPhotos[index];
                  return GestureDetector(
                    onTap: () => _viewPhoto(photoPath),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(photoPath),
                                fit: BoxFit.cover,
                                width: 100,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: () => _applyWatermark(photoPath),
                                icon: const Icon(Icons.branding_watermark,
                                    size: 16),
                                tooltip: 'Add Watermark',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deletePhoto(index),
                                icon: const Icon(Icons.delete, size: 16),
                                tooltip: 'Delete',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _capturedPhotos.isEmpty
                        ? null
                        : () => _applyWatermarkToAll(),
                    icon: _isWatermarking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.branding_watermark),
                    label: Text(_isWatermarking
                        ? 'Adding Watermarks...'
                        : 'Watermark All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _capturedPhotos.isEmpty
                        ? null
                        : () => _clearAllPhotos(),
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Third-Party Camera + Watermark Demo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '📸 Uses camera package for real third-party integration',
            ),
            const Text(
              '🏷️ Applies watermarks using MediaPickerPlus',
            ),
            const Text(
              '🎛️ Demonstrates post-capture processing workflow',
            ),
            const Text(
              '💧 Shows how to integrate with any camera library',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                'This demo shows real integration between the camera package and MediaPickerPlus watermarking. '
                'Capture photos with custom camera UI, then apply watermarks using MediaPickerPlus.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyWatermark(String imagePath) async {
    setState(() => _isWatermarking = true);

    try {
      final watermarkedPath = await MediaPickerPlus.addWatermarkToImage(
        imagePath,
        options: const MediaOptions(
          watermark: 'Third-Party Camera + MediaPickerPlus',
          watermarkFontSize: 20,
          watermarkPosition: WatermarkPosition.bottomRight,
        ),
      );

      if (watermarkedPath != null && mounted) {
        // Replace the original with watermarked version
        final originalIndex = _capturedPhotos.indexOf(imagePath);
        if (originalIndex != -1) {
          setState(() {
            _capturedPhotos[originalIndex] = watermarkedPath;
          });
        }

        _showMessage('Watermark applied successfully!');
      }
    } catch (e) {
      _showError('Failed to apply watermark: $e');
    } finally {
      setState(() => _isWatermarking = false);
    }
  }

  Future<void> _applyWatermarkToAll() async {
    if (_capturedPhotos.isEmpty) return;

    setState(() => _isWatermarking = true);

    try {
      for (int i = 0; i < _capturedPhotos.length; i++) {
        final imagePath = _capturedPhotos[i];
        final watermarkedPath = await MediaPickerPlus.addWatermarkToImage(
          imagePath,
          options: MediaOptions(
            watermark: '3rd Party Batch #${i + 1}',
            watermarkFontSize: 18,
            watermarkPosition: WatermarkPosition.bottomRight,
          ),
        );

        if (watermarkedPath != null && mounted) {
          setState(() {
            _capturedPhotos[i] = watermarkedPath;
          });
        }
      }

      if (mounted) {
        _showMessage('Watermarks applied to all photos!');
      }
    } catch (e) {
      _showError('Failed to apply watermarks: $e');
    } finally {
      setState(() => _isWatermarking = false);
    }
  }

  void _deletePhoto(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _capturedPhotos.removeAt(index);
              });
              _showMessage('Photo deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearAllPhotos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Photos'),
        content: const Text('Are you sure you want to delete all photos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _capturedPhotos.clear();
              });
              _showMessage('All photos cleared');
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewPhoto(String photoPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Photo Viewer'),
            actions: [
              IconButton(
                onPressed: () {
                  _applyWatermark(photoPath);
                  Navigator.of(context).pop(); // Return after watermarking
                },
                icon: const Icon(Icons.branding_watermark),
                tooltip: 'Add Watermark',
              ),
            ],
          ),
          body: PhotoView(
            imageProvider: FileImage(File(photoPath)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            initialScale: PhotoViewComputedScale.contained,
            heroAttributes: PhotoViewHeroAttributes(tag: photoPath),
          ),
        ),
      ),
    );
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

  Future<void> _openCamerAwesome() async {
    try {
      if (!mounted) return;

      // Open third-party camera (using camera package)
      final String? capturedPath = await Navigator.of(context).push<String?>(
        MaterialPageRoute(
          builder: (context) => const ThirdPartyCameraPage(),
        ),
      );

      if (capturedPath != null && mounted) {
        setState(() {
          _capturedPhotos.insert(0, capturedPath); // Add to beginning
        });
        _showMessage(
            'Photo captured with third-party camera! Ready for watermarking.');
      }
    } catch (e) {
      _showError('Failed to open third-party camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Third-Party Camera Demo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _openCamerAwesome,
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Capture Photo',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildCapturedPhotosGrid(),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamerAwesome,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class ThirdPartyCameraPage extends StatefulWidget {
  const ThirdPartyCameraPage({super.key});

  @override
  State<ThirdPartyCameraPage> createState() => _ThirdPartyCameraPageState();
}

class _ThirdPartyCameraPageState extends State<ThirdPartyCameraPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No cameras available');
        return;
      }

      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      setState(() => _error = 'Failed to initialize camera: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() => _isCapturing = true);

    try {
      final image = await _controller!.takePicture();

      // Save to app documents directory with unique name
      final directory = await getApplicationDocumentsDirectory();
      final thirdPartyDir = Directory('${directory.path}/third_party_camera');
      if (!await thirdPartyDir.exists()) {
        await thirdPartyDir.create(recursive: true);
      }

      final fileName =
          'third_party_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${thirdPartyDir.path}/$fileName';

      // Copy the captured image to our directory
      await File(image.path).copy(savedPath);

      if (mounted) {
        Navigator.of(context).pop(savedPath);
      }
    } catch (e) {
      setState(() => _error = 'Failed to capture photo: $e');
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;

    final currentIndex = _cameras.indexOf(_controller!.description);
    final nextIndex = (currentIndex + 1) % _cameras.length;

    await _controller?.dispose();

    _controller = CameraController(
      _cameras[nextIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return CameraPreview(_controller!);
  }

  Widget _buildControls() {
    return Container(
      height: 120,
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Switch camera button
          IconButton(
            onPressed: _cameras.length > 1 ? _switchCamera : null,
            icon: const Icon(
              Icons.flip_camera_android,
              color: Colors.white,
              size: 32,
            ),
          ),

          // Capture button
          GestureDetector(
            onTap: _isCapturing ? null : _capturePhoto,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: _isCapturing ? Colors.grey : Colors.transparent,
              ),
              child: _isCapturing
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 100,
      color: Colors.black87,
      padding: const EdgeInsets.only(top: 40),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_enhance,
            color: Colors.deepPurple,
            size: 24,
          ),
          SizedBox(width: 8),
          Text(
            'Third-Party Camera',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildCameraPreview(),
                ),
                _buildControls(),
              ],
            ),
    );
  }
}
