import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
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
    // Skip permission requests on macOS and desktop platforms
    // Desktop platforms handle permissions through system settings
    // and Info.plist/manifest configuration
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return;
    }

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
    _videoController = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        setState(() {
          _mediaPath = path;
          _isVideo = true;
          _videoController!.play();
        });
      });
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
                            : Image.file(
                                File(_mediaPath!),
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Path: $_mediaPath"),
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
              : Image.file(
                  File(widget.mediaPath),
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}
