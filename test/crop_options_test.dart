import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/crop_options.dart';

void main() {
  group('CropRect', () {
    test('toMap/fromMap round-trip', () {
      const rect = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      final map = rect.toMap();
      final fromMap = CropRect.fromMap(map);
      expect(fromMap, rect);
    });

    test('copyWith updates selected fields', () {
      const rect = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      final updated = rect.copyWith(width: 0.5);
      expect(updated.x, 0.1);
      expect(updated.y, 0.2);
      expect(updated.width, 0.5);
      expect(updated.height, 0.4);
    });
  });

  group('CropOptions', () {
    test('toMap/fromMap round-trip', () {
      const options = CropOptions(
        enableCrop: true,
        aspectRatio: 1.0,
        freeform: false,
        showGrid: false,
        lockAspectRatio: true,
        cropRect: CropRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
      );

      final map = options.toMap();
      final fromMap = CropOptions.fromMap(map);
      expect(fromMap, options);
    });

    test('copyWith updates selected fields', () {
      const options = CropOptions(enableCrop: false, showGrid: true);
      final updated = options.copyWith(enableCrop: true, showGrid: false);
      expect(updated.enableCrop, true);
      expect(updated.showGrid, false);
    });

    test('preset aspect ratios are stable', () {
      expect(CropOptions.square.enableCrop, true);
      expect(CropOptions.square.lockAspectRatio, true);
      expect(CropOptions.square.aspectRatio, 1.0);

      expect(CropOptions.portrait.aspectRatio, closeTo(3.0 / 4.0, 1e-12));
      expect(CropOptions.landscape.aspectRatio, closeTo(4.0 / 3.0, 1e-12));
      expect(CropOptions.widescreen.aspectRatio, closeTo(16.0 / 9.0, 1e-12));
    });
  });
}
