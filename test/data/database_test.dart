import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase - Tables Add/Read', () {
    test('children table supports insert and read', () async {
      final id = await db.into(db.children).insert(
            ChildrenCompanion.insert(
              name: 'Alice',
              ruleId: 'placeholder_example',
              schoolYearStart: '2026-09-01',
              schoolYearEnd: '2027-06-30',
              createdAt: 1700000000000,
            ),
          );

      final child = await (db.select(db.children)..where((t) => t.id.equals(id)))
          .getSingle();

      expect(child.id, id);
      expect(child.name, 'Alice');
      expect(child.ruleId, 'placeholder_example');
      expect(child.schoolYearStart, '2026-09-01');
      expect(child.schoolYearEnd, '2027-06-30');
      expect(child.createdAt, 1700000000000);
    });

    test('subjects table supports insert and read', () async {
      final id = await db.into(db.subjects).insert(
            SubjectsCompanion.insert(
              name: 'Mathematics',
              isCore: const Value(true),
              sortOrder: const Value(1),
            ),
          );

      final subject = await (db.select(db.subjects)..where((t) => t.id.equals(id)))
          .getSingle();

      expect(subject.id, id);
      expect(subject.name, 'Mathematics');
      expect(subject.isCore, true);
      expect(subject.sortOrder, 1);
    });

    test('log_entries table supports insert and read', () async {
      final childId = await db.into(db.children).insert(
            ChildrenCompanion.insert(
              name: 'Bob',
              ruleId: 'custom:1',
              schoolYearStart: '2026-09-01',
              schoolYearEnd: '2027-06-30',
              createdAt: 1700000000000,
            ),
          );

      final subjectId = await db.into(db.subjects).insert(
            SubjectsCompanion.insert(name: 'Science'),
          );

      final entryId = await db.into(db.logEntries).insert(
            LogEntriesCompanion.insert(
              childId: childId,
              subjectId: subjectId,
              day: '2026-10-15',
              minutes: 45,
              note: const Value('Solar system chapter'),
              createdAt: 1700000001000,
            ),
          );

      final entry = await (db.select(db.logEntries)..where((t) => t.id.equals(entryId)))
          .getSingle();

      expect(entry.id, entryId);
      expect(entry.childId, childId);
      expect(entry.subjectId, subjectId);
      expect(entry.day, '2026-10-15');
      expect(entry.minutes, 45);
      expect(entry.note, 'Solar system chapter');
      expect(entry.createdAt, 1700000001000);
    });

    test('work_samples table supports insert and read', () async {
      final childId = await db.into(db.children).insert(
            ChildrenCompanion.insert(
              name: 'Charlie',
              ruleId: 'placeholder_example',
              schoolYearStart: '2026-09-01',
              schoolYearEnd: '2027-06-30',
              createdAt: 1700000000000,
            ),
          );

      final subjectId = await db.into(db.subjects).insert(
            SubjectsCompanion.insert(name: 'Art'),
          );

      final sampleId = await db.into(db.workSamples).insert(
            WorkSamplesCompanion.insert(
              childId: childId,
              subjectId: Value(subjectId),
              day: '2026-10-16',
              title: const Value('Watercolor Painting'),
              filePath: '/data/user/0/com.example.homeledger/files/samples/sample_1.jpg',
              createdAt: 1700000002000,
            ),
          );

      final sample = await (db.select(db.workSamples)
            ..where((t) => t.id.equals(sampleId)))
          .getSingle();

      expect(sample.id, sampleId);
      expect(sample.childId, childId);
      expect(sample.subjectId, subjectId);
      expect(sample.day, '2026-10-16');
      expect(sample.title, 'Watercolor Painting');
      expect(sample.filePath,
          '/data/user/0/com.example.homeledger/files/samples/sample_1.jpg');
      expect(sample.createdAt, 1700000002000);
    });

    test('custom_rules table supports insert and read', () async {
      final ruleId = await db.into(db.customRules).insert(
            CustomRulesCompanion.insert(
              label: 'Sample Custom Goal',
              requiredHours: const Value(1000),
              requiredDays: const Value(null),
            ),
          );

      final rule = await (db.select(db.customRules)
            ..where((t) => t.id.equals(ruleId)))
          .getSingle();

      expect(rule.id, ruleId);
      expect(rule.label, 'Sample Custom Goal');
      expect(rule.requiredHours, 1000);
      expect(rule.requiredDays, isNull);
    });

    test('entitlement table supports insert and read', () async {
      final id = await db.into(db.entitlements).insert(
            EntitlementsCompanion.insert(
              paidUntil: const Value('2027-10-19T00:00:00Z'),
              lastVerifiedAt: const Value('2026-10-19T10:00:00Z'),
              plan: const Value('yearly'),
            ),
          );

      final row = await (db.select(db.entitlements)..where((t) => t.id.equals(id)))
          .getSingle();

      expect(row.paidUntil, '2027-10-19T00:00:00Z');
      expect(row.lastVerifiedAt, '2026-10-19T10:00:00Z');
      expect(row.plan, 'yearly');
    });
  });

  group('AppDatabase - Constraints and Rules', () {
    test('unique subject name is enforced ignoring case', () async {
      await db.into(db.subjects).insert(
            SubjectsCompanion.insert(name: 'History'),
          );

      // Inserting 'history' with different casing must fail with unique constraint violation
      expect(
        () => db.into(db.subjects).insert(
              SubjectsCompanion.insert(name: 'history'),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('foreign keys are enforced for log_entries', () async {
      final subjectId = await db.into(db.subjects).insert(
            SubjectsCompanion.insert(name: 'Spelling'),
          );

      // Inserting a log entry with non-existent childId must fail
      expect(
        () => db.into(db.logEntries).insert(
              LogEntriesCompanion.insert(
                childId: 99999, // Non-existent child
                subjectId: subjectId,
                day: '2026-10-15',
                minutes: 30,
                createdAt: 1700000000000,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('custom rule needs at least one value (check constraint)', () async {
      // Both requiredHours and requiredDays null must be rejected by CHECK constraint
      expect(
        () => db.into(db.customRules).insert(
              CustomRulesCompanion.insert(
                label: 'Empty Rule',
                requiredHours: const Value(null),
                requiredDays: const Value(null),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('VACUUM INTO creates a consistent standalone database file', () async {
      await db.into(db.subjects).insert(
            SubjectsCompanion.insert(name: 'History'),
          );
      final tempDir = Directory.systemTemp.createTempSync('db_vacuum_test_');
      final targetFile = File('${tempDir.path}/vacuum_test.sqlite');
      try {
        await db.customStatement("VACUUM INTO '${targetFile.path.replaceAll("'", "''")}';");
        expect(targetFile.existsSync(), isTrue);
        expect(targetFile.lengthSync(), greaterThan(0));

        final copyDb = AppDatabase(NativeDatabase(targetFile));
        final subjects = await copyDb.select(copyDb.subjects).get();
        expect(subjects.any((s) => s.name == 'History'), isTrue);
        await copyDb.close();
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
