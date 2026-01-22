@TestOn('vm')
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/crop_options.dart';

void main() {
  group('CropRect', () {
    test('toMap creates correct map', () {
      const rect = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      final map = rect.toMap();

      expect(map['x'], 0.1);
      expect(map['y'], 0.2);
      expect(map['width'], 0.3);
      expect(map['height'], 0.4);
    });

    test('fromMap creates correct CropRect', () {
      final map = {
        'x': 0.1,
        'y': 0.2,
        'width': 0.3,
        'height': 0.4,
      };
      final rect = CropRect.fromMap(map);

      expect(rect.x, 0.1);
      expect(rect.y, 0.2);
      expect(rect.width, 0.3);
      expect(rect.height, 0.4);
    });

    test('toMap/fromMap round-trip', () {
      const rect = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      final map = rect.toMap();
      final fromMap = CropRect.fromMap(map);

      expect(fromMap, rect);
    });

    test('fromMap handles int values', () {
      final map = {
        'x': 10,
        'y': 20,
        'width': 30,
        'height': 40,
      };
      final rect = CropRect.fromMap(map);

      expect(rect.x, 10.0);
      expect(rect.y, 20.0);
      expect(rect.width, 30.0);
      expect(rect.height, 40.0);
    });

    test('copyWith updates specified fields', () {
      const rect = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      final updated = rect.copyWith(x: 0.5, height: 0.6);

      expect(updated.x, 0.5);
      expect(updated.y, 0.2); // Unchanged
      expect(updated.width, 0.3); // Unchanged
      expect(updated.height, 0.6);
    });

    test('copyWith preserves all fields when no parameters provided', () {
      const rect = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      final updated = rect.copyWith();

      expect(updated, rect);
    });

    test('toString returns correct format', () {
      const rect = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      final str = rect.toString();

      expect(str, contains('0.1'));
      expect(str, contains('0.2'));
      expect(str, contains('0.3'));
      expect(str, contains('0.4'));
    });

    test('equality operator works correctly', () {
      const rect1 = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      const rect2 = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      const rect3 = CropRect(x: 0.5, y: 0.2, width: 0.3, height: 0.4);

      expect(rect1 == rect2, isTrue);
      expect(rect1 == rect3, isFalse);
      expect(rect1 == rect1, isTrue); // Identical check
    });

    test('hashCode is consistent', () {
      const rect1 = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      const rect2 = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);

      expect(rect1.hashCode, rect2.hashCode);
    });
  });

  group('CropOptions', () {
    test('default constructor values', () {
      const options = CropOptions();

      expect(options.cropRect, isNull);
      expect(options.enableCrop, false);
      expect(options.aspectRatio, isNull);
      expect(options.freeform, true);
      expect(options.showGrid, true);
      expect(options.lockAspectRatio, false);
    });

    test('constructor with all parameters', () {
      const cropRect = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      const options = CropOptions(
        cropRect: cropRect,
        enableCrop: true,
        aspectRatio: 4.0 / 3.0,
        freeform: false,
        showGrid: false,
        lockAspectRatio: true,
      );

      expect(options.cropRect, cropRect);
      expect(options.enableCrop, true);
      expect(options.aspectRatio, 4.0 / 3.0);
      expect(options.freeform, false);
      expect(options.showGrid, false);
      expect(options.lockAspectRatio, true);
    });

    test('toMap includes all fields', () {
      const cropRect = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      const options = CropOptions(
        cropRect: cropRect,
        enableCrop: true,
        aspectRatio: 4.0 / 3.0,
        freeform: false,
        showGrid: false,
        lockAspectRatio: true,
      );

      final map = options.toMap();

      expect(map['cropRect'], isNotNull);
      expect(map['enableCrop'], true);
      expect(map['aspectRatio'], 4.0 / 3.0);
      expect(map['freeform'], false);
      expect(map['showGrid'], false);
      expect(map['lockAspectRatio'], true);
    });

    test('toMap handles null cropRect', () {
      const options = CropOptions();
      final map = options.toMap();

      expect(map['cropRect'], isNull);
    });

    test('fromMap creates correct CropOptions', () {
      final map = {
        'cropRect': {
          'x': 0.1,
          'y': 0.2,
          'width': 0.3,
          'height': 0.4,
        },
        'enableCrop': true,
        'aspectRatio': 4.0 / 3.0,
        'freeform': false,
        'showGrid': false,
        'lockAspectRatio': true,
      };

      final options = CropOptions.fromMap(map);

      expect(options.cropRect, isNotNull);
      expect(options.cropRect!.x, 0.1);
      expect(options.enableCrop, true);
      expect(options.aspectRatio, 4.0 / 3.0);
      expect(options.freeform, false);
      expect(options.showGrid, false);
      expect(options.lockAspectRatio, true);
    });

    test('fromMap handles null cropRect', () {
      final map = {
        'enableCrop': false,
        'freeform': true,
        'showGrid': true,
        'lockAspectRatio': false,
      };

      final options = CropOptions.fromMap(map);

      expect(options.cropRect, isNull);
    });

    test('fromMap uses default values when fields are missing', () {
      final map = <String, dynamic>{};

      final options = CropOptions.fromMap(map);

      expect(options.enableCrop, false);
      expect(options.freeform, true);
      expect(options.showGrid, true);
      expect(options.lockAspectRatio, false);
    });

    test('copyWith updates specified fields', () {
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

    test('copyWith preserves all fields when no parameters provided', () {
      const options = CropOptions(
        enableCrop: true,
        aspectRatio: 4.0 / 3.0,
      );
      final updated = options.copyWith();

      expect(updated, options);
    });

    test('copyWith can update cropRect', () {
      const rect1 = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      const rect2 = CropRect(x: 0.5, y: 0.6, width: 0.7, height: 0.8);
      const options = CropOptions(cropRect: rect1);

      final updated = options.copyWith(cropRect: rect2);

      expect(updated.cropRect, rect2);
    });

    test('toString includes all fields', () {
      const cropRect = CropRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      const options = CropOptions(
        cropRect: cropRect,
        enableCrop: true,
        aspectRatio: 4.0 / 3.0,
        freeform: false,
        showGrid: false,
        lockAspectRatio: true,
      );

      final str = options.toString();

      expect(str, contains('enableCrop'));
      expect(str, contains('aspectRatio'));
      expect(str, contains('freeform'));
      expect(str, contains('showGrid'));
      expect(str, contains('lockAspectRatio'));
    });

    test('equality operator works correctly', () {
      const options1 = CropOptions(
        enableCrop: true,
        aspectRatio: 4.0 / 3.0,
        freeform: false,
      );
      const options2 = CropOptions(
        enableCrop: true,
        aspectRatio: 4.0 / 3.0,
        freeform: false,
      );
      const options3 = CropOptions(
        enableCrop: true,
        aspectRatio: 16.0 / 9.0,
        freeform: false,
      );

      expect(options1 == options2, isTrue);
      expect(options1 == options3, isFalse);
      expect(options1 == options1, isTrue); // Identical check
    });

    test('hashCode is consistent', () {
      const options1 = CropOptions(
        enableCrop: true,
        aspectRatio: 4.0 / 3.0,
      );
      const options2 = CropOptions(
        enableCrop: true,
        aspectRatio: 4.0 / 3.0,
      );

      expect(options1.hashCode, options2.hashCode);
    });

    group('static presets', () {
      test('square preset has correct values', () {
        expect(CropOptions.square.enableCrop, true);
        expect(CropOptions.square.aspectRatio, 1.0);
        expect(CropOptions.square.lockAspectRatio, true);
        expect(CropOptions.square.freeform, false);
      });

      test('portrait preset has correct values', () {
        expect(CropOptions.portrait.enableCrop, true);
        expect(CropOptions.portrait.aspectRatio, 3.0 / 4.0);
        expect(CropOptions.portrait.lockAspectRatio, true);
        expect(CropOptions.portrait.freeform, false);
      });

      test('landscape preset has correct values', () {
        expect(CropOptions.landscape.enableCrop, true);
        expect(CropOptions.landscape.aspectRatio, 4.0 / 3.0);
        expect(CropOptions.landscape.lockAspectRatio, true);
        expect(CropOptions.landscape.freeform, false);
      });

      test('widescreen preset has correct values', () {
        expect(CropOptions.widescreen.enableCrop, true);
        expect(CropOptions.widescreen.aspectRatio, 16.0 / 9.0);
        expect(CropOptions.widescreen.lockAspectRatio, true);
        expect(CropOptions.widescreen.freeform, false);
      });
    });
  });
}
