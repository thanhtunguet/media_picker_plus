import 'dart:async';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'camera_preview_web.dart';

/// Helper class to show camera preview overlay and handle user interactions
// TODO: This overlay path appears unused; consider removing or integrating.
class CameraPreviewController {
  static Future<T?> showPreview<T>({
    required BuildContext context,
    required web.MediaStream stream,
    required bool isVideo,
  }) async {
    final completer = Completer<T?>();
    bool isRecording = false;

    // Show the overlay
    final overlay = OverlayEntry(
      builder: (context) => CameraPreviewOverlay(
        stream: stream,
        isVideo: isVideo,
        isRecording: isRecording,
        onCapture: () {
          if (!completer.isCompleted) {
            if (isVideo) {
              // Start recording
              // We'll handle this in the implementation
              completer.complete(true as T);
            } else {
              // Capture photo
              completer.complete(true as T);
            }
          }
        },
        onStopRecording: isVideo
            ? () {
                if (!completer.isCompleted) {
                  completer.complete(false as T);
                }
              }
            : null,
        onCancel: () {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      ),
    );

    // Insert the overlay
    final overlayState = Overlay.of(context);
    overlayState.insert(overlay);

    // Wait for user action
    final result = await completer.future;

    // Remove the overlay
    overlay.remove();

    return result;
  }
}
