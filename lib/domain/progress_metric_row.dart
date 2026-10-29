import 'progress_calculator.dart';

/// Formats an integer minute amount into hours for '`<done>` of `<required>` hours' display.
///
/// Whole hours are displayed as integers (e.g. '0', '5', '100').
/// Fractional hours are formatted to one decimal place (e.g. '1.5').
String formatHoursDone(int minutes) {
  if (minutes <= 0) return '0';
  final hours = minutes / 60.0;
  if (hours == hours.truncateToDouble()) {
    return hours.toInt().toString();
  }
  final fixed = hours.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}

/// A single metric requirement row (hours or days) with label and status.
class ProgressMetricRow {
  final String label;
  final ProgressStatus status;
  final double? percent;

  const ProgressMetricRow({
    required this.label,
    required this.status,
    this.percent,
  });

  String get statusLabel => status.label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressMetricRow &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          status == other.status;

  @override
  int get hashCode => Object.hash(label, status);

  @override
  String toString() => 'ProgressMetricRow($label, ${status.label})';
}

/// Computes the list of metric rows to show.
///
/// Rules:
/// - '`<done>` of `<required>` hours'
/// - '`<done>` of `<required>` days'
/// - Each row with its own status (On pace / Behind / Finished).
/// - Do NOT show a row for a metric whose requirement is zero or null.
List<ProgressMetricRow> computeProgressMetricRows({
  int? requiredMinutes,
  int? requiredDays,
  required int minutesDone,
  required int daysLogged,
  ProgressStatus? minutesStatus,
  ProgressStatus? daysStatus,
  double? percentOfRequirement,
  double? percentOfDaysRequirement,
}) {
  final rows = <ProgressMetricRow>[];

  if (requiredMinutes != null && requiredMinutes > 0 && minutesStatus != null) {
    final reqHours = requiredMinutes ~/ 60;
    final doneStr = formatHoursDone(minutesDone);
    rows.add(
      ProgressMetricRow(
        label: '$doneStr of $reqHours hours',
        status: minutesStatus,
        percent: percentOfRequirement,
      ),
    );
  }

  if (requiredDays != null && requiredDays > 0 && daysStatus != null) {
    rows.add(
      ProgressMetricRow(
        label: '$daysLogged of $requiredDays days',
        status: daysStatus,
        percent: percentOfDaysRequirement,
      ),
    );
  }

  return rows;
}

/// Resolves overall status from shown metric statuses using the worst-of rule:
/// Behind beats On pace beats Finished.
ProgressStatus resolveOverallStatus(List<ProgressStatus> statuses) {
  if (statuses.isEmpty) {
    return ProgressStatus.onPace;
  }
  if (statuses.contains(ProgressStatus.behind)) {
    return ProgressStatus.behind;
  }
  if (statuses.contains(ProgressStatus.onPace)) {
    return ProgressStatus.onPace;
  }
  if (statuses.every((s) => s == ProgressStatus.finished)) {
    return ProgressStatus.finished;
  }
  return statuses.first;
}
