import '../core/constants.dart';
import '../core/formatters.dart';

/// The action outcome of validating a learning log entry.
enum LogValidationAction {
  /// Entry is fully within normal limits and can be saved immediately.
  allowed,

  /// Entry causes daily total to exceed 10 hours. Allowed if parent confirms.
  warn,

  /// Entry violates an absolute constraint (future date, <= 0 minutes, > 24 hours, note > 200 chars).
  blocked,
}

/// The result returned by [LogValidator.validate].
class LogValidationResult {
  final LogValidationAction action;
  final String? message;

  const LogValidationResult.allowed()
      : action = LogValidationAction.allowed,
        message = null;

  const LogValidationResult.warn(this.message)
      : action = LogValidationAction.warn;

  const LogValidationResult.blocked(this.message)
      : action = LogValidationAction.blocked;

  bool get isAllowed => action == LogValidationAction.allowed;
  bool get isWarn => action == LogValidationAction.warn;
  bool get isBlocked => action == LogValidationAction.blocked;
}

/// Pure Dart validator for homeschooling log entries.
///
/// Disclaimers: Records tool, not legal advice.
class LogValidator {
  const LogValidator._();

  /// Validates a proposed daily log entry against Homeledger business rules.
  ///
  /// - [minutesToAdd]: The minutes to log (must be > 0).
  /// - [currentDayMinutes]: Existing logged minutes for this child on this day.
  ///   If editing an existing entry, pass the day's total excluding that entry.
  /// - [date]: The calendar day being logged.
  /// - [today]: Current system date from the clock provider.
  /// - [note]: Optional log note (max 200 characters).
  static LogValidationResult validate({
    required int minutesToAdd,
    required int currentDayMinutes,
    required DateTime date,
    required DateTime today,
    String? note,
  }) {
    // 1. Date cannot be in the future (compared date-only)
    final dateUtc = DateTime.utc(date.year, date.month, date.day);
    final todayUtc = DateTime.utc(today.year, today.month, today.day);

    if (dateUtc.isAfter(todayUtc)) {
      return const LogValidationResult.blocked('Future dates are not allowed');
    }

    // 2. Minutes must be greater than 0
    if (minutesToAdd <= 0) {
      return const LogValidationResult.blocked('Minutes must be greater than 0');
    }

    // 3. Note length limit
    if (note != null && note.length > 200) {
      return const LogValidationResult.blocked('Note cannot exceed 200 characters');
    }

    // 4. Daily limits: 24h hard block, 10h warning
    final newTotalMinutes = currentDayMinutes + minutesToAdd;
    final maxMinutes = (AppConstants.maxDailyHours * 60).round(); // 1440
    final warnMinutes = (AppConstants.warnDailyHours * 60).round(); // 600

    if (newTotalMinutes > maxMinutes) {
      return const LogValidationResult.blocked(
        'Daily total cannot exceed 24 hours',
      );
    }

    if (newTotalMinutes > warnMinutes) {
      return LogValidationResult.warn(
        'Daily total will exceed 10 hours (${formatMinutes(newTotalMinutes)}).',
      );
    }

    return const LogValidationResult.allowed();
  }
}
