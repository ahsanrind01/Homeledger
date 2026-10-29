import 'package:drift/drift.dart';
import '../db/app_database.dart';

/// Repository for managing daily time log entries.
/// All totals (SUM, COUNT DISTINCT) are computed directly via SQL queries
/// and are never stored anywhere in the database.
class LogRepository {
  final AppDatabase _db;

  const LogRepository(this._db);

  /// Inserts a new log entry.
  Future<int> add(LogEntriesCompanion entry) {
    return _db.into(_db.logEntries).insert(entry);
  }

  /// Updates an existing log entry.
  Future<bool> update(LogEntry entry) {
    return _db.update(_db.logEntries).replace(entry);
  }

  /// Deletes a log entry by its id.
  Future<int> delete(int id) {
    return (_db.delete(_db.logEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Fetches a single log entry by id.
  Future<LogEntry?> getById(int id) {
    return (_db.select(_db.logEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watches all log entries for a specific child on a specific day (YYYY-MM-DD).
  Stream<List<LogEntry>> watchForDay(int childId, String day) {
    return (_db.select(_db.logEntries)
          ..where((t) => t.childId.equals(childId) & t.day.equals(day))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Fetches all log entries for a child on a specific day (YYYY-MM-DD).
  Future<List<LogEntry>> getForDay(int childId, String day) {
    return (_db.select(_db.logEntries)
          ..where((t) => t.childId.equals(childId) & t.day.equals(day))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Computes the total logged minutes for a child between [from] and [to] (inclusive).
  /// Executed via SQL SUM query.
  Future<int> totalMinutes(int childId, String from, String to) async {
    final totalExp = _db.logEntries.minutes.sum();
    final query = _db.selectOnly(_db.logEntries)
      ..addColumns([totalExp])
      ..where(_db.logEntries.childId.equals(childId) &
          _db.logEntries.day.isBiggerOrEqualValue(from) &
          _db.logEntries.day.isSmallerOrEqualValue(to));

    final row = await query.getSingle();
    return row.read(totalExp) ?? 0;
  }

  /// Computes total logged minutes grouped by subject for a child between [from] and [to] (inclusive).
  /// Executed via SQL GROUP BY and SUM query.
  /// Returns a map of subjectId -> totalMinutes.
  Future<Map<int, int>> minutesBySubject(
    int childId,
    String from,
    String to,
  ) async {
    final totalExp = _db.logEntries.minutes.sum();
    final subjectIdCol = _db.logEntries.subjectId;

    final query = _db.selectOnly(_db.logEntries)
      ..addColumns([subjectIdCol, totalExp])
      ..where(_db.logEntries.childId.equals(childId) &
          _db.logEntries.day.isBiggerOrEqualValue(from) &
          _db.logEntries.day.isSmallerOrEqualValue(to))
      ..groupBy([subjectIdCol]);

    final rows = await query.get();
    final result = <int, int>{};
    for (final row in rows) {
      final subjectId = row.read(subjectIdCol);
      final minutes = row.read(totalExp);
      if (subjectId != null && minutes != null) {
        result[subjectId] = minutes;
      }
    }
    return result;
  }

  /// Computes the count of distinct days logged for a child between [from] and [to] (inclusive).
  /// Executed via SQL COUNT(DISTINCT day) query.
  /// A day with multiple entries is counted only once.
  Future<int> distinctDaysLogged(int childId, String from, String to) async {
    final countDistinctExp = _db.logEntries.day.count(distinct: true);
    final query = _db.selectOnly(_db.logEntries)
      ..addColumns([countDistinctExp])
      ..where(_db.logEntries.childId.equals(childId) &
          _db.logEntries.day.isBiggerOrEqualValue(from) &
          _db.logEntries.day.isSmallerOrEqualValue(to));

    final row = await query.getSingle();
    return row.read(countDistinctExp) ?? 0;
  }

  /// Counts all log entries for a child.
  Future<int> countForChild(int childId) async {
    final countExp = _db.logEntries.id.count();
    final query = _db.selectOnly(_db.logEntries)
      ..addColumns([countExp])
      ..where(_db.logEntries.childId.equals(childId));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Continuously watches the total logged minutes for a child between [from] and [to] (inclusive).
  Stream<int> watchTotalMinutes(int childId, String from, String to) {
    final totalExp = _db.logEntries.minutes.sum();
    final query = _db.selectOnly(_db.logEntries)
      ..addColumns([totalExp])
      ..where(_db.logEntries.childId.equals(childId) &
          _db.logEntries.day.isBiggerOrEqualValue(from) &
          _db.logEntries.day.isSmallerOrEqualValue(to));

    return query.watchSingle().map((row) => row.read(totalExp) ?? 0);
  }

  /// Continuously watches total logged minutes grouped by subject for a child between [from] and [to] (inclusive).
  Stream<Map<int, int>> watchMinutesBySubject(
    int childId,
    String from,
    String to,
  ) {
    final totalExp = _db.logEntries.minutes.sum();
    final subjectIdCol = _db.logEntries.subjectId;

    final query = _db.selectOnly(_db.logEntries)
      ..addColumns([subjectIdCol, totalExp])
      ..where(_db.logEntries.childId.equals(childId) &
          _db.logEntries.day.isBiggerOrEqualValue(from) &
          _db.logEntries.day.isSmallerOrEqualValue(to))
      ..groupBy([subjectIdCol]);

    return query.watch().map((rows) {
      final result = <int, int>{};
      for (final row in rows) {
        final subjectId = row.read(subjectIdCol);
        final minutes = row.read(totalExp);
        if (subjectId != null && minutes != null) {
          result[subjectId] = minutes;
        }
      }
      return result;
    });
  }

  /// Continuously watches the count of distinct days logged for a child between [from] and [to] (inclusive).
  Stream<int> watchDistinctDaysLogged(int childId, String from, String to) {
    final countDistinctExp = _db.logEntries.day.count(distinct: true);
    final query = _db.selectOnly(_db.logEntries)
      ..addColumns([countDistinctExp])
      ..where(_db.logEntries.childId.equals(childId) &
          _db.logEntries.day.isBiggerOrEqualValue(from) &
          _db.logEntries.day.isSmallerOrEqualValue(to));

    return query.watchSingle().map((row) => row.read(countDistinctExp) ?? 0);
  }

  /// Continuously watches all log entries for a child.
  Stream<List<LogEntry>> watchForChild(int childId) {
    return (_db.select(_db.logEntries)
          ..where((t) => t.childId.equals(childId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.day),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  /// Fetches all log entries for a child between [from] and [to] (inclusive).
  /// Sorted chronologically by day ASC, createdAt ASC.
  Future<List<LogEntry>> getForChildDateRange(
    int childId,
    String from,
    String to,
  ) {
    return (_db.select(_db.logEntries)
          ..where((t) =>
              t.childId.equals(childId) &
              t.day.isBiggerOrEqualValue(from) &
              t.day.isSmallerOrEqualValue(to))
          ..orderBy([
            (t) => OrderingTerm.asc(t.day),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }

  /// Returns the total count of log entries across all children.
  Future<int> countAll() async {
    final countExp = _db.logEntries.id.count();
    final query = _db.selectOnly(_db.logEntries)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }
}



