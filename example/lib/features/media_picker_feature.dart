import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';

import '../widgets/crop_settings_widget.dart';
import '../widgets/media_preview_widget.dart';

class MediaPickerFeature extends StatefulWidget {
  const MediaPickerFeature({super.key});

  @override
  State<MediaPickerFeature> createState() => _MediaPickerFeatureState();
}

class _MediaPickerFeatureState extends State<MediaPickerFeature> {
  String? _singleMediaPath;
  List<String> _multipleMediaPaths = [];
  bool _isLoading = false;

  // Media settings
  int _imageQuality = 85;
  final int _maxWidth = 2560;
  final int _maxHeight = 1440;
  // Using percentage-based font size (4% of shorter edge) for responsive watermarks
  final double _watermarkFontSizePercentage = 4.0;
  final String _watermarkPosition = WatermarkPosition.bottomRight;
  final String _customWatermark = 'Media Picker Plus';
  bool _enableImageResize = true;

  // Crop settings
  bool _enableCrop = false;
  double? _cropAspectRatio;
  String _cropPreset = 'none';

  MediaOptions get _currentOptions => MediaOptions(
        imageQuality: _imageQuality,
        maxWidth: _enableImageResize ? _maxWidth : null,
        maxHeight: _enableImageResize ? _maxHeight : null,
        watermark: _customWatermark,
        watermarkFontSizePercentage: _watermarkFontSizePercentage,
        watermarkPosition: _watermarkPosition,
        cropOptions: _enableCrop
            ? CropOptions(
                enableCrop: true,
                aspectRatio: _cropAspectRatio,
                freeform: _cropAspectRatio == null,
                showGrid: true,
                lockAspectRatio: _cropAspectRatio != null,
              )
            : null,
      );

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

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);
    try {
      final path = await MediaPickerPlus.pickImage(
        options: _currentOptions,
        context: mounted ? context : null,
      );
      if (mounted) {
        setState(() => _singleMediaPath = path);
      }
    } catch (e) {
      if (mounted) _showError('Error picking image: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickVideo() async {
    setState(() => _isLoading = true);
    try {
      final path = await MediaPickerPlus.pickVideo(options: _currentOptions);
      setState(() => _singleMediaPath = path);
    } catch (e) {
      _showError('Error picking video: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMultipleImages() async {
    setState(() => _isLoading = true);
    try {
      final paths = await MediaPickerPlus.pickMultipleImages(
        options: MediaOptions(
          imageQuality: _imageQuality,
          maxWidth: _enableImageResize ? _maxWidth : null,
          maxHeight: _enableImageResize ? _maxHeight : null,
          watermark: '$_customWatermark • Multiple Images',
          watermarkFontSizePercentage: _watermarkFontSizePercentage,
          watermarkPosition: _watermarkPosition,
          cropOptions: _enableCrop
              ? CropOptions(
                  enableCrop: true,
                  aspectRatio: _cropAspectRatio,
                  freeform: _cropAspectRatio == null,
                  showGrid: true,
                  lockAspectRatio: _cropAspectRatio != null,
                )
              : null,
        ),
      );
      setState(() => _multipleMediaPaths = List<String>.from(paths ?? []));
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
        options: MediaOptions(
          imageQuality: _imageQuality,
          maxWidth: _enableImageResize ? _maxWidth : null,
          maxHeight: _enableImageResize ? _maxHeight : null,
          watermark: '$_customWatermark • Multiple Videos',
          watermarkFontSizePercentage: _watermarkFontSizePercentage,
          watermarkPosition: _watermarkPosition,
          cropOptions: _enableCrop
              ? CropOptions(
                  enableCrop: true,
                  aspectRatio: _cropAspectRatio,
                  freeform: _cropAspectRatio == null,
                  showGrid: true,
                  lockAspectRatio: _cropAspectRatio != null,
                )
              : null,
        ),
      );
      setState(() => _multipleMediaPaths = List<String>.from(paths ?? []));
    } catch (e) {
      _showError('Error picking multiple videos: $e');
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

  void _clearSingleMedia() => setState(() => _singleMediaPath = null);
  void _clearMultipleMedia() => setState(() => _multipleMediaPaths.clear());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Picker'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Settings Panel
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
                                'Media Settings',
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
                              Row(
                                children: [
                                  const Expanded(child: Text('Enable Resize')),
                                  Switch(
                                    value: _enableImageResize,
                                    onChanged: (value) => setState(
                                        () => _enableImageResize = value),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CropSettingsWidget(
                                enableCrop: _enableCrop,
                                cropPreset: _cropPreset,
                                onCropChanged: (enabled) =>
                                    setState(() => _enableCrop = enabled),
                                onPresetChanged: _setCropPreset,
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
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: const Text('Pick Image',
                                    style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickVideo,
                                icon: const Icon(Icons.video_library, size: 18),
                                label: const Text('Pick Video',
                                    style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickMultipleImages,
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: const Text('Multiple Images',
                                    style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickMultipleVideos,
                                icon: const Icon(Icons.video_library, size: 18),
                                label: const Text('Multiple Videos',
                                    style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_singleMediaPath != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: MediaPreviewWidget(
                        mediaPath: _singleMediaPath!,
                        title: 'Single Media Preview',
                        onClear: _clearSingleMedia,
                        enableImageResize: _enableImageResize,
                        maxWidth: _maxWidth,
                        maxHeight: _maxHeight,
                      ),
                    ),

                  if (_multipleMediaPaths.isNotEmpty)
                    Card(
                      margin: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.collections),
                            title: const Text('Multiple Media Preview'),
                            trailing: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearMultipleMedia,
                            ),
                          ),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _multipleMediaPaths.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 120,
                                  margin: const EdgeInsets.all(8),
                                  child: MediaPreviewWidget(
                                    mediaPath: _multipleMediaPaths[index],
                                    height: 100,
                                    showControls: false,
                                    enableImageResize: _enableImageResize,
                                    maxWidth: _maxWidth,
                                    maxHeight: _maxHeight,
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                                '${_multipleMediaPaths.length} files selected'),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
