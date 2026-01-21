@TestOn('vm')
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/crop_options.dart';
import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/watermark_position.dart';

void main() {
  test('MediaOptions.toMap includes defaults', () {
    const options = MediaOptions();
    final map = options.toMap();

    expect(map['imageQuality'], 80);
    expect(map['maxWidth'], 1280);
    expect(map['maxHeight'], 1280);
    expect(map['watermarkFontSizePercentage'], 4.0);
    expect(map['watermarkPosition'], WatermarkPosition.bottomRight);
    expect(map['maxDuration'], 60);
  });

  test('MediaOptions.toMap includes crop options', () {
    const cropOptions = CropOptions(
      enableCrop: true,
      aspectRatio: 1.0,
      freeform: false,
      lockAspectRatio: true,
    );
    const options = MediaOptions(cropOptions: cropOptions);
    final map = options.toMap();

    expect(map['cropOptions'], isNotNull);
    final cropMap = map['cropOptions'] as Map<String, dynamic>;
    expect(cropMap['enableCrop'], true);
    expect(cropMap['aspectRatio'], 1.0);
    expect(cropMap['freeform'], false);
    expect(cropMap['lockAspectRatio'], true);
  });
}
