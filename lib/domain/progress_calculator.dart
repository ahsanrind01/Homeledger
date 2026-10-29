import '../core/constants.dart';
import 'progress_metric_row.dart';

export 'progress_metric_row.dart';

/// Progress evaluation status for a homeschooling student.
///
/// Disclaimers: Records tool, not legal advice.
enum ProgressStatus {
  notStarted('Not started'),
  onPace('On pace'),
  behind('Behind'),
  finished('Finished'),
  invalidDates('Invalid dates');

  final String label;
  const ProgressStatus(this.label);
}

/// The immutable calculated progress result.
class ProgressResult {
  /// Overall progress status.
  final ProgressStatus status;

  /// Whether the school year date range was invalid (end before start).
  final bool isInvalidDates;

  /// Diagnostic error message if dates were invalid.
  final String? errorMessage;

  /// Total calendar days in the school year (inclusive of start and end).
  final int totalSchoolDays;

  /// Elapsed school days up to and including [today] (clamped between 0 and [totalSchoolDays]).
  final int elapsedSchoolDays;

  /// Remaining school days in the calendar school year.
  final int daysRemainingInYear;

  // --- Minutes / Hours Metrics ---

  /// Total required minutes for the school year, if applicable.
  final int? requiredMinutes;

  /// Expected minutes to date based on elapsed school days.
  final int? expectedMinutes;

  /// Total minutes logged to date.
  final int minutesDone;

  /// Minutes remaining to reach the full requirement (clamped to >= 0).
  final int? minutesRemaining;

  /// Percentage of total required minutes achieved to date.
  final double? percentOfRequirement;

  /// Status of the minute requirement specifically.
  final ProgressStatus? minutesStatus;

  // --- Days Metrics ---

  /// Total required school days, if applicable.
  final int? requiredDays;

  /// Expected school days to date based on elapsed school days.
  final int? expectedDays;

  /// Total distinct days logged to date.
  final int daysLogged;

  /// Days remaining to reach the full day requirement (clamped to >= 0).
  final int? daysRemaining;

  /// Percentage of total required days achieved to date.
  final double? percentOfDaysRequirement;

  /// Status of the day requirement specifically.
  final ProgressStatus? daysStatus;

  // --- Core Subjects ---

  /// Minutes completed for each core subject (missing core subjects map to 0).
  final Map<String, int> coreSubjectMinutes;

  /// Total minutes completed across all core subjects.
  final int totalCoreMinutes;

  const ProgressResult({
    required this.status,
    this.isInvalidDates = false,
    this.errorMessage,
    required this.totalSchoolDays,
    required this.elapsedSchoolDays,
    required this.daysRemainingInYear,
    this.requiredMinutes,
    this.expectedMinutes,
    required this.minutesDone,
    this.minutesRemaining,
    this.percentOfRequirement,
    this.minutesStatus,
    this.requiredDays,
    this.expectedDays,
    required this.daysLogged,
    this.daysRemaining,
    this.percentOfDaysRequirement,
    this.daysStatus,
    this.coreSubjectMinutes = const {},
    this.totalCoreMinutes = 0,
  });

  /// Factory constructor for invalid date errors (e.g. end before start).
  factory ProgressResult.invalidDates({
    required String errorMessage,
    required int minutesDone,
    required int daysLogged,
    Map<String, int> coreSubjectMinutes = const {},
    int totalCoreMinutes = 0,
  }) {
    return ProgressResult(
      status: ProgressStatus.invalidDates,
      isInvalidDates: true,
      errorMessage: errorMessage,
      totalSchoolDays: 0,
      elapsedSchoolDays: 0,
      daysRemainingInYear: 0,
      minutesDone: minutesDone,
      daysLogged: daysLogged,
      coreSubjectMinutes: coreSubjectMinutes,
      totalCoreMinutes: totalCoreMinutes,
    );
  }

  /// Formatted metric requirement rows to show on Home and PDF.
  ///
  /// Each row displays '`<done>` of `<required>` hours' or '`<done>` of `<required>` days'
  /// with its own status chip (On pace / Behind / Finished).
  /// Metrics with zero or null requirements are omitted.
  List<ProgressMetricRow> get metricRows => computeProgressMetricRows(
        requiredMinutes: requiredMinutes,
        requiredDays: requiredDays,
        minutesDone: minutesDone,
        daysLogged: daysLogged,
        minutesStatus: minutesStatus,
        daysStatus: daysStatus,
        percentOfRequirement: percentOfRequirement,
        percentOfDaysRequirement: percentOfDaysRequirement,
      );
}

/// Pure Dart calculator for student progress against state or custom requirements.
///
/// Takes plain values in, performs pure date-only math, and outputs [ProgressResult].
/// Never accesses the database or system clock directly.
class ProgressCalculator {
  const ProgressCalculator._();

  /// Calculates the progress result for a student.
  ///
  /// Mathematical and Date Rules:
  /// 1. All dates are converted to UTC calendar dates (year, month, day) so that
  ///    time of day, timezones, and Daylight Saving Time (DST) shifts cannot alter day counts.
  /// 2. Total school days = (end - start) in calendar days + 1.
  /// 3. Elapsed school days = (today - start) + 1, clamped between 0 and total school days.
  /// 4. Expected values: (required * elapsed / total).
  ///    We compute this using floating-point division and round to the nearest integer
  ///    because all time in Homeledger is tracked in discrete integer minutes.
  /// 5. On pace rule: A student is [ProgressStatus.onPace] if done >= [kEnoughPaceFactor] (0.90)
  ///    of expected, otherwise [ProgressStatus.behind].
  /// 6. Before start: [ProgressStatus.notStarted], expected 0.
  /// 7. After end: [ProgressStatus.finished], final figures shown.
  /// 8. If both hours and days are required, overall status is [ProgressStatus.behind]
  ///    if either is behind.
  static ProgressResult calculate({
    int? requiredMinutes,
    int? requiredDays,
    required int minutesDone,
    required int daysLogged,
    Map<String, int> coreMinutesBySubject = const {},
    List<String> coreSubjects = const [],
    required DateTime schoolYearStart,
    required DateTime schoolYearEnd,
    required DateTime today,
  }) {
    // 1. Date-only normalization: strips hours, minutes, and time zone offsets
    final startUtc = DateTime.utc(
      schoolYearStart.year,
      schoolYearStart.month,
      schoolYearStart.day,
    );
    final endUtc = DateTime.utc(
      schoolYearEnd.year,
      schoolYearEnd.month,
      schoolYearEnd.day,
    );
    final todayUtc = DateTime.utc(
      today.year,
      today.month,
      today.day,
    );

    // 2. Validate calendar bounds (avoid division by zero or negative days)
    if (endUtc.isBefore(startUtc)) {
      return ProgressResult.invalidDates(
        errorMessage: 'School year end date cannot be before start date.',
        minutesDone: minutesDone,
        daysLogged: daysLogged,
      );
    }

    // 3. Compute calendar day metrics
    final totalSchoolDays = endUtc.difference(startUtc).inDays + 1;

    final int elapsedSchoolDays;
    if (todayUtc.isBefore(startUtc)) {
      elapsedSchoolDays = 0;
    } else if (todayUtc.isAfter(endUtc)) {
      elapsedSchoolDays = totalSchoolDays;
    } else {
      elapsedSchoolDays = todayUtc.difference(startUtc).inDays + 1;
    }

    final daysRemainingInYear = (totalSchoolDays - elapsedSchoolDays).clamp(
      0,
      totalSchoolDays,
    );

    // 4. Resolve core subject minutes
    final resolvedCoreSubjectMinutes = <String, int>{};
    for (final subject in coreSubjects) {
      resolvedCoreSubjectMinutes[subject] = coreMinutesBySubject[subject] ?? 0;
    }
    final totalCoreMinutes = resolvedCoreSubjectMinutes.values.fold<int>(
      0,
      (sum, m) => sum + m,
    );

    final bool isBeforeStart = todayUtc.isBefore(startUtc);
    final bool isAfterEnd = todayUtc.isAfter(endUtc);

    // 5. Evaluate Minutes / Hours metrics
    int? expectedMinutes;
    int? minutesRemaining;
    double? percentOfRequirement;
    ProgressStatus? minutesStatus;

    if (requiredMinutes != null) {
      if (isBeforeStart) {
        expectedMinutes = 0;
        minutesStatus = ProgressStatus.notStarted;
      } else if (isAfterEnd) {
        expectedMinutes = requiredMinutes;
        minutesStatus = ProgressStatus.finished;
      } else {
        // expected = required * elapsed / total
        expectedMinutes = ((requiredMinutes * elapsedSchoolDays) / totalSchoolDays).round();
        if (requiredMinutes > 0 && minutesDone >= requiredMinutes) {
          minutesStatus = ProgressStatus.finished;
        } else {
          final threshold = expectedMinutes * kEnoughPaceFactor;
          minutesStatus =
              minutesDone >= threshold ? ProgressStatus.onPace : ProgressStatus.behind;
        }
      }

      minutesRemaining = (requiredMinutes - minutesDone).clamp(0, requiredMinutes);
      percentOfRequirement = requiredMinutes > 0
          ? (minutesDone / requiredMinutes) * 100.0
          : 0.0;
    }

    // 6. Evaluate Days metrics
    int? expectedDays;
    int? daysRemaining;
    double? percentOfDaysRequirement;
    ProgressStatus? daysStatus;

    if (requiredDays != null) {
      if (isBeforeStart) {
        expectedDays = 0;
        daysStatus = ProgressStatus.notStarted;
      } else if (isAfterEnd) {
        expectedDays = requiredDays;
        daysStatus = ProgressStatus.finished;
      } else {
        // expected = required * elapsed / total
        expectedDays = ((requiredDays * elapsedSchoolDays) / totalSchoolDays).round();
        if (requiredDays > 0 && daysLogged >= requiredDays) {
          daysStatus = ProgressStatus.finished;
        } else {
          final threshold = expectedDays * kEnoughPaceFactor;
          daysStatus =
              daysLogged >= threshold ? ProgressStatus.onPace : ProgressStatus.behind;
        }
      }

      daysRemaining = (requiredDays - daysLogged).clamp(0, requiredDays);
      percentOfDaysRequirement = requiredDays > 0
          ? (daysLogged / requiredDays) * 100.0
          : 0.0;
    }

    // 7. Determine overall status
    final ProgressStatus overallStatus;
    if (isBeforeStart) {
      overallStatus = ProgressStatus.notStarted;
    } else if (isAfterEnd) {
      overallStatus = ProgressStatus.finished;
    } else {
      final shownStatuses = <ProgressStatus>[
        if (requiredMinutes != null && requiredMinutes > 0 && minutesStatus != null)
          minutesStatus,
        if (requiredDays != null && requiredDays > 0 && daysStatus != null)
          daysStatus,
      ];
      overallStatus = resolveOverallStatus(shownStatuses);
    }

    return ProgressResult(
      status: overallStatus,
      totalSchoolDays: totalSchoolDays,
      elapsedSchoolDays: elapsedSchoolDays,
      daysRemainingInYear: daysRemainingInYear,
      requiredMinutes: requiredMinutes,
      expectedMinutes: expectedMinutes,
      minutesDone: minutesDone,
      minutesRemaining: minutesRemaining,
      percentOfRequirement: percentOfRequirement,
      minutesStatus: minutesStatus,
      requiredDays: requiredDays,
      expectedDays: expectedDays,
      daysLogged: daysLogged,
      daysRemaining: daysRemaining,
      percentOfDaysRequirement: percentOfDaysRequirement,
      daysStatus: daysStatus,
      coreSubjectMinutes: resolvedCoreSubjectMinutes,
      totalCoreMinutes: totalCoreMinutes,
    );
  }
}
