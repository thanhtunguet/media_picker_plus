import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';

import 'features/camera_feature.dart';
import 'features/camerawesome_feature.dart';
import 'features/file_picker_feature.dart';
import 'features/media_picker_feature.dart';
import 'features/permission_feature.dart';
import 'features/watermark_feature.dart';

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
        useMaterial3: true,
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

class _MediaPickerExampleState extends State<MediaPickerExample>
    with WidgetsBindingObserver {
  bool _hasCameraPermission = false;
  bool _hasGalleryPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh permissions when app becomes active (user might have changed permissions in system settings)
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final cameraPermission = await MediaPickerPlus.hasCameraPermission();
      final galleryPermission = await MediaPickerPlus.hasGalleryPermission();

      if (mounted) {
        setState(() {
          _hasCameraPermission = cameraPermission == true;
          _hasGalleryPermission = galleryPermission == true;
        });
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
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
          '• Interactive cropping with manual selection\n'
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

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool? requiresPermission,
    bool? hasPermission,
  }) {
    final needsPermission = requiresPermission == true && hasPermission != true;

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withAlpha(51),
                    child: Icon(
                      icon,
                      size: 24,
                      color: color,
                    ),
                  ),
                  if (needsPermission)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (needsPermission) ...[
                const SizedBox(height: 6),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Text(
                      'Permission Required',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformInfo() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Platform Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
                'Current Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}'),
            const SizedBox(height: 4),
            const Text('✅ Android: Full support with advanced features'),
            const Text('✅ iOS: Full support with advanced features'),
            const Text('✅ macOS: Full support with advanced features'),
            const Text('✅ Web: Full support with HTML5 APIs'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Picker Plus'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.security,
              color: _hasCameraPermission && _hasGalleryPermission
                  ? Colors.green
                  : Colors.orange,
            ),
            onPressed: () async {
              // Navigate to permissions page and refresh when returning
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const PermissionFeature()),
              );
              // Refresh permissions when returning from permissions page
              _checkPermissions();
            },
            tooltip: 'Permission Status',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissions,
            tooltip: 'Refresh Permissions',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showAboutDialog,
            tooltip: 'About',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkPermissions,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even when content doesn't scroll
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withAlpha(204),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Media Picker Plus',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Comprehensive media picking plugin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Features Grid
              const Text(
                'Features',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  final childAspectRatio =
                      constraints.maxWidth > 600 ? 1.1 : 0.9;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _buildFeatureCard(
                        title: 'Media Picker',
                        description: 'Pick images & videos with processing',
                        icon: Icons.photo_library,
                        color: Colors.blue,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) =>
                                    const MediaPickerFeature()),
                          );
                          _checkPermissions(); // Refresh permissions when returning
                        },
                        requiresPermission: true,
                        hasPermission: _hasGalleryPermission,
                      ),
                      _buildFeatureCard(
                        title: 'Camera & Recording',
                        description: 'Capture photos & record videos',
                        icon: Icons.camera_alt,
                        color: Colors.green,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const CameraFeature()),
                          );
                          _checkPermissions(); // Refresh permissions when returning
                        },
                        requiresPermission: true,
                        hasPermission: _hasCameraPermission,
                      ),
                      _buildFeatureCard(
                        title: 'File Picker',
                        description: 'Select documents & files',
                        icon: Icons.folder,
                        color: Colors.orange,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const FilePickerFeature()),
                        ),
                      ),
                      _buildFeatureCard(
                        title: 'Watermark',
                        description: 'Add watermarks to photos & videos',
                        icon: Icons.branding_watermark,
                        color: Colors.teal,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const WatermarkFeature()),
                        ),
                      ),
                      _buildFeatureCard(
                        title: '3rd Party Camera',
                        description: 'Third-party camera integration demo',
                        icon: Icons.camera_enhance,
                        color: Colors.deepPurple,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) =>
                                    const CamerAwesomeFeature()),
                          );
                          _checkPermissions(); // Refresh permissions when returning
                        },
                        requiresPermission: true,
                        hasPermission: _hasCameraPermission,
                      ),
                      _buildFeatureCard(
                        title: 'Permissions',
                        description: 'Manage camera & gallery permissions',
                        icon: Icons.security,
                        color: Colors.purple,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const PermissionFeature()),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Platform Info
              _buildPlatformInfo(),
              const SizedBox(height: 16),

              // Key Features
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Key Features Demonstrated',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text('📸 Image and video picking from gallery'),
                      const Text('🎥 Camera photo capture and video recording'),
                      const Text('🏷️ Advanced watermarking with positioning'),
                      const Text(
                          '✂️ Interactive cropping with manual selection'),
                      const Text('🎛️ Image quality control and resizing'),
                      const Text('📁 Multiple media selection'),
                      const Text('📄 File picking with extension filtering'),
                      const Text('🔐 Permission management'),
                      const Text('⚙️ Real-time settings configuration'),
                      const Text(
                          '🌐 Cross-platform support (Android, iOS, macOS, Web)'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
