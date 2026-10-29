import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';

void main() {
  late AppDatabase db;
  late SubjectRepository subjectRepo;
  late SettingsRepository settingsRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    subjectRepo = SubjectRepository(db);
    settingsRepo = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('fresh database -> ensureDefaultSubjectsSeeded creates 6 subjects and sets the flag', () async {
    expect(await subjectRepo.getAll(), isEmpty);
    expect(await settingsRepo.getSetting(SubjectRepository.keyDefaultSubjectsSeeded), isNull);

    await subjectRepo.ensureDefaultSubjectsSeeded(settingsRepo);

    final subjects = await subjectRepo.getAll();
    expect(subjects.length, 6);
    expect(
      subjects.map((s) => s.name).toList(),
      ['Math', 'Reading', 'Writing', 'Science', 'History', 'Other'],
    );
    expect(
      await settingsRepo.getSetting(SubjectRepository.keyDefaultSubjectsSeeded),
      'true',
    );
  });

  test('calling ensureDefaultSubjectsSeeded again changes nothing', () async {
    await subjectRepo.ensureDefaultSubjectsSeeded(settingsRepo);
    expect((await subjectRepo.getAll()).length, 6);

    // Call second time
    await subjectRepo.ensureDefaultSubjectsSeeded(settingsRepo);
    expect((await subjectRepo.getAll()).length, 6);
    expect(
      await settingsRepo.getSetting(SubjectRepository.keyDefaultSubjectsSeeded),
      'true',
    );
  });

  test('delete all subjects, call again -> still 0 subjects', () async {
    await subjectRepo.ensureDefaultSubjectsSeeded(settingsRepo);
    final initial = await subjectRepo.getAll();
    for (final s in initial) {
      await subjectRepo.delete(s.id);
    }
    expect(await subjectRepo.getAll(), isEmpty);

    // Calling again must respect parent's deletion because the flag is set
    await subjectRepo.ensureDefaultSubjectsSeeded(settingsRepo);
    expect(await subjectRepo.getAll(), isEmpty);
  });

  test('database that already has subjects and no flag -> no new subjects and flag set', () async {
    // Manually add one custom subject before seeding has run
    await subjectRepo.add(
      SubjectsCompanion.insert(name: 'Art'),
    );
    expect((await subjectRepo.getAll()).length, 1);
    expect(await settingsRepo.getSetting(SubjectRepository.keyDefaultSubjectsSeeded), isNull);

    // Run ensureDefaultSubjectsSeeded
    await subjectRepo.ensureDefaultSubjectsSeeded(settingsRepo);

    final subjects = await subjectRepo.getAll();
    expect(subjects.length, 1);
    expect(subjects.first.name, 'Art');
    expect(
      await settingsRepo.getSetting(SubjectRepository.keyDefaultSubjectsSeeded),
      'true',
    );
  });
}
