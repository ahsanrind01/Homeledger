import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/domain/progress_calculator.dart';

void main() {
  group('ProgressMetricRow format and computation', () {
    test('formatHoursDone formats whole numbers and decimals correctly', () {
      expect(formatHoursDone(0), '0');
      expect(formatHoursDone(60), '1');
      expect(formatHoursDone(120), '2');
      expect(formatHoursDone(300), '5');
      expect(formatHoursDone(6000), '100');
      expect(formatHoursDone(90), '1.5');
      expect(formatHoursDone(30), '0.5');
    });

    test('computeProgressMetricRows with hours only', () {
      final rows = computeProgressMetricRows(
        requiredMinutes: 6000,
        requiredDays: null,
        minutesDone: 1200,
        daysLogged: 10,
        minutesStatus: ProgressStatus.onPace,
      );

      expect(rows.length, 1);
      expect(rows.first.label, '20 of 100 hours');
      expect(rows.first.status, ProgressStatus.onPace);
      expect(rows.first.statusLabel, 'On pace');
    });

    test('computeProgressMetricRows with days only', () {
      final rows = computeProgressMetricRows(
        requiredMinutes: null,
        requiredDays: 180,
        minutesDone: 500,
        daysLogged: 45,
        daysStatus: ProgressStatus.behind,
      );

      expect(rows.length, 1);
      expect(rows.first.label, '45 of 180 days');
      expect(rows.first.status, ProgressStatus.behind);
      expect(rows.first.statusLabel, 'Behind');
    });

    test('computeProgressMetricRows with both hours and days', () {
      final rows = computeProgressMetricRows(
        requiredMinutes: 6000,
        requiredDays: 180,
        minutesDone: 3000,
        daysLogged: 180,
        minutesStatus: ProgressStatus.onPace,
        daysStatus: ProgressStatus.finished,
      );

      expect(rows.length, 2);
      expect(rows[0].label, '50 of 100 hours');
      expect(rows[0].status, ProgressStatus.onPace);
      expect(rows[1].label, '180 of 180 days');
      expect(rows[1].status, ProgressStatus.finished);
    });

    test('computeProgressMetricRows omits zero or null requirements', () {
      final zeroHours = computeProgressMetricRows(
        requiredMinutes: 0,
        requiredDays: 180,
        minutesDone: 100,
        daysLogged: 50,
        minutesStatus: ProgressStatus.finished,
        daysStatus: ProgressStatus.onPace,
      );
      expect(zeroHours.length, 1);
      expect(zeroHours.first.label, '50 of 180 days');

      final zeroDays = computeProgressMetricRows(
        requiredMinutes: 3000,
        requiredDays: 0,
        minutesDone: 600,
        daysLogged: 5,
        minutesStatus: ProgressStatus.behind,
        daysStatus: ProgressStatus.finished,
      );
      expect(zeroDays.length, 1);
      expect(zeroDays.first.label, '10 of 50 hours');

      final bothNullOrZero = computeProgressMetricRows(
        requiredMinutes: null,
        requiredDays: 0,
        minutesDone: 0,
        daysLogged: 0,
      );
      expect(bothNullOrZero, isEmpty);
    });
  });

  group('resolveOverallStatus worst-of resolution', () {
    test('Behind beats On pace', () {
      expect(
        resolveOverallStatus([ProgressStatus.behind, ProgressStatus.onPace]),
        ProgressStatus.behind,
      );
      expect(
        resolveOverallStatus([ProgressStatus.onPace, ProgressStatus.behind]),
        ProgressStatus.behind,
      );
    });

    test('Behind beats Finished', () {
      expect(
        resolveOverallStatus([ProgressStatus.behind, ProgressStatus.finished]),
        ProgressStatus.behind,
      );
      expect(
        resolveOverallStatus([ProgressStatus.finished, ProgressStatus.behind]),
        ProgressStatus.behind,
      );
    });

    test('On pace beats Finished', () {
      expect(
        resolveOverallStatus([ProgressStatus.onPace, ProgressStatus.finished]),
        ProgressStatus.onPace,
      );
      expect(
        resolveOverallStatus([ProgressStatus.finished, ProgressStatus.onPace]),
        ProgressStatus.onPace,
      );
    });

    test('All Finished yields Finished', () {
      expect(
        resolveOverallStatus([ProgressStatus.finished, ProgressStatus.finished]),
        ProgressStatus.finished,
      );
      expect(
        resolveOverallStatus([ProgressStatus.finished]),
        ProgressStatus.finished,
      );
    });

    test('Single metric status matches metric', () {
      expect(resolveOverallStatus([ProgressStatus.behind]), ProgressStatus.behind);
      expect(resolveOverallStatus([ProgressStatus.onPace]), ProgressStatus.onPace);
    });
  });

  group('ProgressCalculator integration with metric rows & worst-of status', () {
    final start = DateTime(2026, 9, 1);
    final end = DateTime(2027, 6, 30); // ~303 days
    final midYear = DateTime(2027, 1, 15); // ~day 137 (~45% elapsed)

    test('Hours only: Behind, On pace, and Finished', () {
      // 1. Behind
      final behind = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        requiredDays: null,
        minutesDone: 0,
        daysLogged: 0,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(behind.status, ProgressStatus.behind);
      expect(behind.metricRows.length, 1);
      expect(behind.metricRows.first.label, '0 of 100 hours');
      expect(behind.metricRows.first.status, ProgressStatus.behind);

      // 2. On pace
      final onPace = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        requiredDays: null,
        minutesDone: 3000,
        daysLogged: 50,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(onPace.status, ProgressStatus.onPace);
      expect(onPace.metricRows.length, 1);
      expect(onPace.metricRows.first.label, '50 of 100 hours');
      expect(onPace.metricRows.first.status, ProgressStatus.onPace);

      // 3. Finished
      final finished = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        requiredDays: null,
        minutesDone: 6000,
        daysLogged: 70,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(finished.status, ProgressStatus.finished);
      expect(finished.metricRows.length, 1);
      expect(finished.metricRows.first.label, '100 of 100 hours');
      expect(finished.metricRows.first.status, ProgressStatus.finished);
    });

    test('Days only: Behind, On pace, and Finished', () {
      // 1. Behind
      final behind = ProgressCalculator.calculate(
        requiredMinutes: null,
        requiredDays: 180,
        minutesDone: 500,
        daysLogged: 10,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(behind.status, ProgressStatus.behind);
      expect(behind.metricRows.length, 1);
      expect(behind.metricRows.first.label, '10 of 180 days');
      expect(behind.metricRows.first.status, ProgressStatus.behind);

      // 2. On pace
      final onPace = ProgressCalculator.calculate(
        requiredMinutes: null,
        requiredDays: 180,
        minutesDone: 500,
        daysLogged: 90,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(onPace.status, ProgressStatus.onPace);
      expect(onPace.metricRows.length, 1);
      expect(onPace.metricRows.first.label, '90 of 180 days');
      expect(onPace.metricRows.first.status, ProgressStatus.onPace);

      // 3. Finished
      final finished = ProgressCalculator.calculate(
        requiredMinutes: null,
        requiredDays: 180,
        minutesDone: 500,
        daysLogged: 180,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(finished.status, ProgressStatus.finished);
      expect(finished.metricRows.length, 1);
      expect(finished.metricRows.first.label, '180 of 180 days');
      expect(finished.metricRows.first.status, ProgressStatus.finished);
    });

    test('Both requirements with different statuses', () {
      // Hours On pace + Days Behind -> overall Behind
      final onPaceAndBehind = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        requiredDays: 180,
        minutesDone: 3000, // On pace
        daysLogged: 10, // Behind
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(onPaceAndBehind.minutesStatus, ProgressStatus.onPace);
      expect(onPaceAndBehind.daysStatus, ProgressStatus.behind);
      expect(onPaceAndBehind.status, ProgressStatus.behind);
      expect(onPaceAndBehind.metricRows.length, 2);
      expect(onPaceAndBehind.metricRows[0].status, ProgressStatus.onPace);
      expect(onPaceAndBehind.metricRows[1].status, ProgressStatus.behind);

      // Hours Behind + Days On pace -> overall Behind
      final behindAndOnPace = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        requiredDays: 180,
        minutesDone: 300, // Behind
        daysLogged: 90, // On pace
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(behindAndOnPace.minutesStatus, ProgressStatus.behind);
      expect(behindAndOnPace.daysStatus, ProgressStatus.onPace);
      expect(behindAndOnPace.status, ProgressStatus.behind);

      // Hours Finished + Days Behind -> overall Behind
      final finishedAndBehind = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        requiredDays: 180,
        minutesDone: 6000, // Finished
        daysLogged: 10, // Behind
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(finishedAndBehind.minutesStatus, ProgressStatus.finished);
      expect(finishedAndBehind.daysStatus, ProgressStatus.behind);
      expect(finishedAndBehind.status, ProgressStatus.behind);

      // Hours Finished + Days On pace -> overall On pace
      final finishedAndOnPace = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        requiredDays: 180,
        minutesDone: 6000, // Finished
        daysLogged: 90, // On pace
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(finishedAndOnPace.minutesStatus, ProgressStatus.finished);
      expect(finishedAndOnPace.daysStatus, ProgressStatus.onPace);
      expect(finishedAndOnPace.status, ProgressStatus.onPace);

      // Hours On pace + Days Finished -> overall On pace
      final onPaceAndFinished = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        requiredDays: 180,
        minutesDone: 3000, // On pace
        daysLogged: 180, // Finished
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(onPaceAndFinished.minutesStatus, ProgressStatus.onPace);
      expect(onPaceAndFinished.daysStatus, ProgressStatus.finished);
      expect(onPaceAndFinished.status, ProgressStatus.onPace);

      // Hours Finished + Days Finished -> overall Finished
      final allFinished = ProgressCalculator.calculate(
        requiredMinutes: 6000,
        requiredDays: 180,
        minutesDone: 6000, // Finished
        daysLogged: 180, // Finished
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(allFinished.minutesStatus, ProgressStatus.finished);
      expect(allFinished.daysStatus, ProgressStatus.finished);
      expect(allFinished.status, ProgressStatus.finished);
    });

    test('Zero requirement metric is omitted from metricRows', () {
      final res = ProgressCalculator.calculate(
        requiredMinutes: 0,
        requiredDays: 180,
        minutesDone: 100,
        daysLogged: 90,
        schoolYearStart: start,
        schoolYearEnd: end,
        today: midYear,
      );
      expect(res.metricRows.length, 1);
      expect(res.metricRows.first.label, '90 of 180 days');
    });
  });
}
