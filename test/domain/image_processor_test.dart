import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/domain/image_processor.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ImageProcessor', () {
    test('4000x3000 image is resized to 1600x1200 and encoded as JPEG', () {
      // Create synthetic 4000x3000 image
      final source = img.Image(width: 4000, height: 3000);
      img.fill(source, color: img.ColorRgb8(100, 150, 200));
      final rawBytes = Uint8List.fromList(img.encodeJpg(source));

      final processedBytes = processImageBytes(
        rawBytes: rawBytes,
        maxDimension: 1600,
        quality: 80,
      );

      final decoded = img.decodeImage(processedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 1600);
      expect(decoded.height, 1200);
    });

    test('3000x4000 portrait image is resized to 1200x1600', () {
      final source = img.Image(width: 3000, height: 4000);
      img.fill(source, color: img.ColorRgb8(50, 100, 150));
      final rawBytes = Uint8List.fromList(img.encodeJpg(source));

      final processedBytes = processImageBytes(
        rawBytes: rawBytes,
        maxDimension: 1600,
        quality: 80,
      );

      final decoded = img.decodeImage(processedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 1200);
      expect(decoded.height, 1600);
    });

    test('Small image (800x600) is NOT enlarged', () {
      final source = img.Image(width: 800, height: 600);
      img.fill(source, color: img.ColorRgb8(200, 100, 50));
      final rawBytes = Uint8List.fromList(img.encodeJpg(source));

      final processedBytes = processImageBytes(
        rawBytes: rawBytes,
        maxDimension: 1600,
        quality: 80,
      );

      final decoded = img.decodeImage(processedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 800);
      expect(decoded.height, 600);
    });

    test('Invalid image bytes throw FormatException', () {
      final badBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(
        () => processImageBytes(rawBytes: badBytes),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
