import 'dart:io';
import 'package:flutter/material.dart';

import 'crop_options.dart';
import 'crop_ui.dart';
import 'media_options.dart';
import 'media_picker_plus_platform_interface.dart';
import 'media_source.dart';
import 'media_type.dart';

/// Helper class to handle interactive cropping flow
class CropHelper {

  /// Pick media with interactive cropping UI when cropping is enabled
  static Future<String?> pickMediaWithCrop(
    BuildContext context,
    MediaSource source,
    MediaType type,
    MediaOptions options,
  ) async {
    // Check if interactive cropping is needed
    if (options.cropOptions?.enableCrop == true) {
      return await _pickWithInteractiveCrop(context, source, type, options);
    }
    
    // Use regular picking when cropping is disabled
    return await MediaPickerPlusPlatform.instance.pickMedia(source, type, options);
  }

  static Future<String?> _pickWithInteractiveCrop(
    BuildContext context,
    MediaSource source,
    MediaType type,
    MediaOptions options,
  ) async {
    // First pick the media without cropping
    final tempOptions = MediaOptions(
      imageQuality: options.imageQuality,
      maxWidth: options.maxWidth,
      maxHeight: options.maxHeight,
      watermark: null, // Don't apply watermark until after cropping
      watermarkFontSize: options.watermarkFontSize,
      watermarkPosition: options.watermarkPosition,
      maxDuration: options.maxDuration,
      cropOptions: null, // Disable cropping for initial pick
    );
    
    final tempResult = await MediaPickerPlusPlatform.instance.pickMedia(source, type, tempOptions);
    if (tempResult == null) return null;

    // Check if context is still mounted before showing UI
    if (!context.mounted) return null;

    // Show interactive cropping UI
    final cropResult = await showCropUI(context, tempResult, options.cropOptions);
    if (cropResult == null) return null;

    // Apply final processing with watermark if needed
    if (options.watermark != null) {
      final finalOptions = MediaOptions(
        imageQuality: options.imageQuality,
        maxWidth: options.maxWidth,
        maxHeight: options.maxHeight,
        watermark: options.watermark,
        watermarkFontSize: options.watermarkFontSize,
        watermarkPosition: options.watermarkPosition,
        maxDuration: options.maxDuration,
        cropOptions: CropOptions(
          enableCrop: true,
          cropRect: cropResult,
          freeform: false, // Use specific crop rect
          showGrid: false,
          lockAspectRatio: false,
        ),
      );
      
      // Create a temporary file from the original and process with final options
      return await _processImageWithFinalOptions(tempResult, finalOptions);
    }
    
    // Apply cropping without watermark
    final finalOptions = MediaOptions(
      imageQuality: options.imageQuality,
      maxWidth: options.maxWidth,
      maxHeight: options.maxHeight,
      watermark: null,
      watermarkFontSize: options.watermarkFontSize,
      watermarkPosition: options.watermarkPosition,
      maxDuration: options.maxDuration,
      cropOptions: CropOptions(
        enableCrop: true,
        cropRect: cropResult,
        freeform: false,
        showGrid: false,
        lockAspectRatio: false,
      ),
    );
    
    return await _processImageWithFinalOptions(tempResult, finalOptions);
  }

  static Future<String?> _processImageWithFinalOptions(
    String imagePath,
    MediaOptions options,
  ) async {
    try {
      final tempFile = File(imagePath);
      if (!await tempFile.exists()) return null;
      
      // Use the platform interface to process the image with the crop settings
      return await MediaPickerPlusPlatform.instance.processImage(imagePath, options);
    } catch (e) {
      // If processing fails, return the original image
      return imagePath;
    }
  }

  /// Show the interactive crop UI and return the selected crop rectangle
  static Future<CropRect?> showCropUI(
    BuildContext context,
    String imagePath,
    CropOptions? cropOptions,
  ) async {
    if (!context.mounted) return null;

    CropRect? selectedCropRect;

    final result = await Navigator.of(context).push<CropRect>(
      MaterialPageRoute(
        builder: (context) => CropUI(
          imagePath: imagePath,
          initialCropOptions: cropOptions,
          onCropChanged: (cropRect) {
            selectedCropRect = cropRect;
          },
          onConfirm: () {
            Navigator.of(context).pop(selectedCropRect);
          },
          onCancel: () {
            Navigator.of(context).pop(null);
          },
        ),
        fullscreenDialog: true,
      ),
    );

    return result;
  }
}