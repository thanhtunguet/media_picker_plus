@TestOn('vm')
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/crop_options.dart';
import 'package:media_picker_plus/crop_ui.dart';

Future<ui.Image> _createTestImage() async {
  final completer = Completer<ui.Image>();
  final pixels = Uint8List.fromList(<int>[
    255,
    0,
    0,
    255,
    0,
    255,
    0,
    255,
    0,
    0,
    255,
    255,
    255,
    255,
    0,
    255,
  ]);
  ui.decodeImageFromPixels(
    pixels,
    2,
    2,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
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
    // Pump initial frame to build the widget
    await tester.pump();
    // Pump again to trigger post-frame callbacks scheduled in initState
    await tester.pump();
    
    // Wait for callback, pumping frames periodically if needed
    for (int i = 0; i < 20 && emitted == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (emitted != null) break;
    }

    expect(emitted, isNotNull, reason: 'onCropChanged should have been called');
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
    // Pump initial frame to build the widget
    await tester.pump();
    // Pump again to trigger post-frame callbacks scheduled in initState
    await tester.pump();
    
    // Wait for callback, pumping frames periodically if needed
    for (int i = 0; i < 20 && emitted == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (emitted != null) break;
    }

    expect(emitted, isNotNull, reason: 'onCropChanged should have been called');
    final ratio = emitted!.width / emitted!.height;
    expect(ratio, closeTo(1.0, 0.01));
  });
}
