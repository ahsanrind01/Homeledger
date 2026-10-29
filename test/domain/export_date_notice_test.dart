import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/domain/export_date_notice.dart';

void main() {
  const syStart = '2026-09-01';
  const syEnd = '2027-06-30';

  group('Date Range School Year Notice', () {
    test('range completely inside school year produces no notice', () {
      // Exactly matches school year boundaries
      final exactMatchNotice = computeDateRangeSchoolYearNotice(
        schoolYearStart: syStart,
        schoolYearEnd: syEnd,
        rangeStart: '2026-09-01',
        rangeEnd: '2027-06-30',
      );
      expect(exactMatchNotice, isNull);

      // Sub-range strictly inside school year (October only)
      final subRangeNotice = computeDateRangeSchoolYearNotice(
        schoolYearStart: syStart,
        schoolYearEnd: syEnd,
        rangeStart: '2026-10-01',
        rangeEnd: '2026-10-31',
      );
      expect(subRangeNotice, isNull);

      final overlap = checkDateRangeSchoolYearOverlap(
        schoolYearStart: DateTime.parse(syStart),
        schoolYearEnd: DateTime.parse(syEnd),
        rangeStart: DateTime.parse('2026-10-01'),
        rangeEnd: DateTime.parse('2026-10-31'),
      );
      expect(overlap, DateRangeSchoolYearOverlap.inside);
    });

    test('range starting before school year start produces partly outside notice', () {
      final notice = computeDateRangeSchoolYearNotice(
        schoolYearStart: syStart,
        schoolYearEnd: syEnd,
        rangeStart: '2026-08-01', // Before 2026-09-01
        rangeEnd: '2026-10-31',
      );

      expect(
        notice,
        'Part of this range is outside the school year (2026-09-01 to 2027-06-30). Progress is shown for the school year.',
      );

      final overlap = checkDateRangeSchoolYearOverlap(
        schoolYearStart: DateTime.parse(syStart),
        schoolYearEnd: DateTime.parse(syEnd),
        rangeStart: DateTime.parse('2026-08-01'),
        rangeEnd: DateTime.parse('2026-10-31'),
      );
      expect(overlap, DateRangeSchoolYearOverlap.partlyOutside);
    });

    test('range ending after school year end produces partly outside notice', () {
      final notice = computeDateRangeSchoolYearNotice(
        schoolYearStart: syStart,
        schoolYearEnd: syEnd,
        rangeStart: '2027-05-01',
        rangeEnd: '2027-07-31', // After 2027-06-30
      );

      expect(
        notice,
        'Part of this range is outside the school year (2026-09-01 to 2027-06-30). Progress is shown for the school year.',
      );

      final overlap = checkDateRangeSchoolYearOverlap(
        schoolYearStart: DateTime.parse(syStart),
        schoolYearEnd: DateTime.parse(syEnd),
        rangeStart: DateTime.parse('2027-05-01'),
        rangeEnd: DateTime.parse('2027-07-31'),
      );
      expect(overlap, DateRangeSchoolYearOverlap.partlyOutside);
    });

    test('range spanning both before and after school year produces partly outside notice', () {
      final notice = computeDateRangeSchoolYearNotice(
        schoolYearStart: syStart,
        schoolYearEnd: syEnd,
        rangeStart: '2026-07-01', // Before start
        rangeEnd: '2027-08-01',   // After end
      );

      expect(
        notice,
        'Part of this range is outside the school year (2026-09-01 to 2027-06-30). Progress is shown for the school year.',
      );
    });

    test('range completely before school year produces no overlap notice', () {
      final notice = computeDateRangeSchoolYearNotice(
        schoolYearStart: syStart,
        schoolYearEnd: syEnd,
        rangeStart: '2026-06-01',
        rangeEnd: '2026-08-31', // Before 2026-09-01
      );

      expect(
        notice,
        'This range is outside the school year. The time log is empty for this range.',
      );

      final overlap = checkDateRangeSchoolYearOverlap(
        schoolYearStart: DateTime.parse(syStart),
        schoolYearEnd: DateTime.parse(syEnd),
        rangeStart: DateTime.parse('2026-06-01'),
        rangeEnd: DateTime.parse('2026-08-31'),
      );
      expect(overlap, DateRangeSchoolYearOverlap.noOverlap);
    });

    test('range completely after school year produces no overlap notice', () {
      final notice = computeDateRangeSchoolYearNotice(
        schoolYearStart: syStart,
        schoolYearEnd: syEnd,
        rangeStart: '2027-07-01', // After 2027-06-30
        rangeEnd: '2027-08-31',
      );

      expect(
        notice,
        'This range is outside the school year. The time log is empty for this range.',
      );

      final overlap = checkDateRangeSchoolYearOverlap(
        schoolYearStart: DateTime.parse(syStart),
        schoolYearEnd: DateTime.parse(syEnd),
        rangeStart: DateTime.parse('2027-07-01'),
        rangeEnd: DateTime.parse('2027-08-31'),
      );
      expect(overlap, DateRangeSchoolYearOverlap.noOverlap);
    });

    test('handles invalid date strings gracefully', () {
      final notice = computeDateRangeSchoolYearNotice(
        schoolYearStart: 'invalid',
        schoolYearEnd: syEnd,
        rangeStart: '2026-09-01',
        rangeEnd: '2027-06-30',
      );
      expect(notice, isNull);
    });
  });
}
