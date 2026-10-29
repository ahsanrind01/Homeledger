import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/custom_rule_repository.dart';
import 'package:homeledger/data/repositories/entitlement_repository.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';

void main() {
  late AppDatabase db;
  late ChildRepository childRepo;
  late SubjectRepository subjectRepo;
  late LogRepository logRepo;
  late SampleRepository sampleRepo;
  late CustomRuleRepository customRuleRepo;
  late EntitlementRepository entitlementRepo;
  late SettingsRepository settingsRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    childRepo = ChildRepository(db);
    subjectRepo = SubjectRepository(db);
    logRepo = LogRepository(db);
    sampleRepo = SampleRepository(db);
    customRuleRepo = CustomRuleRepository(db);
    entitlementRepo = EntitlementRepository(db);
    settingsRepo = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ChildRepository', () {
    test('add, getById, update, and watchAll work', () async {
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Daniel',
          ruleId: 'asset:rule_default',
          schoolYearStart: '2026-08-15',
          schoolYearEnd: '2027-05-30',
          createdAt: 1000,
        ),
      );

      final child = await childRepo.getById(childId);
      expect(child, isNotNull);
      expect(child!.name, 'Daniel');

      final updated = await childRepo.update(
        child.copyWith(name: 'Daniel Updated'),
      );
      expect(updated, isTrue);

      final fetched = await childRepo.getById(childId);
      expect(fetched!.name, 'Daniel Updated');

      final all = await childRepo.getAll();
      expect(all.length, 1);
    });

    test(
        'deleteChildCascade removes child, entries, samples and returns file paths with nothing left behind',
        () async {
      // 1. Insert child
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Emma',
          ruleId: 'custom:1',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );

      // 2. Insert subjects
      final mathId = await subjectRepo.add(
        SubjectsCompanion.insert(name: 'Math'),
      );
      final readingId = await subjectRepo.add(
        SubjectsCompanion.insert(name: 'Reading'),
      );

      // 3. Insert log entries for this child
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: mathId,
          day: '2026-10-10',
          minutes: 40,
          createdAt: 1001,
        ),
      );
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: readingId,
          day: '2026-10-11',
          minutes: 50,
          createdAt: 1002,
        ),
      );

      // 4. Insert work samples for this child
      await sampleRepo.add(
        WorkSamplesCompanion.insert(
          childId: childId,
          subjectId: Value(mathId),
          day: '2026-10-10',
          title: const Value('Math Test 1'),
          filePath: '/files/samples/math1.jpg',
          createdAt: 1003,
        ),
      );
      await sampleRepo.add(
        WorkSamplesCompanion.insert(
          childId: childId,
          subjectId: Value(readingId),
          day: '2026-10-11',
          title: const Value('Essay 1'),
          filePath: '/files/samples/essay1.pdf',
          createdAt: 1004,
        ),
      );

      // Verify records exist before cascade delete
      expect(await childRepo.getById(childId), isNotNull);
      expect(await logRepo.totalMinutes(childId, '2026-10-01', '2026-10-31'), 90);
      expect((await sampleRepo.listForChild(childId)).length, 2);

      // 5. Execute deleteChildCascade
      final returnedPaths = await childRepo.deleteChildCascade(childId);

      // 6. Verify returned sample paths
      expect(returnedPaths, containsAll([
        '/files/samples/math1.jpg',
        '/files/samples/essay1.pdf',
      ]));
      expect(returnedPaths.length, 2);

      // 7. Verify nothing is left behind
      expect(await childRepo.getById(childId), isNull);
      expect(await logRepo.totalMinutes(childId, '2026-10-01', '2026-10-31'), 0);
      expect((await sampleRepo.listForChild(childId)).isEmpty, isTrue);

      // Verify that subjects remain intact (only child-owned data was deleted)
      expect(await subjectRepo.getById(mathId), isNotNull);
      expect(await subjectRepo.getById(readingId), isNotNull);
    });
  });

  group('SubjectRepository', () {
    test('add, getById, update, delete, getAll', () async {
      final id = await subjectRepo.add(
        SubjectsCompanion.insert(
          name: 'Geography',
          isCore: const Value(false),
          sortOrder: const Value(3),
        ),
      );

      final subject = await subjectRepo.getById(id);
      expect(subject, isNotNull);
      expect(subject!.name, 'Geography');

      await subjectRepo.update(subject.copyWith(isCore: true));
      final updated = await subjectRepo.getById(id);
      expect(updated!.isCore, isTrue);

      final all = await subjectRepo.getAll();
      expect(all.any((s) => s.id == id), isTrue);

      await subjectRepo.delete(id);
      expect(await subjectRepo.getById(id), isNull);
    });

    test('rejects duplicate names ignoring case', () async {
      await subjectRepo.add(SubjectsCompanion.insert(name: 'Science'));

      expect(
        () => subjectRepo.add(SubjectsCompanion.insert(name: 'science')),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('LogRepository', () {
    late int childId;
    late int mathId;
    late int scienceId;

    setUp(() async {
      childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Liam',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );
      mathId = await subjectRepo.add(SubjectsCompanion.insert(name: 'Math'));
      scienceId = await subjectRepo.add(SubjectsCompanion.insert(name: 'Science'));
    });

    test('totalMinutes by date range includes both boundary days', () async {
      // Entry before range
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: mathId,
        day: '2026-10-09',
        minutes: 20,
        createdAt: 1001,
      ));

      // Boundary start entry
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: mathId,
        day: '2026-10-10',
        minutes: 30,
        createdAt: 1002,
      ));

      // Inside entry
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: scienceId,
        day: '2026-10-11',
        minutes: 45,
        createdAt: 1003,
      ));

      // Boundary end entry
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: mathId,
        day: '2026-10-12',
        minutes: 60,
        createdAt: 1004,
      ));

      // Entry after range
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: scienceId,
        day: '2026-10-13',
        minutes: 15,
        createdAt: 1005,
      ));

      // Total from 2026-10-10 to 2026-10-12 must include 10th (30m), 11th (45m), and 12th (60m)
      final total = await logRepo.totalMinutes(
        childId,
        '2026-10-10',
        '2026-10-12',
      );
      expect(total, 30 + 45 + 60); // 135 minutes

      // Querying with no entries returns 0
      final emptyTotal = await logRepo.totalMinutes(
        childId,
        '2026-01-01',
        '2026-01-02',
      );
      expect(emptyTotal, 0);
    });

    test('minutesBySubject returns grouped minutes by subject', () async {
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: mathId,
        day: '2026-10-10',
        minutes: 30,
        createdAt: 1001,
      ));
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: mathId,
        day: '2026-10-11',
        minutes: 45,
        createdAt: 1002,
      ));
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: scienceId,
        day: '2026-10-11',
        minutes: 60,
        createdAt: 1003,
      ));

      final result = await logRepo.minutesBySubject(
        childId,
        '2026-10-10',
        '2026-10-12',
      );

      expect(result[mathId], 75);
      expect(result[scienceId], 60);
    });

    test('distinctDaysLogged counts a day once even with several entries',
        () async {
      // Day 1: 3 separate entries
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: mathId,
        day: '2026-10-10',
        minutes: 20,
        createdAt: 1001,
      ));
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: scienceId,
        day: '2026-10-10',
        minutes: 30,
        createdAt: 1002,
      ));
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: mathId,
        day: '2026-10-10',
        minutes: 25,
        createdAt: 1003,
      ));

      // Day 2: 2 separate entries
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: mathId,
        day: '2026-10-11',
        minutes: 40,
        createdAt: 1004,
      ));
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: scienceId,
        day: '2026-10-11',
        minutes: 45,
        createdAt: 1005,
      ));

      // Day 3 (outside date range): 1 entry
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: mathId,
        day: '2026-10-15',
        minutes: 30,
        createdAt: 1006,
      ));

      final distinctDays = await logRepo.distinctDaysLogged(
        childId,
        '2026-10-10',
        '2026-10-12',
      );

      // Must be exactly 2 distinct days (10th and 11th), despite 5 total entries
      expect(distinctDays, 2);
    });

    test('watchForDay returns entries for that day only', () async {
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: mathId,
        day: '2026-10-10',
        minutes: 30,
        createdAt: 1001,
      ));
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: scienceId,
        day: '2026-10-11',
        minutes: 40,
        createdAt: 1002,
      ));

      final entriesForDay = await logRepo.getForDay(childId, '2026-10-10');
      expect(entriesForDay.length, 1);
      expect(entriesForDay.first.minutes, 30);
    });
  });

  group('SampleRepository', () {
    test('add, listForChild with filters, and delete', () async {
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Sophia',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );
      final artId = await subjectRepo.add(SubjectsCompanion.insert(name: 'Art'));
      final musicId =
          await subjectRepo.add(SubjectsCompanion.insert(name: 'Music'));

      final id1 = await sampleRepo.add(WorkSamplesCompanion.insert(
        childId: childId,
        subjectId: Value(artId),
        day: '2026-10-10',
        title: const Value('Sketch 1'),
        filePath: '/files/sketch1.png',
        createdAt: 1001,
      ));

      final id2 = await sampleRepo.add(WorkSamplesCompanion.insert(
        childId: childId,
        subjectId: Value(musicId),
        day: '2026-10-15',
        title: const Value('Piano Recording'),
        filePath: '/files/piano.m4a',
        createdAt: 1002,
      ));

      // Filter by subjectId
      final artSamples = await sampleRepo.listForChild(
        childId,
        SampleFilter(subjectId: artId),
      );
      expect(artSamples.length, 1);
      expect(artSamples.first.id, id1);

      // Filter by date range
      final rangeSamples = await sampleRepo.listForChild(
        childId,
        const SampleFilter(from: '2026-10-12', to: '2026-10-20'),
      );
      expect(rangeSamples.length, 1);
      expect(rangeSamples.first.id, id2);

      // Delete
      await sampleRepo.delete(id1);
      final remaining = await sampleRepo.listForChild(childId);
      expect(remaining.length, 1);
      expect(remaining.first.id, id2);
    });
  });

  group('CustomRuleRepository', () {
    test('add, getById, getAll, and validation', () async {
      // 1. Success with requiredHours only
      final id1 = await customRuleRepo.add(
        CustomRulesCompanion.insert(
          label: '1000 Hours Goal',
          requiredHours: const Value(1000),
          requiredDays: const Value(null),
        ),
      );
      expect(id1, isPositive);

      // 2. Success with requiredDays only
      final id2 = await customRuleRepo.add(
        CustomRulesCompanion.insert(
          label: '180 Days Goal',
          requiredHours: const Value(null),
          requiredDays: const Value(180),
        ),
      );
      expect(id2, isPositive);

      // 3. Success with both
      final id3 = await customRuleRepo.add(
        CustomRulesCompanion.insert(
          label: 'Both Goal',
          requiredHours: const Value(900),
          requiredDays: const Value(175),
        ),
      );
      expect(id3, isPositive);

      // 4. Fail validation when both are null
      expect(
        () => customRuleRepo.add(
          CustomRulesCompanion.insert(
            label: 'Invalid Goal',
            requiredHours: const Value(null),
            requiredDays: const Value(null),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      final all = await customRuleRepo.getAll();
      expect(all.length, 3);
    });
  });

  group('EntitlementRepository', () {
    test('get initially null, set updates plan, resetToFree', () async {
      final initial = await entitlementRepo.get();
      expect(initial, isNull);

      await entitlementRepo.set(
        paidUntil: '2027-10-19T00:00:00Z',
        lastVerifiedAt: '2026-10-19T00:00:00Z',
        plan: 'yearly',
      );

      final current = await entitlementRepo.get();
      expect(current, isNotNull);
      expect(current!.plan, 'yearly');
      expect(current.paidUntil, '2027-10-19T00:00:00Z');

      await entitlementRepo.resetToFree();
      final afterReset = await entitlementRepo.get();
      expect(afterReset!.plan, 'free');
      expect(afterReset.paidUntil, isNull);
    });
  });

  group('SettingsRepository', () {
    test('isDisclaimerAccepted defaults to false and persists true', () async {
      expect(await settingsRepo.isDisclaimerAccepted(), isFalse);
      await settingsRepo.setDisclaimerAccepted(true);
      expect(await settingsRepo.isDisclaimerAccepted(), isTrue);
    });

    test('getSetting and setSetting store generic values', () async {
      expect(await settingsRepo.getSetting('custom_key'), isNull);
      await settingsRepo.setSetting('custom_key', 'hello_world');
      expect(await settingsRepo.getSetting('custom_key'), 'hello_world');
    });
  });

  group('SubjectRepository - Seeding, Counting, Reordering', () {
    test('seedDefaultSubjects seeds 6 subjects only when empty', () async {
      final initial = await subjectRepo.getAll();
      expect(initial, isEmpty);

      await subjectRepo.seedDefaultSubjects();
      final seeded = await subjectRepo.getAll();
      expect(seeded.length, 6);
      expect(
        seeded.map((s) => s.name).toList(),
        ['Math', 'Reading', 'Writing', 'Science', 'History', 'Other'],
      );

      // Running it again should NOT duplicate
      await subjectRepo.seedDefaultSubjects();
      final afterSecondRun = await subjectRepo.getAll();
      expect(afterSecondRun.length, 6);
    });

    test('countLogEntriesForSubject returns correct count', () async {
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Lucas',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );
      final subId = await subjectRepo.add(SubjectsCompanion.insert(name: 'Latin'));
      expect(await subjectRepo.countLogEntriesForSubject(subId), 0);

      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: subId,
        day: '2026-10-10',
        minutes: 40,
        createdAt: 1001,
      ));
      expect(await subjectRepo.countLogEntriesForSubject(subId), 1);
    });

    test('reorder updates sortOrder sequentially', () async {
      await subjectRepo.seedDefaultSubjects();
      final current = await subjectRepo.getAll();
      // Reverse list
      final reversed = current.reversed.toList();
      await subjectRepo.reorder(reversed);

      final reordered = await subjectRepo.getAll();
      expect(reordered.first.name, 'Other');
      expect(reordered.last.name, 'Math');
    });
  });

  group('LogRepository and SampleRepository countForChild', () {
    test('counts entries and samples for child', () async {
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Maya',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );
      final subId = await subjectRepo.add(SubjectsCompanion.insert(name: 'Drama'));

      expect(await logRepo.countForChild(childId), 0);
      expect(await sampleRepo.countForChild(childId), 0);

      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId,
        subjectId: subId,
        day: '2026-10-10',
        minutes: 45,
        createdAt: 1001,
      ));
      await sampleRepo.add(WorkSamplesCompanion.insert(
        childId: childId,
        day: '2026-10-10',
        filePath: '/path/test.png',
        createdAt: 1002,
      ));

      expect(await logRepo.countForChild(childId), 1);
      expect(await sampleRepo.countForChild(childId), 1);
    });
  });
}
