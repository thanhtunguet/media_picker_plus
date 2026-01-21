@TestOn('vm')
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/crop_options.dart';

void main() {
  test('CropRect toMap/fromMap round-trip', () {
    const rect = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
    final map = rect.toMap();
    final fromMap = CropRect.fromMap(map);

    expect(fromMap, rect);
  });

  test('CropOptions copyWith preserves fields', () {
    const options = CropOptions(
      enableCrop: true,
      aspectRatio: 4.0 / 3.0,
      freeform: false,
      showGrid: false,
      lockAspectRatio: true,
    );

    final updated = options.copyWith(showGrid: true);

    expect(updated.enableCrop, true);
    expect(updated.aspectRatio, 4.0 / 3.0);
    expect(updated.freeform, false);
    expect(updated.showGrid, true);
    expect(updated.lockAspectRatio, true);
  });
}
