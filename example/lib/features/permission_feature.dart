import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';

class PermissionFeature extends StatefulWidget {
  const PermissionFeature({super.key});

  @override
  State<PermissionFeature> createState() => _PermissionFeatureState();
}

class _PermissionFeatureState extends State<PermissionFeature> {
  bool _hasCameraPermission = false;
  bool _hasGalleryPermission = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    setState(() => _isLoading = true);
    try {
      final cameraPermission = await MediaPickerPlus.hasCameraPermission();
      final galleryPermission = await MediaPickerPlus.hasGalleryPermission();

      setState(() {
        _hasCameraPermission = cameraPermission == true;
        _hasGalleryPermission = galleryPermission == true;
      });
    } catch (e) {
      _showError('Error checking permissions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestCameraPermission() async {
    setState(() => _isLoading = true);
    try {
      final granted = await MediaPickerPlus.requestCameraPermission();
      setState(() => _hasCameraPermission = granted == true);
      _showMessage(granted ? 'Camera permission granted' : 'Camera permission denied');
    } catch (e) {
      _showError('Error requesting camera permission: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestGalleryPermission() async {
    setState(() => _isLoading = true);
    try {
      final granted = await MediaPickerPlus.requestGalleryPermission();
      setState(() => _hasGalleryPermission = granted == true);
      _showMessage(granted ? 'Gallery permission granted' : 'Gallery permission denied');
    } catch (e) {
      _showError('Error requesting gallery permission: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestAllPermissions() async {
    await _requestCameraPermission();
    await _requestGalleryPermission();
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

  Widget _buildPermissionCard(String title, bool granted, VoidCallback onRequest) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  granted ? Icons.check_circle : Icons.cancel,
                  color: granted ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        granted ? 'Granted' : 'Required',
                        style: TextStyle(
                          color: granted ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: granted ? null : onRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: granted ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(granted ? 'Already Granted' : 'Request Permission'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSummary() {
    final allGranted = _hasCameraPermission && _hasGalleryPermission;
    return Card(
      color: allGranted ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              allGranted ? Icons.security : Icons.warning,
              size: 48,
              color: allGranted ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              allGranted ? 'All Permissions Granted' : 'Some Permissions Missing',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: allGranted ? Colors.green.shade700 : Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              allGranted
                  ? 'You can use all features of Media Picker Plus'
                  : 'Request missing permissions to unlock all features',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: allGranted ? Colors.green.shade600 : Colors.orange.shade600,
              ),
            ),
            if (!allGranted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _requestAllPermissions,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Request All Permissions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Permission Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('📷 Camera Permission:', style: TextStyle(fontWeight: FontWeight.w500)),
            const Text('Required for capturing photos and recording videos directly from the camera.'),
            const SizedBox(height: 8),
            const Text('🖼️ Gallery Permission:', style: TextStyle(fontWeight: FontWeight.w500)),
            const Text('Required for accessing and selecting images/videos from device gallery.'),
            const SizedBox(height: 8),
            const Text('🎤 Microphone Permission:', style: TextStyle(fontWeight: FontWeight.w500)),
            const Text('Automatically handled when recording videos with audio.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                'Note: Permissions are required only for specific features. '
                'You can still use file picking and other features without camera/gallery permissions.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAllPermissions,
            tooltip: 'Refresh permissions',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Permission Summary
                  _buildPermissionSummary(),
                  const SizedBox(height: 16),

                  // Individual Permission Cards
                  _buildPermissionCard(
                    'Camera Permission',
                    _hasCameraPermission,
                    _requestCameraPermission,
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionCard(
                    'Gallery Permission',
                    _hasGalleryPermission,
                    _requestGalleryPermission,
                  ),
                  const SizedBox(height: 16),

                  // Permission Information
                  _buildPermissionInfo(),
                ],
              ),
            ),
    );
  }
}