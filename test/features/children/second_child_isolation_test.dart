import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';

void main() {
  late AppDatabase db;
  late ChildRepository childRepo;
  late SubjectRepository subjectRepo;
  late LogRepository logRepo;
  late SampleRepository sampleRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    childRepo = ChildRepository(db);
    subjectRepo = SubjectRepository(db);
    logRepo = LogRepository(db);
    sampleRepo = SampleRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Second child data isolation: logging for child A leaves child B totals completely unchanged', () async {
    // 1. Create Child A and Child B with distinct rules and school years
    final childAId = await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Alice',
        ruleId: 'placeholder_example',
        schoolYearStart: '2026-08-01',
        schoolYearEnd: '2027-05-31',
        createdAt: 1700000000000,
      ),
    );

    final childBId = await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Bob',
        ruleId: 'custom:1',
        schoolYearStart: '2026-09-01',
        schoolYearEnd: '2027-06-30',
        createdAt: 1700000001000,
      ),
    );

    // 2. Create Subjects
    final mathId = await subjectRepo.add(
      SubjectsCompanion.insert(name: 'Math'),
    );
    final readingId = await subjectRepo.add(
      SubjectsCompanion.insert(name: 'Reading'),
    );

    // Initial state: both have 0 minutes logged
    expect(await logRepo.countForChild(childAId), 0);
    expect(await logRepo.countForChild(childBId), 0);
    expect(
      await logRepo.totalMinutes(childAId, '2026-10-20', '2026-10-20'),
      0,
    );
    expect(
      await logRepo.totalMinutes(childBId, '2026-10-20', '2026-10-20'),
      0,
    );

    // 3. Log 90 minutes for Child A on Math
    await logRepo.add(
      LogEntriesCompanion.insert(
        childId: childAId,
        subjectId: mathId,
        day: '2026-10-20',
        minutes: 90,
        createdAt: 1700000002000,
      ),
    );

    // Log 45 minutes for Child A on Reading
    await logRepo.add(
      LogEntriesCompanion.insert(
        childId: childAId,
        subjectId: readingId,
        day: '2026-10-20',
        minutes: 45,
        createdAt: 1700000003000,
      ),
    );

    // Verify Child A has 135 minutes across 2 entries
    expect(await logRepo.countForChild(childAId), 2);
    expect(
      await logRepo.totalMinutes(childAId, '2026-10-20', '2026-10-20'),
      135,
    );

    // 4. VERIFY CHILD B IS 100% UNCHANGED: 0 entries, 0 minutes
    expect(await logRepo.countForChild(childBId), 0);
    expect(
      await logRepo.totalMinutes(childBId, '2026-10-20', '2026-10-20'),
      0,
    );

    final childBSubjectMinutes = await logRepo.minutesBySubject(
      childBId,
      '2026-09-01',
      '2027-06-30',
    );
    expect(childBSubjectMinutes, isEmpty);

    final childBDistinctDays = await logRepo.distinctDaysLogged(
      childBId,
      '2026-09-01',
      '2027-06-30',
    );
    expect(childBDistinctDays, 0);

    // 5. Add work sample for Child A
    await sampleRepo.add(
      WorkSamplesCompanion.insert(
        childId: 1,
        day: '2026-10-20',
        filePath: 'samples/1/sample_artwork.jpg',
        createdAt: 1700000004000,
      ),
    );

    expect(await sampleRepo.countForChild(childAId), 1);
    expect(await sampleRepo.countForChild(childBId), 0);
  });
}
