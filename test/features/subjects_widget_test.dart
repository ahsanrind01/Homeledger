import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';
import 'package:homeledger/features/subjects/subjects_screen.dart';
import 'package:homeledger/services/sample_storage_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late SubjectRepository subjectRepo;
  late LogRepository logRepo;
  late SampleRepository sampleRepo;
  late SampleStorageService sampleStorageService;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    subjectRepo = SubjectRepository(db);
    logRepo = LogRepository(db);
    sampleRepo = SampleRepository(db);

    tempDir = Directory.systemTemp.createTempSync('homeledger_subjects_test_');
    sampleStorageService = SampleStorageService(
      sampleRepository: sampleRepo,
      getDocumentsDirectory: () async => tempDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget createSubjectUnderTest() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sampleStorageServiceProvider.overrideWithValue(sampleStorageService),
      ],
      child: const MaterialApp(
        home: SubjectsScreen(),
      ),
    );
  }

  testWidgets('Subjects screen shows 6 default subjects when seeded on first launch',
      (WidgetTester tester) async {
    await subjectRepo.ensureDefaultSubjectsSeeded(SettingsRepository(db));
    await tester.pumpWidget(createSubjectUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Math'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Writing'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('Subject with entries and samples: dialog shows both counts; after confirming, rows and files are gone',
      (WidgetTester tester) async {
    // 1. Setup child, subject, 2 log entries, and 1 work sample with physical file
    final childId = await db.into(db.children).insert(
          ChildrenCompanion.insert(
            name: 'Oliver',
            ruleId: 'placeholder_example',
            schoolYearStart: '2026-09-01',
            schoolYearEnd: '2027-06-30',
            createdAt: 1000,
          ),
        );

    final subjectId = await subjectRepo.add(
      SubjectsCompanion.insert(name: 'Robotics', isCore: const Value(true)),
    );

    await logRepo.add(LogEntriesCompanion.insert(
      childId: childId,
      subjectId: subjectId,
      day: '2026-10-10',
      minutes: 60,
      createdAt: 1001,
    ));
    await logRepo.add(LogEntriesCompanion.insert(
      childId: childId,
      subjectId: subjectId,
      day: '2026-10-11',
      minutes: 45,
      createdAt: 1002,
    ));

    final sampleRelPath = 'samples/$childId/sample1.jpg';
    final sampleFile = File(p.join(tempDir.path, sampleRelPath));
    sampleFile.parent.createSync(recursive: true);
    sampleFile.writeAsBytesSync([1, 2, 3, 4]);

    final sampleId = await sampleRepo.add(
      WorkSamplesCompanion.insert(
        childId: childId,
        subjectId: Value(subjectId),
        day: '2026-10-12',
        filePath: sampleRelPath,
        createdAt: 1003,
      ),
    );

    await tester.pumpWidget(createSubjectUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Robotics'), findsOneWidget);

    // 2. Find and tap delete button for Robotics
    final roboticsTile = find.ancestor(
      of: find.text('Robotics'),
      matching: find.byType(ListTile),
    );
    final deleteButton = find.descendant(
      of: roboticsTile,
      matching: find.byIcon(Icons.delete_outline),
    );

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // 3. Verify dialog shows both counts in plain words
    expect(find.text('Delete Robotics?'), findsOneWidget);
    expect(
      find.text(
        'This will delete 2 time entries and 1 work sample for Robotics. '
        'Work samples and their image files will be permanently deleted. This cannot be undone.',
      ),
      findsOneWidget,
    );

    // 4. Tap Delete in dialog
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Delete'),
    ));
    await tester.pumpAndSettle();

    // 5. Verify subject, log entries, and work samples are gone from DB and UI
    expect(find.text('Robotics'), findsNothing);
    final subjects = await subjectRepo.getAll();
    expect(subjects.any((s) => s.id == subjectId), isFalse);

    expect(await subjectRepo.countLogEntriesForSubject(subjectId), 0);
    expect(await sampleRepo.getById(sampleId), isNull);

    // 6. Verify image file on disk is deleted
    expect(sampleFile.existsSync(), isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });


  testWidgets('Deleting an unused subject prompts confirmation and removes it',
      (WidgetTester tester) async {
    await subjectRepo.add(
      SubjectsCompanion.insert(name: 'Astronomy'),
    );

    await tester.pumpWidget(createSubjectUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Astronomy'), findsOneWidget);

    final astronomyTile = find.ancestor(
      of: find.text('Astronomy'),
      matching: find.byType(ListTile),
    );
    final deleteButton = find.descendant(
      of: astronomyTile,
      matching: find.byIcon(Icons.delete_outline),
    );

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Confirmation dialog
    expect(find.text('Delete Astronomy?'), findsOneWidget);
    expect(find.text('Are you sure you want to delete this subject?'), findsOneWidget);

    // Tap Delete in dialog
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Delete'),
    ));
    await tester.pumpAndSettle();

    // Subject must be gone
    expect(find.text('Astronomy'), findsNothing);
    final subjects = await subjectRepo.getAll();
    expect(subjects.any((s) => s.name == 'Astronomy'), isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

