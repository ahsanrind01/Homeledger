/// Formats an integer amount of minutes into a human-readable string.
///
/// Examples:
/// - 135 minutes -> '2 h 15 min'
/// - 120 minutes -> '2 h'
/// - 45 minutes  -> '45 min'
/// - 0 minutes   -> '0 min'
String formatMinutes(int minutes) {
  if (minutes <= 0) {
    return '0 min';
  }
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;

  if (hours == 0) {
    return '$remainingMinutes min';
  }
  if (remainingMinutes == 0) {
    return '$hours h';
  }
  return '$hours h $remainingMinutes min';
}

/// Formats a DateTime to a standardized ISO date string (YYYY-MM-DD).
String formatIsoDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Formats progress requirement text, such as 'X h Y min of Z h' or 'X of Y days'.
String formatProgressSummary({
  required int minutesDone,
  required int? requiredMinutes,
  int? daysLogged,
  int? requiredDays,
}) {
  final h = minutesDone ~/ 60;
  final m = minutesDone % 60;
  if (requiredMinutes != null) {
    final reqH = requiredMinutes ~/ 60;
    return '$h h $m min of $reqH h';
  }
  if (requiredDays != null && daysLogged != null) {
    return '$daysLogged of $requiredDays days';
  }
  return '$h h $m min';
}

/// Formats a DateTime for user-friendly display (e.g. 'Oct 19, 2026').
String formatDisplayDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}


