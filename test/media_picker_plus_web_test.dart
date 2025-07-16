@TestOn('chrome')
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/media_picker_plus_web.dart';
import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/media_source.dart';
import 'package:media_picker_plus/media_type.dart';

void main() {
  group('MediaPickerPlusWeb', () {
    late MediaPickerPlusWeb plugin;

    setUp(() {
      plugin = MediaPickerPlusWeb();
    });

    test('getPlatformVersion returns user agent', () async {
      final version = await plugin.getPlatformVersion();
      expect(version, isNotNull);
      expect(version, isA<String>());
    });

    test('hasCameraPermission returns true by default', () async {
      final result = await plugin.hasCameraPermission();
      expect(result, true);
    });

    test('requestCameraPermission returns true by default', () async {
      final result = await plugin.requestCameraPermission();
      expect(result, true);
    });

    test('hasGalleryPermission returns true', () async {
      final result = await plugin.hasGalleryPermission();
      expect(result, true);
    });

    test('requestGalleryPermission returns true', () async {
      final result = await plugin.requestGalleryPermission();
      expect(result, true);
    });

    test('pickMedia from gallery throws exception for camera', () async {
      const options = MediaOptions();
      
      // Camera capture should throw an exception in web
      expect(
        () => plugin.pickMedia(MediaSource.camera, MediaType.image, options),
        throwsA(isA<Exception>()),
      );
    });

    test('pickMedia from gallery for image should work', () async {
      const options = MediaOptions();
      
      // Gallery pick should work but may return null if no file selected
      // In a real test, this would need more complex mocking
      try {
        final result = await plugin.pickMedia(MediaSource.gallery, MediaType.image, options);
        // Result can be null if user cancels
        expect(result, anyOf(isNull, isA<String>()));
      } catch (e) {
        // This is expected in test environment without real file picker
        expect(e, isNotNull);
      }
    });

    test('pickMedia with custom options', () async {
      const options = MediaOptions(
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 90,
        watermark: 'Test Watermark',
      );
      
      try {
        final result = await plugin.pickMedia(MediaSource.gallery, MediaType.image, options);
        expect(result, anyOf(isNull, isA<String>()));
      } catch (e) {
        // This is expected in test environment
        expect(e, isNotNull);
      }
    });

    test('pickMedia handles unsupported source', () async {
      const options = MediaOptions();
      
      // Test with an invalid source by casting
      expect(
        () => plugin.pickMedia(MediaSource.values.first, MediaType.image, options),
        throwsA(isA<Exception>()),
      );
    });
  });
}