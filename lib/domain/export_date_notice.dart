/// Pure helper for detecting date range overlap with the school year and
/// generating explanatory notices for parents during export.
///
/// Disclaimers: Records tool, not legal advice.
enum DateRangeSchoolYearOverlap {
  inside,
  partlyOutside,
  noOverlap,
}

/// Evaluates whether a date range is inside, partly outside, or has no overlap with the school year.
DateRangeSchoolYearOverlap checkDateRangeSchoolYearOverlap({
  required DateTime schoolYearStart,
  required DateTime schoolYearEnd,
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  final syStart = DateTime.utc(schoolYearStart.year, schoolYearStart.month, schoolYearStart.day);
  final syEnd = DateTime.utc(schoolYearEnd.year, schoolYearEnd.month, schoolYearEnd.day);
  final rStart = DateTime.utc(rangeStart.year, rangeStart.month, rangeStart.day);
  final rEnd = DateTime.utc(rangeEnd.year, rangeEnd.month, rangeEnd.day);

  if (rEnd.isBefore(syStart) || rStart.isAfter(syEnd)) {
    return DateRangeSchoolYearOverlap.noOverlap;
  }
  if (rStart.isBefore(syStart) || rEnd.isAfter(syEnd)) {
    return DateRangeSchoolYearOverlap.partlyOutside;
  }
  return DateRangeSchoolYearOverlap.inside;
}

/// Returns the plain text notice string if the date range is partly or fully outside the school year.
String? computeDateRangeSchoolYearNotice({
  required String schoolYearStart,
  required String schoolYearEnd,
  required String rangeStart,
  required String rangeEnd,
}) {
  DateTime syStart;
  DateTime syEnd;
  DateTime rStart;
  DateTime rEnd;
  try {
    syStart = DateTime.parse(schoolYearStart);
    syEnd = DateTime.parse(schoolYearEnd);
    rStart = DateTime.parse(rangeStart);
    rEnd = DateTime.parse(rangeEnd);
  } catch (_) {
    return null;
  }

  final overlap = checkDateRangeSchoolYearOverlap(
    schoolYearStart: syStart,
    schoolYearEnd: syEnd,
    rangeStart: rStart,
    rangeEnd: rEnd,
  );

  switch (overlap) {
    case DateRangeSchoolYearOverlap.noOverlap:
      return 'This range is outside the school year. The time log is empty for this range.';
    case DateRangeSchoolYearOverlap.partlyOutside:
      return 'Part of this range is outside the school year ($schoolYearStart to $schoolYearEnd). Progress is shown for the school year.';
    case DateRangeSchoolYearOverlap.inside:
      return null;
  }
}
