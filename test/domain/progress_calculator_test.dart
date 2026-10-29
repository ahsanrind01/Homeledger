import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/domain/progress_calculator.dart';

void main() {
  group('ProgressCalculator', () {
    // -------------------------------------------------------------------------
    // Test Case 1: 100 required hours, 100-day year, today = day 50
    //
    // Numbers:
    // - requiredHours = 100 -> requiredMinutes = 100 * 60 = 6,000 min
    // - totalSchoolDays = 100 days (e.g. 2026-01-01 to 2026-04-10 inclusive)
    // - elapsedSchoolDays = 50 days (2026-02-19)
    // - expectedMinutes = (6000 * 50) / 100 = 3,000 min (50.0 hours)
    // - paceThreshold = 3,000 * 0.90 = 2,700 min (45.0 hours)
    //
    // Evaluation:
    // - 45.0 hours = 2,700 min: 2,700 >= 2,700 -> On pace (OnPace)
    // - 44.9 hours = 2,694 min: 2,694 < 2,700 -> Behind
    // -------------------------------------------------------------------------
    test(
        '100 required hours, 100-day year, today = day 50: 45.0 h is OnPace, 44.9 h is Behind',
        () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 4, 10); // 100 days total inclusive
      final day50 = DateTime(2026, 2, 19); // 50th day

      // 45.0 hours = 2700 minutes
      final resultOnPace = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        minutesDone: 2700,
        daysLogged: 50,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: day50,
      );

      expect(resultOnPace.totalSchoolDays, 100);
      expect(resultOnPace.elapsedSchoolDays, 50);
      expect(resultOnPace.expectedMinutes, 3000);
      expect(resultOnPace.status, ProgressStatus.onPace);
      expect(resultOnPace.percentOfRequirement, 45.0);

      // 44.9 hours = 2694 minutes
      final resultBehind = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        minutesDone: 2694,
        daysLogged: 50,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: day50,
      );

      expect(resultBehind.expectedMinutes, 3000);
      expect(resultBehind.status, ProgressStatus.behind);
      expect(resultBehind.percentOfRequirement, closeTo(44.9, 0.01));
    });

    // -------------------------------------------------------------------------
    // Test Case 2: Day 1 with 0 hours
    //
    // Numbers:
    // - requiredHours = 100 (6,000 min), 100-day year
    // - Day 1: elapsed = 1
    // - expectedMinutes = (6000 * 1) / 100 = 60 min (1 hour)
    // - paceThreshold = 60 * 0.90 = 54 min
    // - minutesDone = 0 min
    // - 0 < 54 -> Behind
    //
    // FAIRNESS COMMENT:
    // On the morning of Day 1 before any instruction has occurred, the formula
    // immediately marks the student as 'Behind' because 1 hour is expected.
    // This can feel punitive or discouraging to a parent opening the app on their
    // very first day of school. (Flagged for product decision in review).
    // -------------------------------------------------------------------------
    test('Day 1 with 0 hours: expected is 1 h, so 0 is Behind', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 4, 10); // 100 days
      final day1 = DateTime(2026, 1, 1); // First day

      final result = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        minutesDone: 0,
        daysLogged: 0,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: day1,
      );

      expect(result.elapsedSchoolDays, 1);
      expect(result.expectedMinutes, 60); // 1 hour expected
      expect(result.status, ProgressStatus.behind);
      expect(result.minutesRemaining, 6000);
    });

    // -------------------------------------------------------------------------
    // Test Case 3: Today before the start: NotStarted
    //
    // Numbers:
    // - start = 2026-09-01, today = 2026-08-31
    // - elapsed = 0, expected = 0
    // - status = NotStarted
    // -------------------------------------------------------------------------
    test('Today before the start: NotStarted', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2027, 6, 30);
      final beforeStart = DateTime(2026, 8, 31);

      final result = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        minutesDone: 0,
        daysLogged: 0,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: beforeStart,
      );

      expect(result.status, ProgressStatus.notStarted);
      expect(result.elapsedSchoolDays, 0);
      expect(result.expectedMinutes, 0);
      expect(result.daysRemainingInYear, result.totalSchoolDays);
    });

    // -------------------------------------------------------------------------
    // Test Case 4: Today after the end: Finished
    //
    // Numbers:
    // - start = 2026-09-01, end = 2027-06-30, today = 2027-07-01
    // - elapsed = total, expected = required
    // - status = Finished, final percentage shown
    // -------------------------------------------------------------------------
    test('Today after the end: Finished', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2027, 6, 30);
      final afterEnd = DateTime(2027, 7, 1);

      final result = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        minutesDone: 6000,
        daysLogged: 180,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: afterEnd,
      );

      expect(result.status, ProgressStatus.finished);
      expect(result.elapsedSchoolDays, result.totalSchoolDays);
      expect(result.expectedMinutes, 6000);
      expect(result.percentOfRequirement, 100.0);
      expect(result.daysRemainingInYear, 0);
    });

    // -------------------------------------------------------------------------
    // Test Case 5: Today equals the end date
    //
    // Numbers:
    // - start = 2026-09-01, end = 2027-06-30, today = 2027-06-30
    // - elapsed = total, expected = required
    // - If done >= 90%, status is OnPace (or Behind if < 90%)
    // -------------------------------------------------------------------------
    test('Today equals the end date', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2027, 6, 30);
      final lastDay = DateTime(2027, 6, 30);

      // On pace on final day (e.g. 95% done)
      final resultOnPace = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        minutesDone: 5700,
        daysLogged: 180,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: lastDay,
      );

      expect(resultOnPace.elapsedSchoolDays, resultOnPace.totalSchoolDays);
      expect(resultOnPace.daysRemainingInYear, 0);
      expect(resultOnPace.expectedMinutes, 6000);
      expect(resultOnPace.status, ProgressStatus.onPace);

      // Behind on final day (e.g. 50% done)
      final resultBehind = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        minutesDone: 3000,
        daysLogged: 100,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: lastDay,
      );

      expect(resultBehind.status, ProgressStatus.behind);
    });

    // -------------------------------------------------------------------------
    // Test Case 6: A school year that contains 29 February (Leap Year)
    //
    // Numbers:
    // - 2028 is a leap year (February has 29 days)
    // - Start: 2028-02-01, End: 2028-03-01
    // - Total days = 29 (Feb) + 1 (March 1) = 30 calendar days
    // -------------------------------------------------------------------------
    test('A school year that contains 29 February', () {
      final start = DateTime(2028, 2, 1);
      final end = DateTime(2028, 3, 1);
      final today = DateTime(2028, 2, 29); // Leap day

      final result = ProgressCalculator.calculate(
        requiredMinutes: 3000,
        minutesDone: 2900,
        daysLogged: 29,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: today,
      );

      expect(result.totalSchoolDays, 30);
      expect(result.elapsedSchoolDays, 29);
      expect(result.daysRemainingInYear, 1);
    });

    // -------------------------------------------------------------------------
    // Test Case 7: A school year that crosses a year end (September to June)
    //
    // Numbers:
    // - Start: 2026-09-01, End: 2027-06-30
    // - Days count:
    //   Sep: 30, Oct: 31, Nov: 30, Dec: 31,
    //   Jan: 31, Feb: 28, Mar: 31, Apr: 30, May: 31, Jun: 30
    //   Total = 303 calendar days
    // -------------------------------------------------------------------------
    test('A school year that crosses a year end (September to June)', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2027, 6, 30);
      final midYear = DateTime(2027, 1, 15);

      final result = ProgressCalculator.calculate(
        requiredMinutes: 60000,
        minutesDone: 30000,
        daysLogged: 90,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );

      expect(result.totalSchoolDays, 303);
      // Sep(30) + Oct(31) + Nov(30) + Dec(31) + Jan 1..15(15) = 137 days
      expect(result.elapsedSchoolDays, 137);
      expect(result.daysRemainingInYear, 303 - 137);
    });

    // -------------------------------------------------------------------------
    // Test Case 8: A DST change inside the year; identical to a run without DST
    //
    // Numbers:
    // - Testing date calculation across US DST fall-back (Nov 2026) and spring-forward (Mar 2027).
    // - Normalizing to UTC date-only ensures 23-hour or 25-hour local days cannot alter calendar day counts.
    // -------------------------------------------------------------------------
    test('A DST change inside the year; the result must be identical to a run without DST',
        () {
      // Create local DateTimes that cross DST
      final start = DateTime(2026, 10, 15, 14, 30); // Pre-DST transition
      final end = DateTime(2027, 4, 15, 9, 15); // Post-DST spring forward
      final today = DateTime(2026, 11, 20, 23, 45); // Post-DST fall back

      // Equivalent pure UTC dates
      final startUtc = DateTime.utc(2026, 10, 15);
      final endUtc = DateTime.utc(2027, 4, 15);
      final todayUtc = DateTime.utc(2026, 11, 20);

      final resultLocal = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        minutesDone: 2000,
        daysLogged: 30,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: today,
      );

      final resultUtc = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        minutesDone: 2000,
        daysLogged: 30,
        schoolYearStart: startUtc,
        schoolYearEnd: endUtc,
        today: todayUtc,
      );

      expect(resultLocal.totalSchoolDays, resultUtc.totalSchoolDays);
      expect(resultLocal.elapsedSchoolDays, resultUtc.elapsedSchoolDays);
      expect(resultLocal.expectedMinutes, resultUtc.expectedMinutes);
      expect(resultLocal.status, resultUtc.status);
    });

    // -------------------------------------------------------------------------
    // Test Case 9: A start and end on the same day (1 total day)
    //
    // Numbers:
    // - Start: 2026-10-19, End: 2026-10-19
    // - totalSchoolDays = 1
    // - elapsed = 1
    // - No division by zero
    // -------------------------------------------------------------------------
    test('A start and end on the same day (1 total day)', () {
      final date = DateTime(2026, 10, 19);

      final result = ProgressCalculator.calculate(
        requiredMinutes: 300,
        minutesDone: 280,
        daysLogged: 1,
        schoolYearStart: date,
        schoolYearEnd: date,
        today: date,
      );

      expect(result.totalSchoolDays, 1);
      expect(result.elapsedSchoolDays, 1);
      expect(result.expectedMinutes, 300);
      expect(result.status, ProgressStatus.onPace); // 280 >= 300 * 0.90 (270)
    });

    // -------------------------------------------------------------------------
    // Test Case 10: Days-only rule; and hours-and-days rule where only one is behind
    //
    // Numbers:
    // - Days only: requiredHours = null, requiredDays = 180. Hours not judged.
    // - Hours & Days: Hours on pace (50/50 h), but days behind (10/50 days) -> overall Behind.
    // -------------------------------------------------------------------------
    test('A days-only rule; an hours-and-days rule where only one is behind',
        () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 4, 10); // 100 days
      final day50 = DateTime(2026, 2, 19); // 50th day

      // Part 1: Days only rule
      final daysOnlyResult = ProgressCalculator.calculate(
        requiredMinutes: null, // Hours not judged
        requiredDays: 100,
        minutesDone: 0,
        daysLogged: 45, // 45 >= 50 * 0.90 (45) -> On pace
        schoolYearStart: start,
        schoolYearEnd: end,
        today: day50,
      );

      expect(daysOnlyResult.requiredMinutes, isNull);
      expect(daysOnlyResult.minutesStatus, isNull);
      expect(daysOnlyResult.daysStatus, ProgressStatus.onPace);
      expect(daysOnlyResult.status, ProgressStatus.onPace);

      // Part 2: Hours and Days rule where hours is on pace but days is behind
      // Expected on day 50: 3,000 min hours, 50 days.
      // Logged: 3,000 min (On pace), but only 10 days logged (Behind).
      final mixedResult = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        requiredDays: 100,
        minutesDone: 3000, // On pace for hours
        daysLogged: 10, // Far behind on days (threshold is 45)
        schoolYearStart: start,
        schoolYearEnd: end,
        today: day50,
      );

      expect(mixedResult.minutesStatus, ProgressStatus.onPace);
      expect(mixedResult.daysStatus, ProgressStatus.behind);
      expect(mixedResult.status, ProgressStatus.behind); // Behind because days is behind
    });

    // -------------------------------------------------------------------------
    // Test Case 11: Core subject minutes are summed correctly and a missing core subject shows 0
    //
    // Numbers:
    // - coreSubjects: ['Math', 'Reading', 'Science']
    // - logged: {'Math': 120, 'Reading': 90}
    // - result: Math: 120, Reading: 90, Science: 0. Total = 210.
    // -------------------------------------------------------------------------
    test('Core subject minutes are summed correctly and a missing core subject shows 0',
        () {
      final date = DateTime(2026, 10, 19);

      final result = ProgressCalculator.calculate(
        requiredMinutes: 1000,
        minutesDone: 210,
        daysLogged: 5,
        coreSubjects: const ['Math', 'Reading', 'Science'],
        coreMinutesBySubject: const {
          'Math': 120,
          'Reading': 90,
          'Art': 60, // Non-core subject
        },
        schoolYearStart: date,
        schoolYearEnd: DateTime(2026, 11, 19),
        today: date,
      );

      expect(result.coreSubjectMinutes['Math'], 120);
      expect(result.coreSubjectMinutes['Reading'], 90);
      expect(result.coreSubjectMinutes['Science'], 0); // Missing core subject shows 0
      expect(result.coreSubjectMinutes.containsKey('Art'), isFalse);
      expect(result.totalCoreMinutes, 120 + 90 + 0); // 210 minutes
    });

    // -------------------------------------------------------------------------
    // Test Case 12: End before start returns the error result
    //
    // Numbers:
    // - Start: 2026-10-20, End: 2026-10-10
    // - Returns invalidDates error result with isInvalidDates = true
    // -------------------------------------------------------------------------
    test('End before start returns the error result', () {
      final start = DateTime(2026, 10, 20);
      final end = DateTime(2026, 10, 10);
      final today = DateTime(2026, 10, 15);

      final result = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        minutesDone: 100,
        daysLogged: 2,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: today,
      );

      expect(result.isInvalidDates, isTrue);
      expect(result.status, ProgressStatus.invalidDates);
      expect(result.errorMessage, contains('cannot be before start date'));
      expect(result.totalSchoolDays, 0);
    });
  });
}
