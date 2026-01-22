@TestOn('vm')
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/crop_options.dart';
import 'package:media_picker_plus/crop_ui.dart';

Future<ui.Image> _createTestImage() async {
  // Use a PictureRecorder + Canvas based image to avoid relying on
  // decodeImageFromPixels callbacks, which can hang in headless CI.
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Draw a simple 2x2 red image. The actual content is irrelevant for
  // these tests; they only care that a valid ui.Image exists.
  final paint = Paint()..color = const Color(0xFFFF0000);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 2, 2), paint);

  final picture = recorder.endRecording();
  return picture.toImage(2, 2);
}

void main() {
  testWidgets('CropUI emits initial crop rect from options', (tester) async {
    final image = await _createTestImage();
    CropRect? emitted;

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'test',
          initialImage: image,
          initialCropOptions: const CropOptions(
            cropRect: CropRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
          ),
          onCropChanged: (rect) {
            emitted = rect;
          },
        ),
      ),
    );

    // Pump initial frame to build widget
    await tester.pump();

    // Pump additional frames to trigger post-frame callbacks and microtasks
    // The callback is scheduled via addPostFrameCallback in initState
    // and also via Future.microtask in didChangeDependencies
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16)); // ~60fps
      if (emitted != null) break;
    }

    // If still not received, pump a few more frames with longer delays
    if (emitted == null) {
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (emitted != null) break;
      }
    }

    expect(emitted, isNotNull,
        reason:
            'onCropChanged should have been called after widget initialization');
    expect(emitted!.x, closeTo(0.2, 0.001));
    expect(emitted!.y, closeTo(0.3, 0.001));
    expect(emitted!.width, closeTo(0.4, 0.001));
    expect(emitted!.height, closeTo(0.5, 0.001));
  });

  testWidgets('CropUI applies aspect ratio when provided', (tester) async {
    final image = await _createTestImage();
    CropRect? emitted;

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'test',
          initialImage: image,
          initialCropOptions: const CropOptions(
            aspectRatio: 1.0,
            lockAspectRatio: true,
          ),
          onCropChanged: (rect) {
            emitted = rect;
          },
        ),
      ),
    );

    // Pump initial frame to build widget
    await tester.pump();

    // Pump additional frames to trigger post-frame callbacks and microtasks
    // The callback is scheduled via addPostFrameCallback in initState
    // and also via Future.microtask in didChangeDependencies
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16)); // ~60fps
      if (emitted != null) break;
    }

    // If still not received, pump a few more frames with longer delays
    if (emitted == null) {
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (emitted != null) break;
      }
    }

    expect(emitted, isNotNull,
        reason:
            'onCropChanged should have been called after widget initialization');
    final ratio = emitted!.width / emitted!.height;
    expect(ratio, closeTo(1.0, 0.01));
  });
}
