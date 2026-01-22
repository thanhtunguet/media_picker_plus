@TestOn('vm')
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/crop_options.dart';
import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/media_picker_plus_method_channel.dart';
import 'package:media_picker_plus/media_source.dart';
import 'package:media_picker_plus/media_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('info.thanhtunguet.media_picker_plus');
  MethodCall? lastCall;
  List<MethodCall> allCalls = [];

  setUp(() {
    allCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      lastCall = call;
      allCalls.add(call);
      return 'path';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('pickMedia preserves cropOptions for freeform cropping', () async {
    final api = MethodChannelMediaPickerPlus();
    const options = MediaOptions(
      cropOptions: CropOptions(enableCrop: true, freeform: true),
    );

    await api.pickMedia(MediaSource.gallery, MediaType.image, options);

    expect(lastCall?.method, 'pickMedia');
    final args = lastCall?.arguments as Map<dynamic, dynamic>?;
    expect(args, isNotNull);
    final optionsMap = args?['options'] as Map<dynamic, dynamic>?;
    expect(optionsMap?['cropOptions'], isNotNull);
  });

  test('concurrent pickMedia requests preserve their respective options',
      () async {
    final api = MethodChannelMediaPickerPlus();

    // Track calls with their options
    final callOptions = <String, Map<dynamic, dynamic>>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      allCalls.add(call);
      if (call.method == 'pickMedia') {
        final args = call.arguments as Map<dynamic, dynamic>?;
        final optionsMap = args?['options'] as Map<dynamic, dynamic>?;
        if (optionsMap != null) {
          callOptions[call.toString()] = Map.from(optionsMap);
        }
      }
      // Simulate async processing delay
      await Future.delayed(const Duration(milliseconds: 10));
      return 'path';
    });

    // Create two different options
    const options1 = MediaOptions(
      watermark: 'Watermark1',
      maxWidth: 1000,
      maxHeight: 2000,
    );

    const options2 = MediaOptions(
      watermark: 'Watermark2',
      maxWidth: 2000,
      maxHeight: 4000,
    );

    // Launch concurrent requests
    final future1 =
        api.pickMedia(MediaSource.gallery, MediaType.image, options1);
    final future2 =
        api.pickMedia(MediaSource.gallery, MediaType.image, options2);

    // Wait for both to complete
    await Future.wait([future1, future2]);

    // Verify both calls were made
    expect(allCalls.length, 2);
    expect(allCalls.every((call) => call.method == 'pickMedia'), isTrue);

    // Verify each call preserved its own options
    final options1Found = callOptions.values.any((opts) =>
        opts['watermark'] == 'Watermark1' &&
        opts['maxWidth'] == 1000 &&
        opts['maxHeight'] == 2000);
    final options2Found = callOptions.values.any((opts) =>
        opts['watermark'] == 'Watermark2' &&
        opts['maxWidth'] == 2000 &&
        opts['maxHeight'] == 4000);

    expect(options1Found, isTrue, reason: 'Options1 should be preserved');
    expect(options2Found, isTrue, reason: 'Options2 should be preserved');
  });

  test(
      'concurrent pickMultipleMedia requests preserve their respective options',
      () async {
    final api = MethodChannelMediaPickerPlus();

    // Track calls with their options
    final callOptions = <String, Map<dynamic, dynamic>>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      allCalls.add(call);
      if (call.method == 'pickMultipleMedia') {
        final args = call.arguments as Map<dynamic, dynamic>?;
        final optionsMap = args?['options'] as Map<dynamic, dynamic>?;
        if (optionsMap != null) {
          callOptions[call.toString()] = Map.from(optionsMap);
        }
      }
      // Simulate async processing delay
      await Future.delayed(const Duration(milliseconds: 10));
      return ['path1', 'path2'];
    });

    // Create two different options
    const options1 = MediaOptions(
      watermark: 'Batch1',
      maxWidth: 800,
    );

    const options2 = MediaOptions(
      watermark: 'Batch2',
      maxWidth: 1600,
    );

    // Launch concurrent requests
    final future1 = api.pickMultipleMedia(
      MediaSource.gallery,
      MediaType.image,
      options1,
    );
    final future2 = api.pickMultipleMedia(
      MediaSource.gallery,
      MediaType.image,
      options2,
    );

    // Wait for both to complete
    await Future.wait([future1, future2]);

    // Verify both calls were made
    expect(allCalls.length, 2);
    expect(
        allCalls.every((call) => call.method == 'pickMultipleMedia'), isTrue);

    // Verify each call preserved its own options
    final options1Found = callOptions.values.any(
        (opts) => opts['watermark'] == 'Batch1' && opts['maxWidth'] == 800);
    final options2Found = callOptions.values.any(
        (opts) => opts['watermark'] == 'Batch2' && opts['maxWidth'] == 1600);

    expect(options1Found, isTrue, reason: 'Batch1 options should be preserved');
    expect(options2Found, isTrue, reason: 'Batch2 options should be preserved');
  });

  test('options are passed correctly to applyImage', () async {
    final api = MethodChannelMediaPickerPlus();

    MethodCall? applyImageCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'applyImage') {
        applyImageCall = call;
      }
      return 'processed_path.jpg';
    });

    const options = MediaOptions(
      watermark: 'TestWatermark',
      maxWidth: 1920,
      maxHeight: 1080,
    );

    await api.applyImage('input.jpg', options);

    expect(applyImageCall?.method, 'applyImage');
    final args = applyImageCall?.arguments as Map<dynamic, dynamic>?;
    expect(args, isNotNull);
    final optionsMap = args?['options'] as Map<dynamic, dynamic>?;
    expect(optionsMap?['watermark'], 'TestWatermark');
    expect(optionsMap?['maxWidth'], 1920);
    expect(optionsMap?['maxHeight'], 1080);
  });
}
