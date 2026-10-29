import 'package:drift/drift.dart';
import '../db/app_database.dart';
import 'settings_repository.dart';

/// Repository for managing learning subjects (e.g., Math, Reading).
class SubjectRepository {
  final AppDatabase _db;

  const SubjectRepository(this._db);

  static const String keyDefaultSubjectsSeeded = 'default_subjects_seeded';

  /// Ensures default subjects are seeded once on first launch.
  /// Seeds only when BOTH:
  /// 1. settings key 'default_subjects_seeded' is absent, AND
  /// 2. the subjects table is currently empty.
  ///
  /// Always sets 'default_subjects_seeded' = 'true' when absent so that if a parent
  /// purposefully deletes all subjects, they are never re-seeded on next start.
  Future<void> ensureDefaultSubjectsSeeded(SettingsRepository settingsRepo) async {
    final flag = await settingsRepo.getSetting(keyDefaultSubjectsSeeded);
    if (flag != null) {
      return;
    }

    final countExp = _db.subjects.id.count();
    final query = _db.selectOnly(_db.subjects)..addColumns([countExp]);
    final row = await query.getSingle();
    final count = row.read(countExp) ?? 0;

    if (count == 0) {
      await seedDefaultSubjects();
    }

    await settingsRepo.setSetting(keyDefaultSubjectsSeeded, 'true');
  }

  /// Inserts a new subject.
  /// Subject names are unique ignoring case (enforced by database constraint).
  Future<int> add(SubjectsCompanion subject) {
    return _db.into(_db.subjects).insert(subject);
  }

  /// Updates an existing subject.
  Future<bool> update(Subject subject) {
    return _db.update(_db.subjects).replace(subject);
  }

  /// Deletes a subject by its id.
  Future<int> delete(int id) {
    return (_db.delete(_db.subjects)..where((t) => t.id.equals(id))).go();
  }

  /// Deletes a subject and cascades deletion:
  /// 1. Collects all work sample file paths associated with this subject.
  /// 2. Deletes all log entries belonging to this subject.
  /// 3. Deletes all work sample database rows belonging to this subject.
  /// 4. Deletes the subject row itself.
  ///
  /// Returns the list of sample file paths so the caller can delete the
  /// physical files from storage after the database transaction commits.
  Future<List<String>> deleteSubjectCascade(int subjectId) {
    return _db.transaction(() async {
      // 1. Collect sample file paths
      final samples = await (_db.select(_db.workSamples)
            ..where((t) => t.subjectId.equals(subjectId)))
          .get();
      final filePaths = samples.map((s) => s.filePath).toList();

      // 2. Delete log entries
      await (_db.delete(_db.logEntries)
            ..where((t) => t.subjectId.equals(subjectId)))
          .go();

      // 3. Delete work sample rows
      await (_db.delete(_db.workSamples)
            ..where((t) => t.subjectId.equals(subjectId)))
          .go();

      // 4. Delete the subject
      await (_db.delete(_db.subjects)..where((t) => t.id.equals(subjectId))).go();

      return filePaths;
    });
  }


  /// Fetches a subject by id.
  Future<Subject?> getById(int id) {
    return (_db.select(_db.subjects)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Fetches all subjects ordered by sortOrder then name.
  Future<List<Subject>> getAll() {
    return (_db.select(_db.subjects)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  /// Continuously watches all subjects ordered by sortOrder then name.
  Stream<List<Subject>> watchAll() {
    return (_db.select(_db.subjects)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  /// Seeds default subjects (Math, Reading, Writing, Science, History, Other)
  /// if no subject exists yet.
  Future<void> seedDefaultSubjects() async {
    final countExp = _db.subjects.id.count();
    final query = _db.selectOnly(_db.subjects)..addColumns([countExp]);
    final row = await query.getSingle();
    final count = row.read(countExp) ?? 0;

    if (count == 0) {
      const defaultNames = [
        'Math',
        'Reading',
        'Writing',
        'Science',
        'History',
        'Other',
      ];
      for (var i = 0; i < defaultNames.length; i++) {
        await _db.into(_db.subjects).insert(
              SubjectsCompanion.insert(
                name: defaultNames[i],
                isCore: const Value(false),
                sortOrder: Value(i),
              ),
            );
      }
    }
  }

  /// Counts the number of log entries referencing this subject.
  Future<int> countLogEntriesForSubject(int subjectId) async {
    final countExp = _db.logEntries.id.count();
    final query = _db.selectOnly(_db.logEntries)
      ..addColumns([countExp])
      ..where(_db.logEntries.subjectId.equals(subjectId));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Reorders subjects by assigning incremental sortOrder values.
  Future<void> reorder(List<Subject> subjects) {
    return _db.transaction(() async {
      for (var i = 0; i < subjects.length; i++) {
        final subject = subjects[i];
        if (subject.sortOrder != i) {
          await (_db.update(_db.subjects)..where((t) => t.id.equals(subject.id)))
              .write(SubjectsCompanion(sortOrder: Value(i)));
        }
      }
    });
  }
}

