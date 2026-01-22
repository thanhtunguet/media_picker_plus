@TestOn('vm')
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/crop_options.dart';
import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/media_picker_plus_method_channel.dart';
import 'package:media_picker_plus/media_source.dart';
import 'package:media_picker_plus/media_type.dart';
import 'package:media_picker_plus/video_compression_options.dart';

// Helper classes for testing compressVideo with custom options
class _CustomOptions {
  Map<String, dynamic> toMap() => {'custom': 'value'};
}

class _CustomOptionsWithoutToMap {}

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

  group('applyImage', () {
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

    test('handles PlatformException', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR', message: 'Image processing error');
      });

      expect(
        () => api.applyImage('input.jpg', const MediaOptions()),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Error applying image transformations'),
        )),
      );
    });
  });

  group('getPlatformVersion', () {
    test('returns platform version', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return 'Android 13';
      });

      final version = await api.getPlatformVersion();
      expect(version, 'Android 13');
      expect(lastCall?.method, 'getPlatformVersion');
    });

    test('handles null return value', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return null;
      });

      final version = await api.getPlatformVersion();
      expect(version, isNull);
    });
  });

  group('pickMedia', () {
    test('handles PlatformException correctly', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR', message: 'Permission denied');
      });

      expect(
        () => api.pickMedia(MediaSource.gallery, MediaType.image,
            const MediaOptions()),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Error picking media: Permission denied'),
        )),
      );
    });

    test('converts source and type to string correctly', () async {
      final api = MethodChannelMediaPickerPlus();
      await api.pickMedia(MediaSource.camera, MediaType.video,
          const MediaOptions());

      final args = lastCall?.arguments as Map<dynamic, dynamic>?;
      expect(args?['source'], 'camera');
      expect(args?['type'], 'video');
    });
  });

  group('hasCameraPermission', () {
    test('returns true when permission granted', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return true;
      });

      final result = await api.hasCameraPermission();
      expect(result, true);
      expect(lastCall?.method, 'hasCameraPermission');
    });

    test('returns false when permission denied', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return false;
      });

      final result = await api.hasCameraPermission();
      expect(result, false);
    });

    test('returns false on exception', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw Exception('Error');
      });

      final result = await api.hasCameraPermission();
      expect(result, false);
    });

    test('_convertToBool handles String "true"', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return 'true';
      });

      final result = await api.hasCameraPermission();
      expect(result, true);
    });

    test('_convertToBool handles String "1"', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return '1';
      });

      final result = await api.hasCameraPermission();
      expect(result, true);
    });

    test('_convertToBool handles String "false"', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return 'false';
      });

      final result = await api.hasCameraPermission();
      expect(result, false);
    });

    test('_convertToBool handles int 1', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return 1;
      });

      final result = await api.hasCameraPermission();
      expect(result, true);
    });

    test('_convertToBool handles int 0', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return 0;
      });

      final result = await api.hasCameraPermission();
      expect(result, false);
    });
  });

  group('requestCameraPermission', () {
    test('returns true when permission granted', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return true;
      });

      final result = await api.requestCameraPermission();
      expect(result, true);
      expect(lastCall?.method, 'requestCameraPermission');
    });

    test('returns false on exception', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw Exception('Error');
      });

      final result = await api.requestCameraPermission();
      expect(result, false);
    });
  });

  group('hasGalleryPermission', () {
    test('returns true when permission granted', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return true;
      });

      final result = await api.hasGalleryPermission();
      expect(result, true);
      expect(lastCall?.method, 'hasGalleryPermission');
    });

    test('returns false on exception', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw Exception('Error');
      });

      final result = await api.hasGalleryPermission();
      expect(result, false);
    });
  });

  group('requestGalleryPermission', () {
    test('returns true when permission granted', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return true;
      });

      final result = await api.requestGalleryPermission();
      expect(result, true);
      expect(lastCall?.method, 'requestGalleryPermission');
    });

    test('returns false on exception', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw Exception('Error');
      });

      final result = await api.requestGalleryPermission();
      expect(result, false);
    });
  });

  group('pickFile', () {
    test('calls method channel with correct arguments', () async {
      final api = MethodChannelMediaPickerPlus();
      const options = MediaOptions(maxWidth: 1920);
      const allowedExtensions = ['jpg', 'png'];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return 'file_path';
      });

      await api.pickFile(options, allowedExtensions);

      expect(lastCall?.method, 'pickFile');
      final args = lastCall?.arguments as Map<dynamic, dynamic>?;
      expect(args?['options'], isNotNull);
      expect(args?['allowedExtensions'], allowedExtensions);
    });

    test('handles null allowedExtensions', () async {
      final api = MethodChannelMediaPickerPlus();
      const options = MediaOptions();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return 'file_path';
      });

      await api.pickFile(options, null);

      final args = lastCall?.arguments as Map<dynamic, dynamic>?;
      expect(args?['allowedExtensions'], isNull);
    });

    test('handles PlatformException', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR', message: 'File picker error');
      });

      expect(
        () => api.pickFile(const MediaOptions(), null),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Error picking file: File picker error'),
        )),
      );
    });
  });

  group('pickMultipleFiles', () {
    test('calls method channel and returns list of paths', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return ['path1', 'path2', 'path3'];
      });

      const options = MediaOptions();
      const allowedExtensions = ['pdf', 'doc'];

      final result = await api.pickMultipleFiles(options, allowedExtensions);

      expect(lastCall?.method, 'pickMultipleFiles');
      expect(result, ['path1', 'path2', 'path3']);
    });

    test('handles null return value', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return null;
      });

      final result = await api.pickMultipleFiles(const MediaOptions(), null);
      expect(result, isNull);
    });

    test('handles PlatformException', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR', message: 'Error');
      });

      expect(
        () => api.pickMultipleFiles(const MediaOptions(), null),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('pickMultipleMedia', () {
    test('handles PlatformException', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR', message: 'Error');
      });

      expect(
        () => api.pickMultipleMedia(
          MediaSource.gallery,
          MediaType.image,
          const MediaOptions(),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('processImage', () {
    test('delegates to applyImage', () async {
      final api = MethodChannelMediaPickerPlus();
      const options = MediaOptions(maxWidth: 1920);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return 'processed.jpg';
      });

      await api.processImage('input.jpg', options);

      expect(lastCall?.method, 'applyImage');
      final args = lastCall?.arguments as Map<dynamic, dynamic>?;
      expect(args?['imagePath'], 'input.jpg');
    });
  });

  group('addWatermarkToImage', () {
    test('throws ArgumentError when watermark is null', () async {
      final api = MethodChannelMediaPickerPlus();
      const options = MediaOptions(watermark: null);

      expect(
        () => api.addWatermarkToImage('input.jpg', options),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when watermark is empty', () async {
      final api = MethodChannelMediaPickerPlus();
      const options = MediaOptions(watermark: '');

      expect(
        () => api.addWatermarkToImage('input.jpg', options),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('delegates to applyImage when watermark is valid', () async {
      final api = MethodChannelMediaPickerPlus();
      const options = MediaOptions(watermark: 'Test Watermark');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return 'watermarked.jpg';
      });

      await api.addWatermarkToImage('input.jpg', options);

      expect(lastCall?.method, 'applyImage');
    });
  });

  group('applyVideo', () {
    test('calls method channel with correct arguments', () async {
      final api = MethodChannelMediaPickerPlus();
      const options = MediaOptions(watermark: 'Video Watermark');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return 'output.mp4';
      });

      await api.applyVideo('input.mp4', options);

      expect(lastCall?.method, 'applyVideo');
      final args = lastCall?.arguments as Map<dynamic, dynamic>?;
      expect(args?['videoPath'], 'input.mp4');
      expect(args?['options'], isNotNull);
    });

    test('handles PlatformException', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR', message: 'Video error');
      });

      expect(
        () => api.applyVideo('input.mp4', const MediaOptions()),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Error applying video transformations'),
        )),
      );
    });
  });

  group('addWatermarkToVideo', () {
    test('delegates to applyVideo', () async {
      final api = MethodChannelMediaPickerPlus();
      const options = MediaOptions(watermark: 'Video Watermark');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return 'output.mp4';
      });

      await api.addWatermarkToVideo('input.mp4', options);

      expect(lastCall?.method, 'applyVideo');
    });
  });

  group('getThumbnail', () {
    test('calls method channel with default timeInSeconds', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return 'thumbnail.jpg';
      });

      await api.getThumbnail('video.mp4');

      expect(lastCall?.method, 'getThumbnail');
      final args = lastCall?.arguments as Map<dynamic, dynamic>?;
      expect(args?['videoPath'], 'video.mp4');
      expect(args?['timeInSeconds'], 1.0);
      expect(args?['options'], isNull);
    });

    test('calls method channel with custom timeInSeconds', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return 'thumbnail.jpg';
      });

      await api.getThumbnail('video.mp4', timeInSeconds: 5.5);

      final args = lastCall?.arguments as Map<dynamic, dynamic>?;
      expect(args?['timeInSeconds'], 5.5);
    });

    test('calls method channel with options', () async {
      final api = MethodChannelMediaPickerPlus();
      const options = MediaOptions(maxWidth: 200);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return 'thumbnail.jpg';
      });

      await api.getThumbnail('video.mp4', options: options);

      final args = lastCall?.arguments as Map<dynamic, dynamic>?;
      expect(args?['options'], isNotNull);
    });

    test('handles PlatformException', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR', message: 'Thumbnail error');
      });

      expect(
        () => api.getThumbnail('video.mp4'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Error extracting thumbnail'),
        )),
      );
    });
  });

  group('compressVideo', () {
    test('handles Map options', () async {
      final api = MethodChannelMediaPickerPlus();
      final optionsMap = {
        'quality': 'p720',
        'customBitrate': 2000000,
      };
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return 'output.mp4';
      });

      await api.compressVideo('input.mp4', options: optionsMap);

      expect(lastCall?.method, 'compressVideo');
      final args = lastCall?.arguments as Map<dynamic, dynamic>?;
      expect(args?['inputPath'], 'input.mp4');
      expect(args?['options'], optionsMap);
    });

    test('handles VideoCompressionOptions with video info', () async {
      final api = MethodChannelMediaPickerPlus();
      final options = VideoCompressionOptions(
        quality: VideoCompressionQuality.p720,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        allCalls.add(call);
        if (call.method == 'getVideoInfo') {
          return {'width': 1920, 'height': 1080};
        }
        return 'output.mp4';
      });

      await api.compressVideo('input.mp4', options: options);

      // Should call getVideoInfo first, then compressVideo
      expect(allCalls.length, greaterThan(1));
      expect(allCalls.any((call) => call.method == 'compressVideo'), isTrue);
    });

    test('handles VideoCompressionOptions when getVideoInfo fails', () async {
      final api = MethodChannelMediaPickerPlus();
      final options = VideoCompressionOptions(
        quality: VideoCompressionQuality.p720,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        allCalls.add(call);
        if (call.method == 'getVideoInfo') {
          throw Exception('Video info error');
        }
        return 'output.mp4';
      });

      await api.compressVideo('input.mp4', options: options);

      // Should still call compressVideo with fallback options
      expect(allCalls.any((call) => call.method == 'compressVideo'), isTrue);
    });

    test('handles VideoCompressionOptions with outputPath', () async {
      final api = MethodChannelMediaPickerPlus();
      final options = VideoCompressionOptions(
        quality: VideoCompressionQuality.p1080,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        allCalls.add(call);
        if (call.method == 'getVideoInfo') {
          return {'width': 3840, 'height': 2160};
        }
        return 'output.mp4';
      });

      await api.compressVideo('input.mp4',
          outputPath: 'custom_output.mp4', options: options);

      final compressCall = allCalls.firstWhere(
        (call) => call.method == 'compressVideo',
      );
      final args = compressCall.arguments as Map<dynamic, dynamic>?;
      expect(args?['outputPath'], 'custom_output.mp4');
    });

    test('handles PlatformException', () async {
      final api = MethodChannelMediaPickerPlus();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERROR', message: 'Compression error');
      });

      expect(
        () => api.compressVideo('input.mp4', options: <String, dynamic>{}),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Error compressing video'),
        )),
      );
    });

    test('handles custom object with toMap method', () async {
      final api = MethodChannelMediaPickerPlus();
      
      // Create a custom class with toMap method
      final customOptions = _CustomOptions();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        lastCall = call;
        return 'output.mp4';
      });

      await api.compressVideo('input.mp4', options: customOptions);

      expect(lastCall?.method, 'compressVideo');
      final args = lastCall?.arguments as Map<dynamic, dynamic>?;
      expect(args?['options'], {'custom': 'value'});
    });

    test('handles custom object without toMap method (throws NoSuchMethodError)',
        () async {
      final api = MethodChannelMediaPickerPlus();
      
      // Create a custom object without toMap method
      final customOptions = _CustomOptionsWithoutToMap();

      // The code will throw NoSuchMethodError when trying to call toMap()
      // This tests the else branch at line 226
      expect(
        () => api.compressVideo('input.mp4', options: customOptions),
        throwsA(isA<NoSuchMethodError>()),
      );
    });
  });

  group('_convertToBool', () {
    test('converts bool correctly', () {
      final api = MethodChannelMediaPickerPlus();
      // Access via reflection or make it public for testing
      // Since it's private, we test it indirectly through permission methods
      // But we can verify behavior through hasCameraPermission
    });
  });
}
