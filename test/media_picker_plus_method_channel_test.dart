import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/media_picker_plus_method_channel.dart';
import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/media_source.dart';
import 'package:media_picker_plus/media_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelMediaPickerPlus platform = MethodChannelMediaPickerPlus();
  const MethodChannel channel = MethodChannel('info.thanhtunguet.media_picker_plus');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return '42';
          case 'pickMedia':
            return 'test_path.jpg';
          case 'hasCameraPermission':
          case 'requestCameraPermission':
          case 'hasGalleryPermission':
          case 'requestGalleryPermission':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('pickMedia calls correct method', () async {
    const options = MediaOptions();
    final result = await platform.pickMedia(MediaSource.gallery, MediaType.image, options);
    expect(result, 'test_path.jpg');
  });

  test('hasCameraPermission returns true', () async {
    final result = await platform.hasCameraPermission();
    expect(result, true);
  });

  test('requestCameraPermission returns true', () async {
    final result = await platform.requestCameraPermission();
    expect(result, true);
  });

  test('hasGalleryPermission returns true', () async {
    final result = await platform.hasGalleryPermission();
    expect(result, true);
  });

  test('requestGalleryPermission returns true', () async {
    final result = await platform.requestGalleryPermission();
    expect(result, true);
  });

  test('pickMedia with custom options', () async {
    const options = MediaOptions(
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 90,
      watermark: 'Test Watermark',
    );
    final result = await platform.pickMedia(MediaSource.camera, MediaType.video, options);
    expect(result, 'test_path.jpg');
  });

  test('pickMedia handles exceptions', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'pickMedia') {
          throw PlatformException(code: 'ERROR', message: 'Test error');
        }
        return null;
      },
    );

    const options = MediaOptions();
    expect(
      () => platform.pickMedia(MediaSource.gallery, MediaType.image, options),
      throwsA(isA<Exception>()),
    );
  });
}