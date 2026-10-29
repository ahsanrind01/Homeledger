import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/features/export/export_service.dart';

void main() {
  group('sanitizePdfFileName', () {
    test('Standard child name sanitizes cleanly', () {
      final result = sanitizePdfFileName(
        childName: 'Emma',
        startDate: '2026-09-01',
        endDate: '2027-06-30',
      );
      expect(result, 'homeledger-emma-2026-09-01-to-2027-06-30.pdf');
    });

    test('Child name with spaces and apostrophes replaces with single hyphen', () {
      final result = sanitizePdfFileName(
        childName: "Lucas O'Connor",
        startDate: '2026-09-01',
        endDate: '2027-06-30',
      );
      expect(result, 'homeledger-lucas-oconnor-2026-09-01-to-2027-06-30.pdf');
    });

    test('Special characters, slashes, and accents are sanitized', () {
      final result = sanitizePdfFileName(
        childName: 'Zoë / Renée! #1',
        startDate: '2026-09-01',
        endDate: '2027-06-30',
      );
      expect(result, 'homeledger-zo-ren-e-1-2026-09-01-to-2027-06-30.pdf');
    });

    test('Whitespace-only child name falls back to student', () {
      final result = sanitizePdfFileName(
        childName: '   ',
        startDate: '2026-09-01',
        endDate: '2027-06-30',
      );
      expect(result, 'homeledger-student-2026-09-01-to-2027-06-30.pdf');
    });

    test('Unsafe date strings have non-digits and non-hyphens stripped', () {
      final result = sanitizePdfFileName(
        childName: 'Maya',
        startDate: '2026/09/01',
        endDate: '2027:06:30',
      );
      expect(result, 'homeledger-maya-20260901-to-20270630.pdf');
    });
  });
}
