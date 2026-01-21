import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_picker_plus/media_picker_plus.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('info.thanhtunguet.media_picker_plus');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return 'test-version';
          case 'pickMedia':
            return 'picked_media.jpg';
          case 'pickMultipleMedia':
            return ['picked_1.jpg', 'picked_2.jpg'];
          case 'pickFile':
            return 'picked_file.pdf';
          case 'pickMultipleFiles':
            return ['picked_1.pdf', 'picked_2.docx'];
          case 'processImage':
            return 'processed_media.jpg';
          case 'applyImage':
            return 'applied_image.jpg';
          case 'applyVideo':
            return 'applied_video.mp4';
          case 'compressVideo':
            return 'compressed_video.mp4';
          case 'getThumbnail':
            return 'thumbnail.jpg';
          case 'hasCameraPermission':
          case 'requestCameraPermission':
          case 'hasGalleryPermission':
          case 'requestGalleryPermission':
            return true;
        }
        return null;
      },
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('camera/gallery flows return expected values', (tester) async {
    expect(await MediaPickerPlus.pickImage(), 'picked_media.jpg');
    expect(await MediaPickerPlus.capturePhoto(), 'picked_media.jpg');
    expect(await MediaPickerPlus.pickVideo(), 'picked_media.jpg');
    expect(await MediaPickerPlus.recordVideo(), 'picked_media.jpg');
  });

  testWidgets('file picker flows return expected values', (tester) async {
    expect(await MediaPickerPlus.pickFile(), 'picked_file.pdf');
    expect(
      await MediaPickerPlus.pickMultipleFiles(),
      ['picked_1.pdf', 'picked_2.docx'],
    );
  });

  testWidgets('media processing flows return expected values', (tester) async {
    expect(
      await MediaPickerPlus.applyImage('input.jpg',
          options: const MediaOptions()),
      'applied_image.jpg',
    );
    expect(
      await MediaPickerPlus.applyVideo('input.mp4',
          options: const MediaOptions()),
      'applied_video.mp4',
    );
    expect(
      await MediaPickerPlus.compressVideo('input.mp4', options: {}),
      'compressed_video.mp4',
    );
    expect(
      await MediaPickerPlus.getThumbnail('input.mp4'),
      'thumbnail.jpg',
    );
  });
}
