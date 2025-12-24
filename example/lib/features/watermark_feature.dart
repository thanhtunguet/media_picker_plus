import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';

import '../widgets/media_preview_widget.dart';

class WatermarkFeature extends StatefulWidget {
  const WatermarkFeature({super.key});

  @override
  State<WatermarkFeature> createState() => _WatermarkFeatureState();
}

class _WatermarkFeatureState extends State<WatermarkFeature> {
  String? _originalMediaPath;
  String? _watermarkedMediaPath;
  bool _isLoading = false;
  MediaType _mediaType = MediaType.image;

  // Watermark settings
  String _watermarkText = 'Media Picker Plus';
  bool _usePercentageFontSize = true; // Default to percentage-based
  double _watermarkFontSize = 32;
  double _watermarkFontSizePercentage = 4.0; // 4% of shorter edge
  String _watermarkPosition = WatermarkPosition.bottomRight;

  MediaOptions get _currentOptions => MediaOptions(
        watermark: _watermarkText,
        watermarkFontSize: _usePercentageFontSize ? null : _watermarkFontSize,
        watermarkFontSizePercentage:
            _usePercentageFontSize ? _watermarkFontSizePercentage : null,
        watermarkPosition: _watermarkPosition,
      );

  Future<void> _pickMedia(MediaType type) async {
    setState(() {
      _isLoading = true;
      _mediaType = type;
      _watermarkedMediaPath = null;
    });

    try {
      final path = type == MediaType.image
          ? await MediaPickerPlus.pickImage(
              options: const MediaOptions(),
            )
          : await MediaPickerPlus.pickVideo(
              options: const MediaOptions(),
            );

      if (mounted) {
        setState(() => _originalMediaPath = path);
      }
    } catch (e) {
      if (mounted) _showError('Error picking media: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addWatermark() async {
    if (_originalMediaPath == null) {
      _showError('Please select a media file first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final watermarkedPath = _mediaType == MediaType.image
          ? await MediaPickerPlus.addWatermarkToImage(
              _originalMediaPath!,
              options: _currentOptions,
            )
          : await MediaPickerPlus.addWatermarkToVideo(
              _originalMediaPath!,
              options: _currentOptions,
            );

      if (mounted) {
        setState(() => _watermarkedMediaPath = watermarkedPath);
        _showSuccess('Watermark added successfully!');
      }
    } catch (e) {
      if (mounted) _showError('Error adding watermark: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watermark Feature'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Feature Description
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.branding_watermark,
                                  color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              const Text(
                                'Add Watermark to Media',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Add custom text watermarks to your photos and videos. '
                            'Configure text, size, and position to protect your media.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Media Type Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Step 1: Select Media Type',
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
                                  onPressed: () => _pickMedia(MediaType.image),
                                  icon: const Icon(Icons.photo),
                                  label: const Text('Pick Photo'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _pickMedia(MediaType.video),
                                  icon: const Icon(Icons.videocam),
                                  label: const Text('Pick Video'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Watermark Settings
                  if (_originalMediaPath != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Step 2: Configure Watermark',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Watermark Text
                            TextField(
                              decoration: const InputDecoration(
                                labelText: 'Watermark Text',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.text_fields),
                              ),
                              controller: TextEditingController(
                                text: _watermarkText,
                              ),
                              onChanged: (value) {
                                setState(() => _watermarkText = value);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Font Size Mode Toggle
                            SwitchListTile(
                              title:
                                  const Text('Use Percentage-Based Font Size'),
                              subtitle: Text(
                                _usePercentageFontSize
                                    ? 'Font size scales with media dimensions'
                                    : 'Fixed font size in pixels',
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: _usePercentageFontSize,
                              onChanged: (value) {
                                setState(() => _usePercentageFontSize = value);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 8),

                            // Font Size Slider
                            Row(
                              children: [
                                const Icon(Icons.format_size),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _usePercentageFontSize
                                            ? 'Font Size: ${_watermarkFontSizePercentage.toStringAsFixed(1)}%'
                                            : 'Font Size: ${_watermarkFontSize.toInt()}px',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (_usePercentageFontSize)
                                        Slider(
                                          value: _watermarkFontSizePercentage,
                                          min: 1,
                                          max: 20,
                                          divisions: 190,
                                          label:
                                              '${_watermarkFontSizePercentage.toStringAsFixed(1)}%',
                                          onChanged: (value) {
                                            setState(() =>
                                                _watermarkFontSizePercentage =
                                                    value);
                                          },
                                        )
                                      else
                                        Slider(
                                          value: _watermarkFontSize,
                                          min: 12,
                                          max: 72,
                                          divisions: 60,
                                          label: _watermarkFontSize
                                              .toInt()
                                              .toString(),
                                          onChanged: (value) {
                                            setState(() =>
                                                _watermarkFontSize = value);
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Position Selection
                            const Text(
                              'Watermark Position',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildPositionChip(
                                  'Top Left',
                                  WatermarkPosition.topLeft,
                                  Icons.north_west,
                                ),
                                _buildPositionChip(
                                  'Top Right',
                                  WatermarkPosition.topRight,
                                  Icons.north_east,
                                ),
                                _buildPositionChip(
                                  'Bottom Left',
                                  WatermarkPosition.bottomLeft,
                                  Icons.south_west,
                                ),
                                _buildPositionChip(
                                  'Bottom Right',
                                  WatermarkPosition.bottomRight,
                                  Icons.south_east,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Apply Watermark Button
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Step 3: Apply Watermark',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _addWatermark,
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('Add Watermark'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Media Preview
                  if (_originalMediaPath != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Original Media',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            MediaPreviewWidget(
                              mediaPath: _originalMediaPath!,
                              title: 'Original',
                              height: 250,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_watermarkedMediaPath != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Watermarked Media',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            MediaPreviewWidget(
                              mediaPath: _watermarkedMediaPath!,
                              title: 'With Watermark',
                              height: 250,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Path: $_watermarkedMediaPath',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPositionChip(String label, String position, IconData icon) {
    final isSelected = _watermarkPosition == position;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _watermarkPosition = position);
        }
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
    );
  }
}
