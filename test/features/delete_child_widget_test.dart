import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';
import 'package:homeledger/features/settings/settings_screen.dart';
import 'package:homeledger/services/sample_storage_service.dart';

void main() {
  late AppDatabase db;
  late ChildRepository childRepo;
  late SubjectRepository subjectRepo;
  late LogRepository logRepo;
  late SampleRepository sampleRepo;
  late SampleStorageService sampleStorageService;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    childRepo = ChildRepository(db);
    subjectRepo = SubjectRepository(db);
    logRepo = LogRepository(db);
    sampleRepo = SampleRepository(db);

    tempDir = Directory.systemTemp.createTempSync('homeledger_delete_child_test_');
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
        home: SettingsScreen(),
      ),
    );
  }

  testWidgets(
      'Delete child dialog plainly names child, states entry and sample count, deletes relative files and directory while leaving second child untouched',
      (WidgetTester tester) async {
    // 1. Setup Child 1 (Lucas): 3 log entries, 2 work samples (1 on disk, 1 missing)
    final childId1 = await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Lucas',
        ruleId: 'placeholder_example',
        schoolYearStart: '2026-09-01',
        schoolYearEnd: '2027-06-30',
        createdAt: 1000,
      ),
    );

    // 2. Setup Child 2 (Maya): 1 work sample on disk
    final childId2 = await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Maya',
        ruleId: 'placeholder_example',
        schoolYearStart: '2026-09-01',
        schoolYearEnd: '2027-06-30',
        createdAt: 2000,
      ),
    );

    final subjectId = await subjectRepo.add(
      SubjectsCompanion.insert(name: 'Art'),
    );

    for (var i = 1; i <= 3; i++) {
      await logRepo.add(LogEntriesCompanion.insert(
        childId: childId1,
        subjectId: subjectId,
        day: '2026-10-0$i',
        minutes: 30 * i,
        createdAt: 1000 + i,
      ));
    }

    // Create real folder and file for Child 1
    final child1Dir = Directory('${tempDir.path}/samples/$childId1');
    child1Dir.createSync(recursive: true);
    final file1 = File('${child1Dir.path}/a.jpg');
    file1.writeAsStringSync('dummy content a');
    expect(file1.existsSync(), isTrue);

    // Relative path for sample 1
    final relPath1 = 'samples/$childId1/a.jpg';
    // Relative path for sample 2 (missing from disk)
    final missingRelPath = 'samples/$childId1/missing.jpg';

    await sampleRepo.add(WorkSamplesCompanion.insert(
      childId: childId1,
      subjectId: Value(subjectId),
      day: '2026-10-01',
      title: const Value('Artwork 1'),
      filePath: relPath1,
      createdAt: 2001,
    ));

    await sampleRepo.add(WorkSamplesCompanion.insert(
      childId: childId1,
      subjectId: Value(subjectId),
      day: '2026-10-02',
      title: const Value('Artwork 2 (missing)'),
      filePath: missingRelPath,
      createdAt: 2002,
    ));

    // Create real folder and file for Child 2 (Maya)
    final child2Dir = Directory('${tempDir.path}/samples/$childId2');
    child2Dir.createSync(recursive: true);
    final fileChild2 = File('${child2Dir.path}/b.jpg');
    fileChild2.writeAsStringSync('dummy content b');
    expect(fileChild2.existsSync(), isTrue);

    final relPathChild2 = 'samples/$childId2/b.jpg';
    await sampleRepo.add(WorkSamplesCompanion.insert(
      childId: childId2,
      subjectId: Value(subjectId),
      day: '2026-10-01',
      title: const Value('Maya Artwork'),
      filePath: relPathChild2,
      createdAt: 3001,
    ));

    // Verify initial counts
    expect(await logRepo.countForChild(childId1), 3);
    expect(await sampleRepo.countForChild(childId1), 2);
    expect(await sampleRepo.countForChild(childId2), 1);

    // 2. Pump SettingsScreen
    await tester.pumpWidget(createSubjectUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Lucas'), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);

    // Find and tap delete button for Lucas
    final lucasTile = find.ancestor(
      of: find.text('Lucas'),
      matching: find.byType(ListTile),
    );
    final deleteButton = find.descendant(
      of: lucasTile,
      matching: find.byIcon(Icons.delete_outline),
    );
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // 3. Verify dialog content matches specifications
    expect(find.text('Delete Lucas?'), findsOneWidget);
    expect(
      find.text('This will delete 3 log entries and 2 work samples for Lucas. This cannot be undone.'),
      findsOneWidget,
    );

    // 4. Confirm deletion
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Delete'),
    ));
    await tester.pumpAndSettle();

    // 5. Verify database records for Lucas are deleted via cascade
    final remainingChildren = await childRepo.getAll();
    expect(remainingChildren.map((c) => c.name), ['Maya']);
    expect(await logRepo.countForChild(childId1), 0);
    expect(await sampleRepo.countForChild(childId1), 0);

    // 6. Verify real files and folder for Child 1 are deleted
    expect(file1.existsSync(), isFalse);
    expect(child1Dir.existsSync(), isFalse);

    // 7. Verify Child 2's file and folder are completely untouched
    expect(fileChild2.existsSync(), isTrue);
    expect(child2Dir.existsSync(), isTrue);
    expect(await sampleRepo.countForChild(childId2), 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
