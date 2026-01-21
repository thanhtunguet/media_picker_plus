@test_pkg.TestOn('browser')
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/media_options.dart';
import 'package:media_picker_plus/media_picker_plus_web.dart';
import 'package:test/test.dart' as test_pkg;

void main() {
  test('applyImage returns a data URL for a data image', () async {
    const dataUrl =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==';
    final api = MediaPickerPlusWeb();
    final result = await api.applyImage(dataUrl, const MediaOptions());

    expect(result, isNotNull);
    expect(result, startsWith('data:image/jpeg'));
  });
}
