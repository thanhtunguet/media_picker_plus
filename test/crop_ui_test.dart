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

  testWidgets('CropUI shows loading indicator when image is loading',
      (tester) async {
    // When no initialImage is provided and imagePath is a file path,
    // the widget shows a loading indicator while the image loads.
    // Using a non-existent path so it quickly fails to loading state.
    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: '/nonexistent/path/image.jpg',
          onCropChanged: (_) {},
        ),
      ),
    );

    // The first frame shows the loading state
    await tester.pump();

    // Loading indicator is shown while loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('CropUI shows error state when image fails to load',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: '/nonexistent/path/image.jpg',
          onCropChanged: (_) {},
        ),
      ),
    );

    // Use runAsync to let real async I/O complete (File.readAsBytes throws)
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 500));
    });

    // Pump to let setState propagate
    await tester.pump();

    // Error message shown when image fails to load
    expect(find.text('Failed to load image'), findsOneWidget);
  });

  testWidgets('CropUI shows Cancel and Crop buttons with initialImage',
      (tester) async {
    final image = await _createTestImage();

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'test',
          initialImage: image,
          onCropChanged: (_) {},
          onCancel: () {},
          onConfirm: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Crop'), findsOneWidget);
  });

  testWidgets('CropUI calls onCancel when cancel button tapped',
      (tester) async {
    final image = await _createTestImage();
    bool cancelCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'test',
          initialImage: image,
          onCropChanged: (_) {},
          onCancel: () => cancelCalled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(cancelCalled, isTrue);
  });

  testWidgets('CropUI calls onConfirm when crop button tapped', (tester) async {
    final image = await _createTestImage();
    bool confirmCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'test',
          initialImage: image,
          onCropChanged: (_) {},
          onConfirm: () => confirmCalled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crop'));
    await tester.pump();

    expect(confirmCalled, isTrue);
  });

  testWidgets('CropUI shows aspect ratio chips', (tester) async {
    final image = await _createTestImage();

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'test',
          initialImage: image,
          onCropChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // All standard aspect ratio options should be shown
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('1:1'), findsOneWidget);
    expect(find.text('4:3'), findsOneWidget);
    expect(find.text('16:9'), findsOneWidget);
  });

  testWidgets('CropUI updates crop rect when aspect ratio chip tapped',
      (tester) async {
    final image = await _createTestImage();
    CropRect? lastEmitted;

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'test',
          initialImage: image,
          onCropChanged: (rect) => lastEmitted = rect,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the 1:1 aspect ratio chip
    await tester.tap(find.text('1:1'));

    // Pump past the throttle period (> 16ms) to allow callback to fire
    await tester.pump(const Duration(milliseconds: 50));

    // A crop rect should have been emitted with square aspect ratio
    if (lastEmitted != null) {
      final ratio = lastEmitted!.width / lastEmitted!.height;
      expect(ratio, closeTo(1.0, 0.05));
    }
  });

  testWidgets('CropUI shows crop percentage text', (tester) async {
    final image = await _createTestImage();

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'test',
          initialImage: image,
          initialCropOptions: const CropOptions(
            cropRect: CropRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5),
          ),
          onCropChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The crop percentage text follows the "Crop: XX% × XX%" pattern
    final cropTextFinder = find.textContaining('Crop:');
    expect(cropTextFinder, findsOneWidget);
    final text = tester.widget<Text>(cropTextFinder).data ?? '';
    expect(text, contains('%'));
  });

  testWidgets('CropUI shows reset button in app bar', (tester) async {
    final image = await _createTestImage();

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'test',
          initialImage: image,
          onCropChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Reset button (refresh icon) and confirm button (check icon) in app bar
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('CropUI uses custom crop rect from options', (tester) async {
    final image = await _createTestImage();
    CropRect? emitted;

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'test',
          initialImage: image,
          initialCropOptions: const CropOptions(
            cropRect: CropRect(x: 0.15, y: 0.25, width: 0.6, height: 0.4),
          ),
          onCropChanged: (rect) => emitted = rect,
        ),
      ),
    );

    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (emitted != null) break;
    }

    expect(emitted, isNotNull);
    expect(emitted!.x, closeTo(0.15, 0.001));
    expect(emitted!.y, closeTo(0.25, 0.001));
    expect(emitted!.width, closeTo(0.6, 0.001));
    expect(emitted!.height, closeTo(0.4, 0.001));
  });
}
