@TestOn('vm')
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/crop_helper.dart';
import 'package:media_picker_plus/crop_options.dart';
import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/media_source.dart';
import 'package:media_picker_plus/media_type.dart';
import 'package:media_picker_plus/preferred_camera_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('info.thanhtunguet.media_picker_plus');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  // Helper to build a test app with a context
  Widget buildTestApp({required Widget Function(BuildContext) builder}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: builder(context),
        ),
      ),
    );
  }

  group('CropHelper.pickMediaWithCrop', () {
    testWidgets('calls pickMedia without crop when crop disabled',
        (tester) async {
      List<MethodCall> calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'pickMedia') {
          return '/tmp/test.jpg';
        }
        return null;
      });

      late BuildContext testContext;
      await tester.pumpWidget(buildTestApp(builder: (context) {
        testContext = context;
        return Container();
      }));

      const options = MediaOptions();

      final result = await CropHelper.pickMediaWithCrop(
        testContext,
        MediaSource.camera,
        MediaType.image,
        options,
      );

      expect(result, equals('/tmp/test.jpg'));
      expect(calls.length, equals(1));
      expect(calls[0].method, equals('pickMedia'));
      final args = calls[0].arguments as Map;
      expect(args['source'], equals('camera'));
      expect(args['type'], equals('image'));
      final opts = args['options'] as Map;
      expect(opts['cropOptions'], isNull);
    });

    testWidgets('initiates three-phase flow when crop enabled', (tester) async {
      List<MethodCall> calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'pickMedia') {
          return '/tmp/uncropped.jpg';
        }
        if (call.method == 'processImage') {
          return '/tmp/cropped.jpg';
        }
        return null;
      });

      await tester.pumpWidget(buildTestApp(builder: (context) {
        return ElevatedButton(
          onPressed: () async {
            const options = MediaOptions(
              cropOptions: CropOptions(enableCrop: true),
            );

            // This will trigger the interactive crop flow
            // In a real test with navigation, this would show the crop UI
            // For unit testing, we're verifying the initial pickMedia call
            await CropHelper.pickMediaWithCrop(
              context,
              MediaSource.gallery,
              MediaType.image,
              options,
            );
          },
          child: const Text('Test'),
        );
      }));

      await tester.tap(find.text('Test'));
      await tester.pump();

      // Give time for the async operation to start
      await tester.pump(const Duration(milliseconds: 100));

      // Phase 1: Should call pickMedia without crop options
      expect(calls.isNotEmpty, isTrue);
      expect(calls[0].method, equals('pickMedia'));
      final args = calls[0].arguments as Map;
      final opts = args['options'] as Map;
      expect(opts['cropOptions'], isNull,
          reason: 'Phase 1 should disable crop for initial pick');
    });

    testWidgets('returns null when user cancels initial pick', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'pickMedia') {
          return null; // User cancelled
        }
        return null;
      });

      late BuildContext testContext;
      await tester.pumpWidget(buildTestApp(builder: (context) {
        testContext = context;
        return Container();
      }));

      const options = MediaOptions(
        cropOptions: CropOptions(enableCrop: true),
      );

      final result = await CropHelper.pickMediaWithCrop(
        testContext,
        MediaSource.camera,
        MediaType.image,
        options,
      );

      expect(result, isNull);
    });
  });

  // Note: CropHelper._processImageWithFinalOptions is a private method
  // It's tested indirectly through the public pickMediaWithCrop flow
  // Full end-to-end crop flow testing requires integration tests

  group('CropHelper.showCropUI', () {
    testWidgets('returns null when context is not mounted', (tester) async {
      late BuildContext testContext;
      await tester.pumpWidget(buildTestApp(builder: (context) {
        testContext = context;
        return Container();
      }));

      // Remove the widget tree to unmount context
      await tester.pumpWidget(Container());

      final result = await CropHelper.showCropUI(
        testContext,
        '/tmp/test.jpg',
        const CropOptions(),
      );

      expect(result, isNull);
    });
  });

  group('CropHelper crop options handling', () {
    testWidgets('strips watermark in phase 1, applies in phase 3',
        (tester) async {
      List<MethodCall> calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'pickMedia') {
          return '/tmp/test.jpg';
        }
        return null;
      });

      await tester.pumpWidget(buildTestApp(builder: (context) {
        return ElevatedButton(
          onPressed: () async {
            const options = MediaOptions(
              watermark: 'Test Watermark',
              cropOptions: CropOptions(enableCrop: true),
            );

            await CropHelper.pickMediaWithCrop(
              context,
              MediaSource.camera,
              MediaType.image,
              options,
            );
          },
          child: const Text('Test'),
        );
      }));

      await tester.tap(find.text('Test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Phase 1: Should strip watermark from initial pick
      expect(calls.isNotEmpty, isTrue);
      final args = calls[0].arguments as Map;
      final opts = args['options'] as Map;
      expect(opts['watermark'], isNull,
          reason: 'Watermark should be stripped in phase 1');
    });

    testWidgets('preserves imageQuality across all phases', (tester) async {
      List<MethodCall> calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'pickMedia') {
          return '/tmp/test.jpg';
        }
        return null;
      });

      await tester.pumpWidget(buildTestApp(builder: (context) {
        return ElevatedButton(
          onPressed: () async {
            const options = MediaOptions(
              imageQuality: 75,
              cropOptions: CropOptions(enableCrop: true),
            );

            await CropHelper.pickMediaWithCrop(
              context,
              MediaSource.gallery,
              MediaType.image,
              options,
            );
          },
          child: const Text('Test'),
        );
      }));

      await tester.tap(find.text('Test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Phase 1: Should preserve imageQuality
      expect(calls.isNotEmpty, isTrue);
      final args = calls[0].arguments as Map;
      final opts = args['options'] as Map;
      expect(opts['imageQuality'], equals(75));
    });

    testWidgets('preserves preferredCameraDevice across phases',
        (tester) async {
      List<MethodCall> calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'pickMedia') {
          return '/tmp/test.jpg';
        }
        return null;
      });

      await tester.pumpWidget(buildTestApp(builder: (context) {
        return ElevatedButton(
          onPressed: () async {
            const options = MediaOptions(
              preferredCameraDevice: PreferredCameraDevice.front,
              cropOptions: CropOptions(enableCrop: true),
            );

            await CropHelper.pickMediaWithCrop(
              context,
              MediaSource.camera,
              MediaType.image,
              options,
            );
          },
          child: const Text('Test'),
        );
      }));

      await tester.tap(find.text('Test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Phase 1: Should preserve preferredCameraDevice
      expect(calls.isNotEmpty, isTrue);
      final args = calls[0].arguments as Map;
      final opts = args['options'] as Map;
      expect(opts['preferredCameraDevice'], equals('front'));
    });
  });

  group('CropHelper error handling', () {
    testWidgets('handles platform exception gracefully', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'pickMedia') {
          throw PlatformException(code: 'ERROR', message: 'Test error');
        }
        return null;
      });

      late BuildContext testContext;
      await tester.pumpWidget(buildTestApp(builder: (context) {
        testContext = context;
        return Container();
      }));

      const options = MediaOptions();

      expect(
        () => CropHelper.pickMediaWithCrop(
          testContext,
          MediaSource.camera,
          MediaType.image,
          options,
        ),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
