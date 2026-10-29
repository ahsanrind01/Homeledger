import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/services/sample_storage_service.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late SampleRepository sampleRepo;
  late ChildRepository childRepo;
  late Directory tempDocsDir;
  late SampleStorageService storageService;
  late int testChildId;

  // Generates small valid JPEG bytes
  Uint8List createTestJpeg() {
    final image = img.Image(width: 100, height: 100);
    img.fill(image, color: img.ColorRgb8(255, 0, 0));
    return Uint8List.fromList(img.encodeJpg(image));
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sampleRepo = SampleRepository(db);
    childRepo = ChildRepository(db);

    tempDocsDir = await Directory.systemTemp.createTemp('homeledger_storage_test_');

    // Simple passthrough processor for storage service unit tests
    storageService = SampleStorageService(
      sampleRepository: sampleRepo,
      getDocumentsDirectory: () async => tempDocsDir,
      imageProcessor: (bytes) async => bytes,
    );

    // Create a child for FK constraint
    testChildId = await childRepo.add(
      const ChildrenCompanion(
        name: drift.Value('Leo'),
        ruleId: drift.Value('mo_standard'),
        schoolYearStart: drift.Value('2026-07-01'),
        schoolYearEnd: drift.Value('2027-06-30'),
        createdAt: drift.Value(1000),
      ),
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDocsDir.exists()) {
      await tempDocsDir.delete(recursive: true);
    }
  });

  group('SampleStorageService', () {
    test('Stores file and database row with RELATIVE path (not absolute)', () async {
      final rawBytes = createTestJpeg();
      final sample = await storageService.saveSample(
        childId: testChildId,
        rawBytes: rawBytes,
        day: '2026-10-19',
        title: 'Math worksheet',
      );

      // 1. Path must be relative: samples/<childId>/<filename>.jpg
      expect(sample.filePath.startsWith('/'), isFalse,
          reason: 'Path must be relative, not absolute');
      expect(sample.filePath.startsWith('samples/$testChildId/'), isTrue);

      // 2. File must exist on disk in tempDocsDir
      final file = File(p.join(tempDocsDir.path, sample.filePath));
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), rawBytes);

      // 3. Database row exists
      final inDb = await sampleRepo.getById(sample.id);
      expect(inDb, isNotNull);
      expect(inDb!.title, 'Math worksheet');
      expect(inDb.filePath, sample.filePath);
    });

    test('deleteSample removes both disk file and database row', () async {
      final rawBytes = createTestJpeg();
      final sample = await storageService.saveSample(
        childId: testChildId,
        rawBytes: rawBytes,
        day: '2026-10-19',
        title: 'Spelling quiz',
      );

      final file = File(p.join(tempDocsDir.path, sample.filePath));
      expect(await file.exists(), isTrue);

      await storageService.deleteSample(sample.id);

      // Both file and DB row must be gone
      expect(await file.exists(), isFalse);
      expect(await sampleRepo.getById(sample.id), isNull);
    });

    test('deleteSample deletes database row even if disk file is already missing', () async {
      final rawBytes = createTestJpeg();
      final sample = await storageService.saveSample(
        childId: testChildId,
        rawBytes: rawBytes,
        day: '2026-10-19',
      );

      // Manually delete file to simulate external deletion or corruption
      final file = File(p.join(tempDocsDir.path, sample.filePath));
      await file.delete();
      expect(await file.exists(), isFalse);

      // Deleting sample should still cleanly delete database row without throwing
      await storageService.deleteSample(sample.id);
      expect(await sampleRepo.getById(sample.id), isNull);
    });

    test('Failed database row insert rolls back and deletes the created file', () async {
      final rawBytes = createTestJpeg();

      // Using invalid childId = 99999 violates FK constraint in SQLite
      expect(
        () => storageService.saveSample(
          childId: 99999,
          rawBytes: rawBytes,
          day: '2026-10-19',
        ),
        throwsA(anything),
      );

      // Verify no stray files remain in samples/ directory
      final samplesDir = Directory(p.join(tempDocsDir.path, 'samples'));
      if (await samplesDir.exists()) {
        final files = await samplesDir.list(recursive: true).where((e) => e is File).toList();
        expect(files, isEmpty, reason: 'File should have been rolled back upon insert failure');
      }
    });

    test('runOrphanCleanup removes unreferenced files and flags missing file rows', () async {
      // 1. Create a legitimate sample
      final sample = await storageService.saveSample(
        childId: testChildId,
        rawBytes: createTestJpeg(),
        day: '2026-10-19',
        title: 'Valid sample',
      );

      // 2. Create an orphan file on disk with no database row
      final orphanFile = File(p.join(tempDocsDir.path, 'samples', '$testChildId', 'orphan_sample.jpg'));
      await orphanFile.parent.create(recursive: true);
      await orphanFile.writeAsBytes([1, 2, 3]);

      // 3. Create a database row whose file does NOT exist
      final missingRowId = await sampleRepo.add(
        WorkSamplesCompanion(
          childId: drift.Value(testChildId),
          day: const drift.Value('2026-10-18'),
          title: const drift.Value('Ghost sample'),
          filePath: drift.Value('samples/$testChildId/non_existent.jpg'),
          createdAt: const drift.Value(5000),
        ),
      );

      // 4. Run orphan cleanup
      final cleanupResult = await storageService.runOrphanCleanup();

      // Orphan file must be removed
      expect(await orphanFile.exists(), isFalse);
      expect(cleanupResult.deletedFiles, contains(p.normalize('samples/$testChildId/orphan_sample.jpg')));

      // Legitimate sample must still exist
      final validFile = File(p.join(tempDocsDir.path, sample.filePath));
      expect(await validFile.exists(), isTrue);
      expect(await sampleRepo.getById(sample.id), isNotNull);

      // Missing file row must be retained in DB and reported
      expect(cleanupResult.missingFileSampleIds, contains(missingRowId));
      expect(await sampleRepo.getById(missingRowId), isNotNull);
    });
  });
}
