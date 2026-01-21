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

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      lastCall = call;
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
}
