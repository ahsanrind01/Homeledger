import 'package:drift/drift.dart';
import '../db/app_database.dart';

/// Optional filtering criteria for querying work samples.
class SampleFilter {
  final int? subjectId;
  final String? from;
  final String? to;
  final String? day;

  const SampleFilter({
    this.subjectId,
    this.from,
    this.to,
    this.day,
  });
}

/// Repository for managing work sample records.
/// Note: This repository strictly manages the database rows. File creation
/// and deletion on disk are coordinated outside the database transaction.
class SampleRepository {
  final AppDatabase _db;

  const SampleRepository(this._db);

  /// Inserts a new work sample record.
  Future<int> add(WorkSamplesCompanion sample) {
    return _db.into(_db.workSamples).insert(sample);
  }

  /// Deletes a work sample record by its id.
  Future<int> delete(int id) {
    return (_db.delete(_db.workSamples)..where((t) => t.id.equals(id))).go();
  }

  /// Fetches a work sample record by its id.
  Future<WorkSample?> getById(int id) {
    return (_db.select(_db.workSamples)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns the total count of work samples saved for a child.
  Future<int> countForChild(int childId) async {
    final count = _db.workSamples.id.count();
    final query = _db.selectOnly(_db.workSamples)
      ..addColumns([count])
      ..where(_db.workSamples.childId.equals(childId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Returns the total count of work samples across all children.
  Future<int> countAll() async {
    final count = _db.workSamples.id.count();
    final query = _db.selectOnly(_db.workSamples)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Returns the total count of work samples associated with a subject.
  Future<int> countForSubject(int subjectId) async {
    final count = _db.workSamples.id.count();
    final query = _db.selectOnly(_db.workSamples)
      ..addColumns([count])
      ..where(_db.workSamples.subjectId.equals(subjectId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }


  /// Lists work samples for a given child, optionally filtered by subject, day, or date range.
  Future<List<WorkSample>> listForChild(
    int childId, [
    SampleFilter? filter,
  ]) {
    final query = _db.select(_db.workSamples)
      ..where((t) {
        Expression<bool> predicate = t.childId.equals(childId);
        if (filter != null) {
          if (filter.subjectId != null) {
            predicate = predicate & t.subjectId.equals(filter.subjectId!);
          }
          if (filter.day != null) {
            predicate = predicate & t.day.equals(filter.day!);
          }
          if (filter.from != null) {
            predicate = predicate & t.day.isBiggerOrEqualValue(filter.from!);
          }
          if (filter.to != null) {
            predicate = predicate & t.day.isSmallerOrEqualValue(filter.to!);
          }
        }
        return predicate;
      })
      ..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.createdAt)]);

    return query.get();
  }

  /// Continuously watches all work samples for a child.
  Stream<List<WorkSample>> watchForChild(int childId) {
    return (_db.select(_db.workSamples)
          ..where((t) => t.childId.equals(childId))
          ..orderBy([(t) => OrderingTerm.desc(t.day)]))
        .watch();
  }

  /// Fetches all work samples across all children (used for orphan cleanup).
  Future<List<WorkSample>> getAll() {
    return _db.select(_db.workSamples).get();
  }

  /// Continuously watches work samples for a child with optional filters.
  Stream<List<WorkSample>> watchForChildFiltered(
    int childId, [
    SampleFilter? filter,
  ]) {
    final query = _db.select(_db.workSamples)
      ..where((t) {
        Expression<bool> predicate = t.childId.equals(childId);
        if (filter != null) {
          if (filter.subjectId != null) {
            predicate = predicate & t.subjectId.equals(filter.subjectId!);
          }
          if (filter.day != null) {
            predicate = predicate & t.day.equals(filter.day!);
          }
          if (filter.from != null) {
            predicate = predicate & t.day.isBiggerOrEqualValue(filter.from!);
          }
          if (filter.to != null) {
            predicate = predicate & t.day.isSmallerOrEqualValue(filter.to!);
          }
        }
        return predicate;
      })
      ..orderBy([
        (t) => OrderingTerm.desc(t.day),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);

    return query.watch();
  }
}

