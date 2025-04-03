import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/media_picker_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Picker Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _mediaPath;
  bool _isVideo = false;
  final _qualityController = TextEditingController(text: '80');
  final _widthController = TextEditingController(text: '720');
  final _heightController = TextEditingController(text: '1280');
  final _bitrateController = TextEditingController(text: '8000000');

  @override
  void dispose() {
    _qualityController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _bitrateController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final options = MediaOptions(
      imageQuality: int.tryParse(_qualityController.text) ?? 80,
      width: int.tryParse(_widthController.text),
      height: int.tryParse(_heightController.text),
    );

    final path = await MediaPickerPlus.pickImage(options: options);

    if (path != null) {
      setState(() {
        _mediaPath = path;
        _isVideo = false;
      });
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final options = MediaOptions(
      videoBitrate: int.tryParse(_bitrateController.text),
    );

    final path = await MediaPickerPlus.pickVideo(options: options);

    if (path != null) {
      setState(() {
        _mediaPath = path;
        _isVideo = true;
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    // Check and request camera permission if needed
    bool hasPermission = await MediaPickerPlus.hasCameraPermission();
    if (!hasPermission) {
      hasPermission = await MediaPickerPlus.requestCameraPermission();
      if (!hasPermission) {
        _showSnackbar('Camera permission denied');
        return;
      }
    }

    final options = MediaOptions(
      imageQuality: int.tryParse(_qualityController.text) ?? 80,
      width: int.tryParse(_widthController.text),
      height: int.tryParse(_heightController.text),
    );

    final path = await MediaPickerPlus.capturePhoto(options: options);

    if (path != null) {
      setState(() {
        _mediaPath = path;
        _isVideo = false;
      });
    }
  }

  Future<void> _recordVideo() async {
    // Check and request camera permission if needed
    bool hasPermission = await MediaPickerPlus.hasCameraPermission();
    if (!hasPermission) {
      hasPermission = await MediaPickerPlus.requestCameraPermission();
      if (!hasPermission) {
        _showSnackbar('Camera permission denied');
        return;
      }
    }

    final options = MediaOptions(
      videoBitrate: int.tryParse(_bitrateController.text),
      width: int.tryParse(_widthController.text),
      height: int.tryParse(_heightController.text),
    );

    final path = await MediaPickerPlus.recordVideo(options: options);

    if (path != null) {
      setState(() {
        _mediaPath = path;
        _isVideo = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Picker Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Media Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Quality options
            TextField(
              controller: _qualityController,
              decoration: const InputDecoration(
                labelText: 'Image Quality (0-100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),

            // Resolution options
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthController,
                    decoration: const InputDecoration(
                      labelText: 'Width',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Video bitrate option
            TextField(
              controller: _bitrateController,
              decoration: const InputDecoration(
                labelText: 'Video Bitrate (bps)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Action buttons
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton(
                  onPressed: _pickImageFromGallery,
                  child: const Text('Pick Image'),
                ),
                ElevatedButton(
                  onPressed: _pickVideoFromGallery,
                  child: const Text('Pick Video'),
                ),
                ElevatedButton(
                  onPressed: _capturePhoto,
                  child: const Text('Capture Photo'),
                ),
                ElevatedButton(
                  onPressed: _recordVideo,
                  child: const Text('Record Video'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Media preview
            if (_mediaPath != null) ...[
              const Text('Preview:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isVideo
                    ? Center(child: Text('Video Path: $_mediaPath'))
                    : Image.file(
                        File(_mediaPath!),
                        fit: BoxFit.contain,
                      ),
              ),
              const SizedBox(height: 8),
              SelectableText('File path: $_mediaPath'),
            ],
          ],
        ),
      ),
    );
  }
}
