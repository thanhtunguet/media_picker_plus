import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';

Future<void> main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Picker Plus Example',
      home: MediaPickerExample(),
    );
  }
}

class MediaPickerExample extends StatefulWidget {
  const MediaPickerExample({super.key});

  @override
  State<MediaPickerExample> createState() => _MediaPickerExampleState();
}

class _MediaPickerExampleState extends State<MediaPickerExample> {
  String? _pickedMediaPath;

  Future<void> _pickImage() async {
    try {
      final path = await MediaPickerPlus.pickImage(
        options: MediaOptions(
          imageQuality: 80,
          maxWidth: 1280,
          maxHeight: 1280,
          watermark: 'Sample Watermark',
          watermarkFontSize: 30,
          watermarkPosition: WatermarkPosition.bottomRight,
        ),
      );
      setState(() {
        _pickedMediaPath = path;
      });
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Media Picker Plus Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            if (_pickedMediaPath != null) Image.file(File(_pickedMediaPath!)),
          ],
        ),
      ),
    );
  }
}
