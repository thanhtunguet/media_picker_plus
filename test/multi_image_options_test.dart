@TestOn('vm')
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/multi_image_options.dart';

void main() {
  group('MultiImageOptions', () {
    test('default values', () {
      const options = MultiImageOptions();
      expect(options.maxImages, isNull);
      expect(options.minImages, 1);
      expect(options.confirmOnDiscard, true);
    });

    test('custom values', () {
      const options = MultiImageOptions(
        maxImages: 5,
        minImages: 2,
        confirmOnDiscard: false,
      );
      expect(options.maxImages, 5);
      expect(options.minImages, 2);
      expect(options.confirmOnDiscard, false);
    });

    test('maxImages null means unlimited', () {
      const options = MultiImageOptions(maxImages: null);
      expect(options.maxImages, isNull);
    });

    test('can be used as const', () {
      // Verifies const constructor works
      const options1 = MultiImageOptions();
      const options2 = MultiImageOptions();
      expect(identical(options1, options2), true);
    });
  });
}
