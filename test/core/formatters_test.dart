import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/core/formatters.dart';

void main() {
  group('formatMinutes', () {
    test('formats hours and minutes', () {
      expect(formatMinutes(135), '2 h 15 min');
    });

    test('formats whole hours', () {
      expect(formatMinutes(120), '2 h');
      expect(formatMinutes(60), '1 h');
    });

    test('formats only minutes under an hour', () {
      expect(formatMinutes(45), '45 min');
      expect(formatMinutes(1), '1 min');
    });

    test('formats zero and negative numbers as 0 min', () {
      expect(formatMinutes(0), '0 min');
      expect(formatMinutes(-10), '0 min');
    });
  });
}
