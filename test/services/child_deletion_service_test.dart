import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';
import 'package:homeledger/services/child_deletion_service.dart';
import 'package:homeledger/services/sample_storage_service.dart';

void main() {
  late AppDatabase db;
  late ChildRepository childRepo;
  late SubjectRepository subjectRepo;
  late LogRepository logRepo;
  late SampleRepository sampleRepo;
  late SampleStorageService sampleStorageService;
  late ChildDeletionService childDeletionService;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    childRepo = ChildRepository(db);
    subjectRepo = SubjectRepository(db);
    logRepo = LogRepository(db);
    sampleRepo = SampleRepository(db);

    tempDir = Directory.systemTemp.createTempSync('child_del_service_test_');

    sampleStorageService = SampleStorageService(
      sampleRepository: sampleRepo,
      getDocumentsDirectory: () async => tempDir,
    );

    childDeletionService = ChildDeletionService(
      childRepository: childRepo,
      sampleStorageService: sampleStorageService,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('deleteChild removes database records, physical files, and child folder while leaving other child intact', () async {
    // 1. Create Child 1
    final childId1 = await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Lucas',
        ruleId: 'placeholder_example',
        schoolYearStart: '2026-09-01',
        schoolYearEnd: '2027-06-30',
        createdAt: 1000,
      ),
    );

    // 2. Create Child 2
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

    // Add log entries for Child 1
    await logRepo.add(LogEntriesCompanion.insert(
      childId: childId1,
      subjectId: subjectId,
      day: '2026-10-01',
      minutes: 30,
      createdAt: 1001,
    ));

    // Create real files on disk for Child 1
    final child1Dir = Directory('${tempDir.path}/samples/$childId1');
    child1Dir.createSync(recursive: true);

    final file1 = File('${child1Dir.path}/sample_1.jpg');
    file1.writeAsStringSync('sample 1 bytes');
    final relPath1 = 'samples/$childId1/sample_1.jpg';

    final file2 = File('${child1Dir.path}/sample_2.jpg');
    file2.writeAsStringSync('sample 2 bytes');
    final relPath2 = 'samples/$childId1/sample_2.jpg';

    final missingRelPath = 'samples/$childId1/missing.jpg';

    await sampleRepo.add(WorkSamplesCompanion.insert(
      childId: childId1,
      subjectId: Value(subjectId),
      day: '2026-10-01',
      title: const Value('Sample 1'),
      filePath: relPath1,
      createdAt: 3001,
    ));

    await sampleRepo.add(WorkSamplesCompanion.insert(
      childId: childId1,
      subjectId: Value(subjectId),
      day: '2026-10-02',
      title: const Value('Sample 2'),
      filePath: relPath2,
      createdAt: 3002,
    ));

    await sampleRepo.add(WorkSamplesCompanion.insert(
      childId: childId1,
      subjectId: Value(subjectId),
      day: '2026-10-03',
      title: const Value('Missing Sample'),
      filePath: missingRelPath,
      createdAt: 3003,
    ));

    // Create real file for Child 2
    final child2Dir = Directory('${tempDir.path}/samples/$childId2');
    child2Dir.createSync(recursive: true);

    final fileChild2 = File('${child2Dir.path}/maya_sample.jpg');
    fileChild2.writeAsStringSync('maya sample bytes');
    final relPathChild2 = 'samples/$childId2/maya_sample.jpg';

    await sampleRepo.add(WorkSamplesCompanion.insert(
      childId: childId2,
      subjectId: Value(subjectId),
      day: '2026-10-01',
      title: const Value('Maya Sample'),
      filePath: relPathChild2,
      createdAt: 4001,
    ));

    expect(file1.existsSync(), isTrue);
    expect(file2.existsSync(), isTrue);
    expect(child1Dir.existsSync(), isTrue);
    expect(fileChild2.existsSync(), isTrue);
    expect(child2Dir.existsSync(), isTrue);

    // Delete Child 1
    final result = await childDeletionService.deleteChild(childId1);

    expect(result.filesDeleted, 2);
    expect(result.filesMissingOrFailed, 1);

    // Child 1 files and directory are gone
    expect(file1.existsSync(), isFalse);
    expect(file2.existsSync(), isFalse);
    expect(child1Dir.existsSync(), isFalse);

    // Child 1 database rows are gone
    final children = await childRepo.getAll();
    expect(children.map((c) => c.id), [childId2]);
    expect(await logRepo.countForChild(childId1), 0);
    expect(await sampleRepo.countForChild(childId1), 0);

    // Child 2 files, directory, and rows are untouched
    expect(fileChild2.existsSync(), isTrue);
    expect(child2Dir.existsSync(), isTrue);
    expect(await sampleRepo.countForChild(childId2), 1);
  });

  test('deleteChild succeeds gracefully when child has no samples or folder', () async {
    final childId = await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Sam',
        ruleId: 'placeholder_example',
        schoolYearStart: '2026-09-01',
        schoolYearEnd: '2027-06-30',
        createdAt: 1000,
      ),
    );

    final result = await childDeletionService.deleteChild(childId);

    expect(result.filesDeleted, 0);
    expect(result.filesMissingOrFailed, 0);
    expect(await childRepo.getAll(), isEmpty);
  });
}
