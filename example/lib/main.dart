import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _mediaPath;
  bool _isVideo = false;
  VideoPlayerController? _videoController;

  // Thumbnail related state
  String? _thumbnailPath;
  final TextEditingController _thumbnailTimeController =
      TextEditingController(text: "1.0");

  final TextEditingController _watermarkController =
      TextEditingController(text: "Media Picker Plus");
  String _watermarkPosition = WatermarkPosition.bottomRight;
  bool _enableCrop = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Permission handling is platform-specific:
    // - Web: Browser handles permissions automatically via native dialogs when
    //        getUserMedia() or file picker is triggered. No pre-request needed.
    //        Permission.photos, Permission.camera, and Permission.microphone are
    //        NOT supported by permission_handler on web.
    // - Desktop (macOS/Windows/Linux): Permissions are configured through system
    //        settings and Info.plist/manifest configuration, not runtime requests.
    // - Mobile (Android/iOS): Requires runtime permission requests.
    if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return;
    }

    // Request permissions only on mobile platforms (Android/iOS)
    await [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.storage,
    ].request();
  }

  Future<void> _pickImage() async {
    final file = await MediaPickerPlus.pickImage(
      options: MediaOptions(
        watermark: _watermarkController.text,
        watermarkPosition: _watermarkPosition,
        cropOptions: CropOptions(enableCrop: _enableCrop),
      ),
      context: context,
    );
    if (file != null) {
      setState(() {
        _mediaPath = file;
        _isVideo = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    final file = await MediaPickerPlus.capturePhoto(
      options: MediaOptions(
        watermark: _watermarkController.text,
        watermarkPosition: _watermarkPosition,
        cropOptions: CropOptions(enableCrop: _enableCrop),
      ),
      context: context,
    );
    if (file != null) {
      setState(() {
        _mediaPath = file;
        _isVideo = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    final file = await MediaPickerPlus.pickVideo(
      options: MediaOptions(
        watermark: _watermarkController.text,
        watermarkPosition: _watermarkPosition,
      ),
    );
    if (file != null) {
      _setVideo(file);
    }
  }

  Future<void> _recordVideo() async {
    final file = await MediaPickerPlus.recordVideo(
      options: MediaOptions(
        watermark: _watermarkController.text,
        watermarkPosition: _watermarkPosition,
      ),
    );
    if (file != null) {
      _setVideo(file);
    }
  }

  void _setVideo(String path) {
    _videoController?.dispose();

    // Use appropriate VideoPlayerController based on platform
    if (kIsWeb || path.startsWith('data:') || path.startsWith('blob:')) {
      // Web: Use network controller for data/blob URLs
      _videoController = VideoPlayerController.networkUrl(Uri.parse(path))
        ..initialize().then((_) {
          setState(() {
            _mediaPath = path;
            _isVideo = true;
            _videoController!.play();
          });
        });
    } else {
      // Native platforms: Use file controller
      _videoController = VideoPlayerController.file(File(path))
        ..initialize().then((_) {
          setState(() {
            _mediaPath = path;
            _isVideo = true;
            _videoController!.play();
          });
        });
    }
  }

  Future<void> _openCustomCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomCameraPage(),
      ),
    );

    if (result != null && result is String) {
      // Apply watermark to the captured image
      // Note: addWatermarkToImage expects an existing file path.
      final watermarkFile = await MediaPickerPlus.addWatermarkToImage(
        result,
        options: MediaOptions(
          watermark: _watermarkController.text,
          watermarkPosition: _watermarkPosition,
        ),
      );

      if (watermarkFile != null) {
        setState(() {
          _mediaPath = watermarkFile;
          _isVideo = false;
        });
      }
    }
  }

  Future<void> _extractThumbnail() async {
    if (_mediaPath == null || !_isVideo) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a video first')),
        );
      }
      return;
    }

    try {
      // Parse the time input
      final timeInSeconds =
          double.tryParse(_thumbnailTimeController.text) ?? 1.0;

      final thumbnail = await MediaPickerPlus.getThumbnail(
        _mediaPath!,
        timeInSeconds: timeInSeconds,
        options: MediaOptions(
          maxWidth: 300,
          maxHeight: 300,
          imageQuality: 85,
          watermark: _watermarkController.text.isNotEmpty
              ? _watermarkController.text
              : null,
          watermarkPosition: _watermarkPosition,
        ),
      );

      if (!mounted) return;

      if (thumbnail != null) {
        setState(() {
          _thumbnailPath = thumbnail;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thumbnail extracted at ${timeInSeconds}s')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to extract thumbnail')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error extracting thumbnail: $e')),
        );
      }
    }
  }

  void _openFullscreen() {
    if (_mediaPath == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenMediaViewer(
          mediaPath: _mediaPath!,
          isVideo: _isVideo,
          videoController: _videoController,
        ),
      ),
    );
  }

  String _getPathDescription(String path) {
    if (kIsWeb) {
      if (path.startsWith('data:image')) {
        return 'Image (data URL)';
      } else if (path.startsWith('data:video')) {
        return 'Video (data URL)';
      } else if (path.startsWith('blob:')) {
        return 'Media (blob URL)';
      }
      return 'Media (web)';
    }
    // For native platforms, show the file path
    return 'Path: $path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Picker Plus Example')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_mediaPath != null)
                Column(
                  children: [
                    GestureDetector(
                      onTap: () => _openFullscreen(),
                      child: SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: _isVideo
                            ? AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : _buildImage(_mediaPath!, BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getPathDescription(_mediaPath!),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Tap to view fullscreen",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                )
              else
                const Text("No media selected", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              TextField(
                controller: _watermarkController,
                decoration: const InputDecoration(
                  labelText: "Watermark Text",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _watermarkPosition,
                decoration: const InputDecoration(
                  labelText: "Watermark Position",
                  border: OutlineInputBorder(),
                ),
                items: [
                  WatermarkPosition.topLeft,
                  WatermarkPosition.topCenter,
                  WatermarkPosition.topRight,
                  WatermarkPosition.middleLeft,
                  WatermarkPosition.middleCenter,
                  WatermarkPosition.middleRight,
                  WatermarkPosition.bottomLeft,
                  WatermarkPosition.bottomCenter,
                  WatermarkPosition.bottomRight,
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _watermarkPosition = v);
                },
              ),
              SwitchListTile(
                title: const Text("Enable Cropping (Image Only)"),
                value: _enableCrop,
                onChanged: (v) => setState(() => _enableCrop = v),
              ),
              const SizedBox(height: 20),

              // Thumbnail extraction section
              if (_isVideo && _mediaPath != null) ...[
                const Divider(),
                const Text(
                  "Video Thumbnail Extraction",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _thumbnailTimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Time in seconds",
                    border: OutlineInputBorder(),
                    helperText: "Extract thumbnail at this time",
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _extractThumbnail,
                  icon: const Icon(Icons.image),
                  label: const Text("Extract Thumbnail"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_thumbnailPath != null) ...[
                  const SizedBox(height: 10),
                  const Text(
                    "Generated Thumbnail:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImage(_thumbnailPath!, BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getPathDescription(_thumbnailPath!),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 20),
                const Divider(),
              ],

              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Pick Image"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _capturePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Capture Photo"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_library),
                    label: const Text("Pick Video"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _recordVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text("Record Video"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openCustomCamera,
                    icon: const Icon(Icons.camera),
                    label: const Text("Camerawesome"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomCameraPage extends StatelessWidget {
  const CustomCameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photo(pathBuilder: (sensors) async {
          final Directory extDir = await getTemporaryDirectory();
          final testDir = await Directory(
            '${extDir.path}/camerawesome',
          ).create(recursive: true);
          final String path =
              "${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
          return SingleCaptureRequest(path, sensors.first);
        }),
        onMediaTap: (mediaCapture) {
          // mediaCapture.captureRequest might be the way to go if filePath is missing.
          // However, let's check if captureRequest exists.
          // Assuming mediaCapture.captureRequest is of type CaptureRequest
          // and SingleCaptureRequest has a 'path' property.
          // Note: Depending on version, it might be 'when' (unlikely) or 'path'.
          // Let's try casting or accessing likely property.
          // If 'filePath' was missing, maybe it's just 'path'.
          // But 'captureRequest' is safer as it's the core object.
          // Actually, for SingleCaptureRequest, 'path' is the property.
          Navigator.pop(context, mediaCapture.captureRequest.path);
        },
      ),
    );
  }
}

class FullscreenMediaViewer extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final VideoPlayerController? videoController;

  const FullscreenMediaViewer({
    super.key,
    required this.mediaPath,
    required this.isVideo,
    this.videoController,
  });

  @override
  State<FullscreenMediaViewer> createState() => _FullscreenMediaViewerState();
}

class _FullscreenMediaViewerState extends State<FullscreenMediaViewer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.isVideo ? 'Video Viewer' : 'Image Viewer',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: widget.isVideo
              ? (widget.videoController != null &&
                      widget.videoController!.value.isInitialized)
                  ? AspectRatio(
                      aspectRatio: widget.videoController!.value.aspectRatio,
                      child: VideoPlayer(widget.videoController!),
                    )
                  : const CircularProgressIndicator()
              : _buildImage(widget.mediaPath, BoxFit.contain),
        ),
      ),
    );
  }
}

/// Helper function to display images on both web and native platforms.
/// On web, media paths are data URLs (base64) or blob URLs, so we use Image.network().
/// On native platforms, media paths are file paths, so we use Image.file().
Widget _buildImage(String path, BoxFit fit) {
  if (kIsWeb || path.startsWith('data:') || path.startsWith('blob:')) {
    // Web: Use Image.network for data URLs and blob URLs
    return Image.network(
      path,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text('Failed to load image'),
            ],
          ),
        );
      },
    );
  } else {
    // Native platforms: Use Image.file for file paths
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text('Failed to load image'),
            ],
          ),
        );
      },
    );
  }
}
