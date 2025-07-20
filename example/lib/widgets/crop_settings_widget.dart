import 'package:flutter/material.dart';

class CropSettingsWidget extends StatelessWidget {
  final bool enableCrop;
  final String cropPreset;
  final ValueChanged<bool> onCropChanged;
  final ValueChanged<String> onPresetChanged;

  const CropSettingsWidget({
    super.key,
    required this.enableCrop,
    required this.cropPreset,
    required this.onCropChanged,
    required this.onPresetChanged,
  });

  Widget _buildCropPresetChip(String label, String preset, BuildContext context) {
    final isSelected = cropPreset == preset;
    final isInteractive = preset == 'freeform' && isSelected;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isInteractive) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.touch_app,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onPresetChanged(preset);
        }
      },
      backgroundColor: isSelected ? Theme.of(context).primaryColor.withAlpha(51) : null,
      selectedColor: Theme.of(context).primaryColor.withAlpha(102),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Enable Cropping'),
            Switch(
              value: enableCrop,
              onChanged: onCropChanged,
            ),
          ],
        ),
        if (enableCrop) ...[
          const SizedBox(height: 8),
          const Text('Crop Presets:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildCropPresetChip('Square', 'square', context),
              _buildCropPresetChip('3:4', 'portrait', context),
              _buildCropPresetChip('4:3', 'landscape', context),
              _buildCropPresetChip('16:9', 'widescreen', context),
              _buildCropPresetChip('Free', 'freeform', context),
            ],
          ),
          if (cropPreset == 'freeform') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Interactive cropping UI will appear when you pick or capture media.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}