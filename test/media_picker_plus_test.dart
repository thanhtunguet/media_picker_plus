import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/media_picker_plus.dart';
import 'package:media_picker_plus/media_picker_plus_platform_interface.dart';
import 'package:media_picker_plus/media_picker_plus_method_channel.dart';
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
  Future<String?> applyImage(String imagePath, MediaOptions options) {
    return Future.value('processed_$imagePath');
  }

  @override
  Future<String?> applyVideo(String videoPath, MediaOptions options) {
    return Future.value('processed_$videoPath');
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
  final MediaPickerPlusPlatform initialPlatform =
      MediaPickerPlusPlatform.instance;

  test('$MethodChannelMediaPickerPlus is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMediaPickerPlus>());
  });

  group('MediaPickerPlus', () {
    late MockMediaPickerPlusPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockMediaPickerPlusPlatform();
      MediaPickerPlusPlatform.instance = mockPlatform;
    });

    test('pickImage returns path from platform', () async {
      final result = await MediaPickerPlus.pickImage();
      expect(result, 'test_path.jpg');
    });

    test('pickVideo returns path from platform', () async {
      final result = await MediaPickerPlus.pickVideo();
      expect(result, 'test_path.jpg');
    });

    test('capturePhoto returns path from platform', () async {
      final result = await MediaPickerPlus.capturePhoto();
      expect(result, 'test_path.jpg');
    });

    test('recordVideo returns path from platform', () async {
      final result = await MediaPickerPlus.recordVideo();
      expect(result, 'test_path.jpg');
    });

    test('hasCameraPermission returns true', () async {
      final result = await MediaPickerPlus.hasCameraPermission();
      expect(result, true);
    });

    test('requestCameraPermission returns true', () async {
      final result = await MediaPickerPlus.requestCameraPermission();
      expect(result, true);
    });

    test('hasGalleryPermission returns true', () async {
      final result = await MediaPickerPlus.hasGalleryPermission();
      expect(result, true);
    });

    test('requestGalleryPermission returns true', () async {
      final result = await MediaPickerPlus.requestGalleryPermission();
      expect(result, true);
    });

    test('pickImage with custom options', () async {
      const options = MediaOptions(
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 90,
        watermark: 'Test Watermark',
      );
      final result = await MediaPickerPlus.pickImage(options: options);
      expect(result, 'test_path.jpg');
    });

    test('pickFile returns file path from platform', () async {
      final result = await MediaPickerPlus.pickFile();
      expect(result, 'test_file.pdf');
    });

    test('pickFile with allowed extensions', () async {
      final result = await MediaPickerPlus.pickFile(
        allowedExtensions: ['.pdf', '.docx'],
      );
      expect(result, 'test_file.pdf');
    });

    test('pickMultipleFiles returns list of file paths from platform',
        () async {
      final result = await MediaPickerPlus.pickMultipleFiles();
      expect(result, ['test_file1.pdf', 'test_file2.docx']);
    });

    test('pickMultipleFiles with allowed extensions', () async {
      final result = await MediaPickerPlus.pickMultipleFiles(
        allowedExtensions: ['.pdf', '.docx'],
      );
      expect(result, ['test_file1.pdf', 'test_file2.docx']);
    });

    test('pickMultipleImages returns list of image paths from platform',
        () async {
      final result = await MediaPickerPlus.pickMultipleImages();
      expect(result, ['test_media1.jpg', 'test_media2.jpg']);
    });

    test('pickMultipleVideos returns list of video paths from platform',
        () async {
      final result = await MediaPickerPlus.pickMultipleVideos();
      expect(result, ['test_media1.jpg', 'test_media2.jpg']);
    });

    test('pickMultipleImages with custom options', () async {
      const options = MediaOptions(
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 90,
        watermark: 'Test Watermark',
      );
      final result = await MediaPickerPlus.pickMultipleImages(options: options);
      expect(result, ['test_media1.jpg', 'test_media2.jpg']);
    });

    test('addWatermarkToImage returns watermarked path', () async {
      const options = MediaOptions(
        watermark: 'Test Watermark',
        watermarkFontSize: 24,
        watermarkPosition: 'bottomRight',
      );
      final result = await MediaPickerPlus.addWatermarkToImage(
        'test_image.jpg',
        options: options,
      );
      expect(result, 'watermarked_test_image.jpg');
    });

    test('addWatermarkToVideo returns watermarked path', () async {
      const options = MediaOptions(
        watermark: 'Test Watermark',
        watermarkFontSize: 24,
        watermarkPosition: 'topLeft',
      );
      final result = await MediaPickerPlus.addWatermarkToVideo(
        'test_video.mp4',
        options: options,
      );
      expect(result, 'watermarked_test_video.mp4');
    });

    test('getThumbnail returns thumbnail path', () async {
      final result = await MediaPickerPlus.getThumbnail('test_video.mp4');
      expect(result, 'thumbnail_test_video.mp4');
    });

    test('getThumbnail with custom time and options', () async {
      const options = MediaOptions(
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 85,
        watermark: 'Thumbnail',
      );
      final result = await MediaPickerPlus.getThumbnail(
        'test_video.mp4',
        timeInSeconds: 5.0,
        options: options,
      );
      expect(result, 'thumbnail_test_video.mp4');
    });
  });

  group('MediaOptions', () {
    test('default values are set correctly', () {
      const options = MediaOptions();
      expect(options.imageQuality, 80);
      expect(options.maxWidth, 1280);
      expect(options.maxHeight, 1280);
      expect(options.watermark, null);
      expect(options.watermarkFontSize, null);
      expect(options.watermarkFontSizePercentage, 4.0);
      expect(options.watermarkPosition, 'bottomRight');
      expect(options.maxDuration, const Duration(seconds: 60));
    });

    test('custom values are set correctly', () {
      const options = MediaOptions(
        imageQuality: 95,
        maxWidth: 1920,
        maxHeight: 1080,
        watermark: 'Custom Watermark',
        watermarkFontSize: 24,
        watermarkPosition: 'topLeft',
        maxDuration: Duration(seconds: 120),
      );
      expect(options.imageQuality, 95);
      expect(options.maxWidth, 1920);
      expect(options.maxHeight, 1080);
      expect(options.watermark, 'Custom Watermark');
      expect(options.watermarkFontSize, 24);
      expect(options.watermarkPosition, 'topLeft');
      expect(options.maxDuration, const Duration(seconds: 120));
    });

    test('percentage-based font size can be set', () {
      const options = MediaOptions(
        watermark: 'Test Watermark',
        watermarkFontSizePercentage: 5.5,
        watermarkPosition: 'topRight',
      );
      expect(options.watermark, 'Test Watermark');
      expect(options.watermarkFontSizePercentage, 5.5);
      expect(options.watermarkPosition, 'topRight');
    });

    test('toMap returns correct map with absolute font size', () {
      const options = MediaOptions(
        imageQuality: 95,
        maxWidth: 1920,
        maxHeight: 1080,
        watermark: 'Test',
        watermarkFontSize: 24,
        watermarkPosition: 'topLeft',
        maxDuration: Duration(seconds: 120),
      );
      final map = options.toMap();
      expect(map['imageQuality'], 95);
      expect(map['maxWidth'], 1920);
      expect(map['maxHeight'], 1080);
      expect(map['watermark'], 'Test');
      expect(map['watermarkFontSize'], 24);
      expect(map['watermarkPosition'], 'topLeft');
      expect(map['maxDuration'], 120);
    });

    test('toMap returns correct map with percentage-based font size', () {
      const options = MediaOptions(
        watermark: 'Test',
        watermarkFontSizePercentage: 5.0,
        watermarkPosition: 'bottomLeft',
      );
      final map = options.toMap();
      expect(map['watermark'], 'Test');
      expect(map['watermarkFontSizePercentage'], 5.0);
      expect(map['watermarkPosition'], 'bottomLeft');
    });
  });

  group('MediaSource', () {
    test('enum values are correct', () {
      expect(MediaSource.gallery.toString(), 'MediaSource.gallery');
      expect(MediaSource.camera.toString(), 'MediaSource.camera');
      expect(MediaSource.files.toString(), 'MediaSource.files');
    });

    test('has all expected values', () {
      expect(MediaSource.values.length, 3);
      expect(MediaSource.values, contains(MediaSource.gallery));
      expect(MediaSource.values, contains(MediaSource.camera));
      expect(MediaSource.values, contains(MediaSource.files));
    });
  });

  group('MediaType', () {
    test('enum values are correct', () {
      expect(MediaType.image.toString(), 'MediaType.image');
      expect(MediaType.video.toString(), 'MediaType.video');
      expect(MediaType.file.toString(), 'MediaType.file');
    });

    test('has all expected values', () {
      expect(MediaType.values.length, 3);
      expect(MediaType.values, contains(MediaType.image));
      expect(MediaType.values, contains(MediaType.video));
      expect(MediaType.values, contains(MediaType.file));
    });
  });

  group('WatermarkPosition', () {
    test('all position constants are defined', () {
      expect(WatermarkPosition.topLeft, 'topLeft');
      expect(WatermarkPosition.topCenter, 'topCenter');
      expect(WatermarkPosition.topRight, 'topRight');
      expect(WatermarkPosition.middleLeft, 'middleLeft');
      expect(WatermarkPosition.middleCenter, 'middleCenter');
      expect(WatermarkPosition.middleRight, 'middleRight');
      expect(WatermarkPosition.bottomLeft, 'bottomLeft');
      expect(WatermarkPosition.bottomCenter, 'bottomCenter');
      expect(WatermarkPosition.bottomRight, 'bottomRight');
    });

    test('position values are strings', () {
      expect(WatermarkPosition.topLeft, isA<String>());
      expect(WatermarkPosition.bottomRight, isA<String>());
      expect(WatermarkPosition.middleCenter, isA<String>());
    });
  });
}
