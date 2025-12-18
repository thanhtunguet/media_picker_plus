import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/crop_options.dart';
import 'package:media_picker_plus/crop_ui.dart';

void main() {
  late ui.Image testImage;

  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 10, 10),
      Paint()..color = const Color(0xFFFF0000),
    );
    final picture = recorder.endRecording();
    testImage = await picture.toImage(10, 10);
  });

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    Duration step = const Duration(milliseconds: 50),
    int maxPumps = 40,
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for $finder');
  }

  testWidgets('CropUI loads image and emits initial crop rect', (tester) async {
    CropRect? lastRect;

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'ignored',
          initialImage: testImage,
          onCropChanged: (rect) => lastRect = rect,
          onConfirm: () {},
          onCancel: () {},
        ),
      ),
    );

    await pumpUntilFound(tester, find.byType(CropWidget));
    await tester.pump(const Duration(milliseconds: 30));

    expect(lastRect, isNotNull);
    expect(lastRect!.x, closeTo(0.1, 1e-6));
    expect(lastRect!.y, closeTo(0.1, 1e-6));
    expect(lastRect!.width, closeTo(0.8, 1e-6));
    expect(lastRect!.height, closeTo(0.8, 1e-6));
  });

  testWidgets('CropUI aspect ratio chip updates crop ratio', (tester) async {
    CropRect? lastRect;

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'ignored',
          initialImage: testImage,
          onCropChanged: (rect) => lastRect = rect,
          onConfirm: () {},
          onCancel: () {},
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('1:1'));

    await tester.tap(find.text('1:1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    expect(lastRect, isNotNull);
    expect(lastRect!.width / lastRect!.height, closeTo(1.0, 1e-2));
  });

  testWidgets('CropUI confirm and cancel callbacks are wired', (tester) async {
    var confirmed = false;
    var canceled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: CropUI(
          imagePath: 'ignored',
          initialImage: testImage,
          onCropChanged: (_) {},
          onConfirm: () => confirmed = true,
          onCancel: () => canceled = true,
        ),
      ),
    );

    await pumpUntilFound(tester, find.byIcon(Icons.check));

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    expect(confirmed, true);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(canceled, true);
  });
}
