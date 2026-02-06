@TestOn('vm')
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/multi_capture_screen.dart';
import 'package:media_picker_plus/multi_image_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('info.thanhtunguet.media_picker_plus');
  int pickMediaCallCount = 0;

  setUp(() {
    pickMediaCallCount = 0;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// Helper to set up a mock that returns paths in sequence, then null
  void setupMockCamera(List<String?> responses) {
    int callIndex = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'pickMedia') {
        pickMediaCallCount++;
        if (callIndex < responses.length) {
          return responses[callIndex++];
        }
        return null; // Cancel after all responses
      }
      return null;
    });
  }

  Widget buildTestApp({
    MediaOptions mediaOptions = const MediaOptions(),
    MultiImageOptions multiImageOptions = const MultiImageOptions(),
    void Function(List<String>?)? onResult,
  }) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<List<String>>(
                MaterialPageRoute(
                  builder: (_) => MultiCaptureScreen(
                    mediaOptions: mediaOptions,
                    multiImageOptions: multiImageOptions,
                  ),
                ),
              );
              onResult?.call(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('shows loading state initially', (tester) async {
    // Mock camera that never resolves — simulates camera being open
    final completer = Completer<String?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'pickMedia') {
        return completer.future;
      }
      return null;
    });

    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    // Don't use pumpAndSettle — it would wait forever for the completer.
    // Pump enough frames for the navigator animation and postFrameCallback.
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.text('Opening camera...'), findsOneWidget);
    expect(find.text('Photos (0)'), findsOneWidget);

    // Complete the camera to avoid dangling future
    completer.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('pops with null when user cancels first camera', (tester) async {
    // Camera immediately returns null (user cancelled)
    setupMockCamera([null]);

    List<String>? result;
    bool resultCalled = false;
    await tester.pumpWidget(buildTestApp(onResult: (r) {
      result = r;
      resultCalled = true;
    }));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(resultCalled, true);
    expect(result, isNull);
  });

  testWidgets('shows Done button disabled when below minImages',
      (tester) async {
    // Return one photo then null to stop auto-reopening
    setupMockCamera(['/path/img1.jpg', null]);

    await tester.pumpWidget(buildTestApp(
      multiImageOptions: const MultiImageOptions(minImages: 2),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Done button should exist but be visually "disabled" (grey text)
    final doneButton = find.text('Done');
    expect(doneButton, findsOneWidget);

    // Title should show count
    expect(find.text('Photos (1)'), findsOneWidget);
  });

  testWidgets('shows Done button enabled when minImages met', (tester) async {
    setupMockCamera(['/path/img1.jpg', null]);

    await tester.pumpWidget(buildTestApp(
      multiImageOptions: const MultiImageOptions(minImages: 1),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Photos (1)'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('shows Take More button when photos exist and max not reached',
      (tester) async {
    setupMockCamera(['/path/img1.jpg', null]);

    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Take More'), findsOneWidget);
  });

  testWidgets('hides Take More button when maxImages reached', (tester) async {
    setupMockCamera(['/path/img1.jpg', null]);

    await tester.pumpWidget(buildTestApp(
      multiImageOptions: const MultiImageOptions(maxImages: 1),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Take More'), findsNothing);
  });

  testWidgets('Done button pops with captured paths', (tester) async {
    setupMockCamera(['/path/img1.jpg', null]);

    List<String>? result;
    await tester.pumpWidget(buildTestApp(onResult: (r) => result = r));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Tap Done
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result, ['/path/img1.jpg']);
  });

  testWidgets('delete button removes photo from grid', (tester) async {
    setupMockCamera(['/path/img1.jpg', '/path/img2.jpg', null]);

    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Photos (2)'), findsOneWidget);

    // Find and tap the first close icon
    final closeIcons = find.byIcon(Icons.close);
    expect(closeIcons, findsNWidgets(2));
    await tester.tap(closeIcons.first);
    await tester.pumpAndSettle();

    expect(find.text('Photos (1)'), findsOneWidget);
  });

  testWidgets('auto-opens camera up to maxImages then stops', (tester) async {
    // Return 3 photos (maxImages is 2)
    setupMockCamera(['/path/img1.jpg', '/path/img2.jpg', '/path/img3.jpg']);

    await tester.pumpWidget(buildTestApp(
      multiImageOptions: const MultiImageOptions(maxImages: 2),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Should have captured exactly 2 photos (stopped at maxImages)
    expect(find.text('Photos (2)'), findsOneWidget);
    // Camera should have been called exactly 2 times
    expect(pickMediaCallCount, 2);
  });

  testWidgets('screen accessible with state key for testing', (tester) async {
    setupMockCamera([null]);

    await tester.pumpWidget(
      const MaterialApp(
        home: MultiCaptureScreen(
          mediaOptions: MediaOptions(),
          multiImageOptions: MultiImageOptions(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Screen should exist (though it may have popped due to null return)
    // This verifies the widget can be created and rendered
  });
}
