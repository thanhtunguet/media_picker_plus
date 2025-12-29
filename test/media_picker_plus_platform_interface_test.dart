import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/media_picker_plus_platform_interface.dart';
import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/media_source.dart';
import 'package:media_picker_plus/media_type.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMediaPickerPlusPlatform
    with MockPlatformInterfaceMixin
    implements MediaPickerPlusPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> pickMedia(
      MediaSource source, MediaType type, MediaOptions options) {
    return Future.value('test_path.jpg');
  }

  @override
  Future<bool> hasCameraPermission() => Future.value(true);

  @override
  Future<bool> requestCameraPermission() => Future.value(true);

  @override
  Future<bool> hasGalleryPermission() => Future.value(true);

  @override
  Future<bool> requestGalleryPermission() => Future.value(true);

  @override
  Future<String?> pickFile(
      MediaOptions options, List<String>? allowedExtensions) {
    return Future.value('test_file.pdf');
  }

  @override
  Future<List<String>?> pickMultipleFiles(
      MediaOptions options, List<String>? allowedExtensions) {
    return Future.value(['test_file1.pdf', 'test_file2.docx']);
  }

  @override
  Future<List<String>?> pickMultipleMedia(
      MediaSource source, MediaType type, MediaOptions options) {
    return Future.value(['test_media1.jpg', 'test_media2.jpg']);
  }

  @override
  Future<String?> processImage(String imagePath, MediaOptions options) {
    return Future.value('processed_$imagePath');
  }

  @override
  Future<String?> addWatermarkToImage(String imagePath, MediaOptions options) {
    return Future.value('watermarked_$imagePath');
  }

  @override
  Future<String?> addWatermarkToVideo(String videoPath, MediaOptions options) {
    return Future.value('watermarked_$videoPath');
  }

  @override
  Future<String?> getThumbnail(String videoPath,
      {double timeInSeconds = 1.0, MediaOptions? options}) {
    return Future.value('thumbnail_$videoPath');
  }

  @override
  Future<String?> compressVideo(
    String inputPath, {
    String? outputPath,
    required dynamic options,
  }) {
    return Future.value('compressed_$inputPath');
  }
}

void main() {
  group('MediaPickerPlusPlatform', () {
    test('instance can be set', () {
      final mockPlatform = MockMediaPickerPlusPlatform();
      MediaPickerPlusPlatform.instance = mockPlatform;
      expect(MediaPickerPlusPlatform.instance, mockPlatform);
    });

    test('default pickFile throws UnimplementedError', () async {
      final platform = _UnimplementedPlatform();
      const options = MediaOptions();

      expect(
        () => platform.pickFile(options, null),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('default pickMultipleFiles throws UnimplementedError', () async {
      final platform = _UnimplementedPlatform();
      const options = MediaOptions();

      expect(
        () => platform.pickMultipleFiles(options, null),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('default pickMultipleMedia throws UnimplementedError', () async {
      final platform = _UnimplementedPlatform();
      const options = MediaOptions();

      expect(
        () => platform.pickMultipleMedia(
            MediaSource.gallery, MediaType.image, options),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('default pickMedia throws UnimplementedError', () async {
      final platform = _UnimplementedPlatform();
      const options = MediaOptions();

      expect(
        () => platform.pickMedia(MediaSource.gallery, MediaType.image, options),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('default hasCameraPermission throws UnimplementedError', () async {
      final platform = _UnimplementedPlatform();

      expect(
        () => platform.hasCameraPermission(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('default requestCameraPermission throws UnimplementedError', () async {
      final platform = _UnimplementedPlatform();

      expect(
        () => platform.requestCameraPermission(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('default hasGalleryPermission throws UnimplementedError', () async {
      final platform = _UnimplementedPlatform();

      expect(
        () => platform.hasGalleryPermission(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('default requestGalleryPermission throws UnimplementedError',
        () async {
      final platform = _UnimplementedPlatform();

      expect(
        () => platform.requestGalleryPermission(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('default getPlatformVersion throws UnimplementedError', () async {
      final platform = _UnimplementedPlatform();

      expect(
        () => platform.getPlatformVersion(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    group('MockMediaPickerPlusPlatform', () {
      late MockMediaPickerPlusPlatform mockPlatform;

      setUp(() {
        mockPlatform = MockMediaPickerPlusPlatform();
      });

      test('pickFile returns expected result', () async {
        const options = MediaOptions();
        final result = await mockPlatform.pickFile(options, ['.pdf']);
        expect(result, 'test_file.pdf');
      });

      test('pickFile with null extensions', () async {
        const options = MediaOptions();
        final result = await mockPlatform.pickFile(options, null);
        expect(result, 'test_file.pdf');
      });

      test('pickMultipleFiles returns expected result', () async {
        const options = MediaOptions();
        final result =
            await mockPlatform.pickMultipleFiles(options, ['.pdf', '.docx']);
        expect(result, ['test_file1.pdf', 'test_file2.docx']);
      });

      test('pickMultipleFiles with null extensions', () async {
        const options = MediaOptions();
        final result = await mockPlatform.pickMultipleFiles(options, null);
        expect(result, ['test_file1.pdf', 'test_file2.docx']);
      });

      test('pickMultipleMedia returns expected result', () async {
        const options = MediaOptions();
        final result = await mockPlatform.pickMultipleMedia(
            MediaSource.gallery, MediaType.image, options);
        expect(result, ['test_media1.jpg', 'test_media2.jpg']);
      });

      test('pickMultipleMedia with video type', () async {
        const options = MediaOptions();
        final result = await mockPlatform.pickMultipleMedia(
            MediaSource.gallery, MediaType.video, options);
        expect(result, ['test_media1.jpg', 'test_media2.jpg']);
      });

      test('pickMultipleMedia with camera source', () async {
        const options = MediaOptions();
        final result = await mockPlatform.pickMultipleMedia(
            MediaSource.camera, MediaType.image, options);
        expect(result, ['test_media1.jpg', 'test_media2.jpg']);
      });
    });
  });
}

class _UnimplementedPlatform extends MediaPickerPlusPlatform {
  // This class intentionally doesn't override any methods to test the default implementations
}
