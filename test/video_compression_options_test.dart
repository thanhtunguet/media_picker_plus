@TestOn('vm')
import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plus/video_compression_options.dart';

void main() {
  group('VideoCompressionQuality', () {
    test('all quality presets have correct maxHeight and bitrate', () {
      expect(VideoCompressionQuality.p360.maxHeight, 360);
      expect(VideoCompressionQuality.p360.bitrate, 400000);

      expect(VideoCompressionQuality.p480.maxHeight, 480);
      expect(VideoCompressionQuality.p480.bitrate, 800000);

      expect(VideoCompressionQuality.p720.maxHeight, 720);
      expect(VideoCompressionQuality.p720.bitrate, 2000000);

      expect(VideoCompressionQuality.p1080.maxHeight, 1080);
      expect(VideoCompressionQuality.p1080.bitrate, 4000000);

      expect(VideoCompressionQuality.original.maxHeight, 0);
      expect(VideoCompressionQuality.original.bitrate, 0);
    });

    group('calculateWidth', () {
      test('returns original width when maxHeight is 0 (original quality)', () {
        const quality = VideoCompressionQuality.original;
        expect(quality.calculateWidth(1920, 1080), 1920);
        expect(quality.calculateWidth(3840, 2160), 3840);
      });

      test('calculates width maintaining aspect ratio when height is reduced',
          () {
        const quality = VideoCompressionQuality.p720;
        // 1920x1080 -> should be 1280x720 (16:9 ratio maintained)
        expect(quality.calculateWidth(1920, 1080), 1280);
        // 1280x720 -> should remain 1280x720 (already at max)
        expect(quality.calculateWidth(1280, 720), 1280);
      });

      test('handles portrait orientation correctly', () {
        const quality = VideoCompressionQuality.p720;
        // 1080x1920 portrait -> should be 720x1280
        expect(quality.calculateWidth(1080, 1920), 405);
      });

      test('handles square aspect ratio', () {
        const quality = VideoCompressionQuality.p720;
        // 1920x1920 square -> should be 720x720
        expect(quality.calculateWidth(1920, 1920), 720);
      });

      test(
          'returns original width when original height is smaller than maxHeight',
          () {
        const quality = VideoCompressionQuality.p720;
        // 640x480 -> should remain 640x480 (no upscaling)
        expect(quality.calculateWidth(640, 480), 640);
      });
    });

    group('calculateHeight', () {
      test('returns original height when maxHeight is 0 (original quality)',
          () {
        const quality = VideoCompressionQuality.original;
        expect(quality.calculateHeight(1080), 1080);
        expect(quality.calculateHeight(2160), 2160);
      });

      test('returns maxHeight when original height is larger', () {
        const quality = VideoCompressionQuality.p720;
        expect(quality.calculateHeight(1080), 720);
        expect(quality.calculateHeight(2160), 720);
      });

      test('returns original height when it is smaller than maxHeight', () {
        const quality = VideoCompressionQuality.p720;
        expect(quality.calculateHeight(480), 480);
        expect(quality.calculateHeight(360), 360);
      });

      test('returns maxHeight when original height equals maxHeight', () {
        const quality = VideoCompressionQuality.p720;
        expect(quality.calculateHeight(720), 720);
      });
    });
  });

  group('VideoCompressionOptions', () {
    test('default constructor uses p720 quality', () {
      const options = VideoCompressionOptions();
      expect(options.quality, VideoCompressionQuality.p720);
      expect(options.customBitrate, isNull);
      expect(options.customWidth, isNull);
      expect(options.customHeight, isNull);
      expect(options.outputFormat, 'mp4');
      expect(options.deleteOriginalFile, false);
      expect(options.onProgress, isNull);
    });

    test('constructor with all parameters', () {
      void progressCallback(double progress) {}
      final options = VideoCompressionOptions(
        quality: VideoCompressionQuality.p1080,
        customBitrate: 5000000,
        customWidth: 1920,
        customHeight: 1080,
        outputFormat: 'mov',
        deleteOriginalFile: true,
        onProgress: progressCallback,
      );

      expect(options.quality, VideoCompressionQuality.p1080);
      expect(options.customBitrate, 5000000);
      expect(options.customWidth, 1920);
      expect(options.customHeight, 1080);
      expect(options.outputFormat, 'mov');
      expect(options.deleteOriginalFile, true);
      expect(options.onProgress, progressCallback);
    });

    group('targetBitrate', () {
      test('returns customBitrate when provided', () {
        const options = VideoCompressionOptions(customBitrate: 10000000);
        expect(options.targetBitrate, 10000000);
      });

      test('returns quality bitrate when customBitrate is null', () {
        const options = VideoCompressionOptions(
          quality: VideoCompressionQuality.p1080,
        );
        expect(options.targetBitrate, VideoCompressionQuality.p1080.bitrate);
      });

      test('returns p720 bitrate as fallback when quality is null', () {
        const options = VideoCompressionOptions(quality: null);
        expect(options.targetBitrate, VideoCompressionQuality.p720.bitrate);
      });
    });

    group('getTargetWidth', () {
      test('returns customWidth when provided', () {
        const options = VideoCompressionOptions(customWidth: 1920);
        expect(options.getTargetWidth(3840, 2160), 1920);
      });

      test('uses quality calculateWidth when customWidth is null', () {
        const options = VideoCompressionOptions(
          quality: VideoCompressionQuality.p720,
        );
        expect(options.getTargetWidth(1920, 1080), 1280);
      });

      test('falls back to p720 when quality is null', () {
        const options = VideoCompressionOptions(quality: null);
        expect(options.getTargetWidth(1920, 1080), 1280);
      });
    });

    group('getTargetHeight', () {
      test('returns customHeight when provided', () {
        const options = VideoCompressionOptions(customHeight: 1080);
        expect(options.getTargetHeight(2160), 1080);
      });

      test('uses quality calculateHeight when customHeight is null', () {
        const options = VideoCompressionOptions(
          quality: VideoCompressionQuality.p720,
        );
        expect(options.getTargetHeight(1080), 720);
      });

      test('falls back to p720 when quality is null', () {
        const options = VideoCompressionOptions(quality: null);
        expect(options.getTargetHeight(1080), 720);
      });
    });

    group('toMap', () {
      test('includes all fields with default values', () {
        const options = VideoCompressionOptions();
        final map = options.toMap();

        expect(map['quality'], 'p720');
        expect(map['customBitrate'], isNull);
        expect(map['customWidth'], isNull);
        expect(map['customHeight'], isNull);
        expect(map['outputFormat'], 'mp4');
        expect(map['deleteOriginalFile'], false);
        expect(map['targetBitrate'], VideoCompressionQuality.p720.bitrate);
      });

      test('calculates targetWidth and targetHeight from original dimensions',
          () {
        const options = VideoCompressionOptions(
          quality: VideoCompressionQuality.p720,
        );
        final map = options.toMap(originalWidth: 1920, originalHeight: 1080);

        expect(map['targetWidth'], 1280);
        expect(map['targetHeight'], 720);
      });

      test('uses customWidth and customHeight when provided', () {
        const options = VideoCompressionOptions(
          customWidth: 1920,
          customHeight: 1080,
        );
        final map = options.toMap(originalWidth: 3840, originalHeight: 2160);

        expect(map['customWidth'], 1920);
        expect(map['customHeight'], 1080);
        expect(map['targetWidth'], 1920);
        expect(map['targetHeight'], 1080);
      });

      test(
          'falls back to default dimensions when original dimensions not provided',
          () {
        const options = VideoCompressionOptions();
        final map = options.toMap();

        expect(map['targetWidth'], 1280);
        expect(map['targetHeight'], 720);
      });

      test('uses customWidth when provided without original dimensions', () {
        const options = VideoCompressionOptions(customWidth: 1920);
        final map = options.toMap();

        expect(map['targetWidth'], 1920);
        expect(map['targetHeight'], 720); // Default fallback
      });

      test('uses customHeight when provided without original dimensions', () {
        const options = VideoCompressionOptions(customHeight: 1080);
        final map = options.toMap();

        expect(map['targetWidth'], 1280); // Default fallback
        expect(map['targetHeight'], 1080);
      });

      test('handles original quality correctly', () {
        const options = VideoCompressionOptions(
          quality: VideoCompressionQuality.original,
        );
        final map = options.toMap(originalWidth: 1920, originalHeight: 1080);

        expect(map['quality'], 'original');
        expect(map['targetWidth'], 1920);
        expect(map['targetHeight'], 1080);
      });

      test('includes all custom values', () {
        const options = VideoCompressionOptions(
          quality: VideoCompressionQuality.p1080,
          customBitrate: 5000000,
          customWidth: 1920,
          customHeight: 1080,
          outputFormat: 'mov',
          deleteOriginalFile: true,
        );
        final map = options.toMap();

        expect(map['quality'], 'p1080');
        expect(map['customBitrate'], 5000000);
        expect(map['customWidth'], 1920);
        expect(map['customHeight'], 1080);
        expect(map['outputFormat'], 'mov');
        expect(map['deleteOriginalFile'], true);
        expect(map['targetBitrate'], 5000000); // Uses customBitrate
      });
    });
  });
}
