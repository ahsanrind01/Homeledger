import 'package:drift/drift.dart';
import '../db/app_database.dart';

/// Repository for managing child homeschooling profiles.
class ChildRepository {
  final AppDatabase _db;

  const ChildRepository(this._db);

  /// Inserts a new child profile.
  Future<int> add(ChildrenCompanion child) {
    return _db.into(_db.children).insert(child);
  }

  /// Updates an existing child profile.
  Future<bool> update(Child child) {
    return _db.update(_db.children).replace(child);
  }

  /// Fetches a child profile by its unique id.
  Future<Child?> getById(int id) {
    return (_db.select(_db.children)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Continuously watches all child profiles, ordered by creation time.
  Stream<List<Child>> watchAll() {
    return (_db.select(_db.children)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Fetches all children as a one-time list.
  Future<List<Child>> getAll() {
    return (_db.select(_db.children)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Returns the total count of children in the database.
  Future<int> countAll() async {
    final countExp = _db.children.id.count();
    final query = _db.selectOnly(_db.children)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Cascades deletion of a child and all related data in ONE atomic transaction:
  /// 1. Finds and collects all work sample file paths for this child.
  /// 2. Deletes all log entries belonging to the child.
  /// 3. Deletes all work sample database rows belonging to the child.
  /// 4. Deletes the child row itself.
  ///
  /// Returns the collected list of file paths so the caller can delete the
  /// physical files from storage *after* the transaction commits.
  /// Note: Never deletes files inside this transaction or database layer.
  Future<List<String>> deleteChildCascade(int childId) {
    return _db.transaction(() async {
      // 1. Collect all sample file paths
      final samples = await (_db.select(_db.workSamples)
            ..where((t) => t.childId.equals(childId)))
          .get();
      final filePaths = samples.map((s) => s.filePath).toList();

      // 2. Delete child log entries
      await (_db.delete(_db.logEntries)
            ..where((t) => t.childId.equals(childId)))
          .go();

      // 3. Delete work sample rows
      await (_db.delete(_db.workSamples)
            ..where((t) => t.childId.equals(childId)))
          .go();

      // 4. Delete the child
      await (_db.delete(_db.children)..where((t) => t.id.equals(childId))).go();

      return filePaths;
    });
  }
}
