import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';
import 'package:homeledger/features/backup/backup_clients.dart';
import 'package:homeledger/features/backup/backup_exceptions.dart';
import 'package:homeledger/features/backup/backup_manifest.dart';
import 'package:homeledger/features/backup/backup_service.dart';
import 'package:homeledger/services/temp_file_cleanup.dart';
import 'package:path/path.dart' as p;

class FakeBackupShareClient implements BackupShareClient {
  String? sharedFilePath;
  String? sharedSubject;
  BackupShareResult nextResult = BackupShareResult.success;

  @override
  Future<BackupShareResult> shareZip(String filePath, String subject) async {
    sharedFilePath = filePath;
    sharedSubject = subject;
    return nextResult;
  }
}


class FakeFilePickerClient implements FilePickerClient {
  String? pathToPick;

  @override
  Future<String?> pickZipFile() async => pathToPick;
}

class _DummyQueryExecutorUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}
}

void main() {
  late Directory tempDir;
  late Directory docsDir;
  late Directory tempCacheDir;
  late File liveDbFile;
  late AppDatabase db;
  late ChildRepository childRepo;
  late LogRepository logRepo;
  late SampleRepository sampleRepo;
  late SettingsRepository settingsRepo;
  late FakeBackupShareClient fakeShareClient;
  late FakeFilePickerClient fakeFilePickerClient;
  late BackupService backupService;
  late DateTime fixedClock;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('homeledger_backup_service_test_');
    docsDir = Directory(p.join(tempDir.path, 'documents'))..createSync(recursive: true);
    tempCacheDir = Directory(p.join(tempDir.path, 'cache'))..createSync(recursive: true);

    liveDbFile = File(p.join(docsDir.path, 'homeledger.sqlite'));
    db = AppDatabase(NativeDatabase(liveDbFile));

    childRepo = ChildRepository(db);
    logRepo = LogRepository(db);
    sampleRepo = SampleRepository(db);
    settingsRepo = SettingsRepository(db);
    fakeShareClient = FakeBackupShareClient();
    fakeFilePickerClient = FakeFilePickerClient();
    fixedClock = DateTime(2026, 10, 20, 14, 30);

    backupService = BackupService(
      db: db,
      childRepo: childRepo,
      logRepo: logRepo,
      sampleRepo: sampleRepo,
      settingsRepo: settingsRepo,
      shareClient: fakeShareClient,
      filePickerClient: fakeFilePickerClient,
      getDocumentsDirectory: () async => docsDir,
      getTempDirectory: () async => tempCacheDir,
      createDatabase: (file) => AppDatabase(NativeDatabase(file)),
      clock: () => fixedClock,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> populateStandardData() async {
    final childId = await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Maya Lin',
        ruleId: 'test_rule',
        schoolYearStart: '2026-08-01',
        schoolYearEnd: '2027-06-30',
        createdAt: 1700000000000,
      ),
    );

    final subjectId = await db.into(db.subjects).insert(
          SubjectsCompanion.insert(
            name: 'Mathematics',
            isCore: const Value(true),
          ),
        );

    await logRepo.add(
      LogEntriesCompanion.insert(
        childId: childId,
        subjectId: subjectId,
        day: '2026-09-01',
        minutes: 60,
        note: const Value('Algebra equations'),
        createdAt: 1700000001000,
      ),
    );

    await logRepo.add(
      LogEntriesCompanion.insert(
        childId: childId,
        subjectId: subjectId,
        day: '2026-09-02',
        minutes: 45,
        note: const Value('Geometry proofs'),
        createdAt: 1700000002000,
      ),
    );

    // Physical sample file on disk
    final sampleRelPath = 'samples/$childId/sample_test.jpg';
    final sampleFile = File(p.join(docsDir.path, sampleRelPath));
    sampleFile.parent.createSync(recursive: true);
    sampleFile.writeAsBytesSync([10, 20, 30, 40, 50], flush: true);

    await sampleRepo.add(
      WorkSamplesCompanion.insert(
        childId: childId,
        subjectId: Value(subjectId),
        title: const Value('Math Test Sheet'),
        day: '2026-09-02',
        filePath: sampleRelPath,
        createdAt: 1700000003000,
      ),
    );

    await settingsRepo.setParentName('Sarah Lin');
    await settingsRepo.setDisclaimerAccepted(true);
  }

  test('backup then restore into a fresh database gives identical rows', () async {
    await populateStandardData();

    // 1. Create backup
    final backupZip = await backupService.createBackup();
    expect(backupZip.existsSync(), isTrue);
    expect(
      p.basename(backupZip.path),
      'homeledger-backup-2026-10-20-1430.zip',
    );
    expect(fakeShareClient.sharedFilePath, backupZip.path);

    // Verify last backup date saved in Settings
    final lastBackup = await settingsRepo.getLastBackupDate();
    expect(lastBackup, '2026-10-20');

    // 2. Validate backup
    final summary = await backupService.validateBackup(backupZip);
    expect(summary.manifest.schemaVersion, 3);
    expect(summary.manifest.appVersion, '1.0.0');
    expect(summary.manifest.counts.children, 1);
    expect(summary.manifest.counts.entries, 2);
    expect(summary.manifest.counts.samples, 1);
    expect(summary.missingSamplePaths, isEmpty);

    // 3. WIPE live database and samples to simulate fresh device or data loss
    await db.close();
    if (liveDbFile.existsSync()) liveDbFile.deleteSync();
    final liveSamplesDir = Directory(p.join(docsDir.path, 'samples'));
    if (liveSamplesDir.existsSync()) liveSamplesDir.deleteSync(recursive: true);

    // Create a fresh empty database
    db = AppDatabase(NativeDatabase(liveDbFile));
    childRepo = ChildRepository(db);
    logRepo = LogRepository(db);
    sampleRepo = SampleRepository(db);
    expect(await childRepo.countAll(), 0);
    expect(await logRepo.countAll(), 0);
    expect(await sampleRepo.countAll(), 0);

    // Rebind service to fresh db
    backupService = BackupService(
      db: db,
      childRepo: ChildRepository(db),
      logRepo: LogRepository(db),
      sampleRepo: SampleRepository(db),
      settingsRepo: SettingsRepository(db),
      shareClient: fakeShareClient,
      filePickerClient: fakeFilePickerClient,
      getDocumentsDirectory: () async => docsDir,
      getTempDirectory: () async => tempCacheDir,
      createDatabase: (file) => AppDatabase(NativeDatabase(file)),
      clock: () => fixedClock,
    );

    // 4. Perform restore
    await backupService.performRestore(
      summary,
      onDatabaseReopened: (reopenedDb) {
        db = reopenedDb;
      },
    );

    // 5. Verify all restored rows and files
    final restoredChildren = await (db.select(db.children)).get();
    expect(restoredChildren.length, 1);
    expect(restoredChildren.first.name, 'Maya Lin');

    final restoredEntries = await (db.select(db.logEntries)).get();
    expect(restoredEntries.length, 2);
    expect(restoredEntries[0].minutes, 60);
    expect(restoredEntries[1].minutes, 45);

    final restoredSamples = await (db.select(db.workSamples)).get();
    expect(restoredSamples.length, 1);
    expect(restoredSamples.first.title, 'Math Test Sheet');

    // Check physical sample file on disk
    final restoredSampleFile = File(p.join(docsDir.path, restoredSamples.first.filePath));
    expect(restoredSampleFile.existsSync(), isTrue);
    expect(restoredSampleFile.readAsBytesSync(), equals([10, 20, 30, 40, 50]));

    // Check settings
    final restoredSettings = SettingsRepository(db);
    expect(await restoredSettings.getParentName(), 'Sarah Lin');
    expect(await restoredSettings.isDisclaimerAccepted(), isTrue);
  });

  test('manifest counts match actual database counts', () async {
    await populateStandardData();

    final backupZip = await backupService.createBackup();
    final summary = await backupService.validateBackup(backupZip);

    expect(summary.manifest.counts.children, await childRepo.countAll());
    expect(summary.manifest.counts.entries, await logRepo.countAll());
    expect(summary.manifest.counts.samples, await sampleRepo.countAll());
  });

  test('a zip without a manifest is rejected', () async {
    final zipFile = File(p.join(tempCacheDir.path, 'no_manifest.zip'));
    final archive = Archive();
    // Add dummy db file without manifest.json
    archive.addFile(ArchiveFile('homeledger.sqlite', 4, [1, 2, 3, 4]));
    zipFile.writeAsBytesSync(ZipEncoder().encode(archive));

    expect(
      () => backupService.validateBackup(zipFile),
      throwsA(isA<BackupInvalidBackupException>()),
    );
  });

  test('a newer schemaVersion is refused with exact update message', () async {
    final zipFile = File(p.join(tempCacheDir.path, 'newer_schema.zip'));
    final manifest = const BackupManifest(
      schemaVersion: 999, // Far future schema
      appVersion: '2.0.0',
      createdAt: '2026-10-20T12:00:00Z',
      counts: BackupCounts(children: 1, entries: 1, samples: 0),
    );

    final archive = Archive();
    final manifestBytes = manifest.toRawJson().codeUnits;
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    archive.addFile(ArchiveFile('homeledger.sqlite', 4, [1, 2, 3, 4]));
    zipFile.writeAsBytesSync(ZipEncoder().encode(archive));

    expect(
      () => backupService.validateBackup(zipFile),
      throwsA(
        predicate<BackupNewerVersionException>((e) =>
            e.message == 'This backup is from a newer version of Homeledger. Please update the app.'),
      ),
    );
  });

  test('a corrupted zip is rejected and live data is untouched', () async {
    await populateStandardData();

    final corruptZip = File(p.join(tempCacheDir.path, 'corrupt.zip'));
    corruptZip.writeAsBytesSync([0x00, 0x11, 0x22, 0x33, 0x44, 0x55]);

    expect(
      () => backupService.validateBackup(corruptZip),
      throwsA(isA<BackupCorruptedException>()),
    );

    // Live data is completely intact
    expect(await childRepo.countAll(), 1);
    expect(await logRepo.countAll(), 2);
    expect(await sampleRepo.countAll(), 1);
  });

  test('a path traversal zip is rejected', () async {
    final evilZip = File(p.join(tempCacheDir.path, 'evil_traversal.zip'));
    final archive = Archive();
    archive.addFile(ArchiveFile('../../outside.txt', 5, 'EVIL!'.codeUnits));
    archive.addFile(ArchiveFile('homeledger.sqlite', 4, [1, 2, 3, 4]));
    archive.addFile(
      ArchiveFile(
        'manifest.json',
        50,
        const BackupManifest(
          schemaVersion: 3,
          appVersion: '1.0.0',
          createdAt: '2026-10-20T12:00:00Z',
          counts: BackupCounts(children: 0, entries: 0, samples: 0),
        ).toRawJson().codeUnits,
      ),
    );
    evilZip.writeAsBytesSync(ZipEncoder().encode(archive));

    expect(
      () => backupService.validateBackup(evilZip),
      throwsA(isA<BackupSecurityException>()),
    );

    // Verify outside file was never created
    final outsideFile = File(p.join(tempDir.path, 'outside.txt'));
    expect(outsideFile.existsSync(), isFalse);
  });

  test('a restore that fails midway puts the old data back', () async {
    await populateStandardData();

    // 1. Create a valid backup
    final backupZip = await backupService.createBackup();
    final summary = await backupService.validateBackup(backupZip);

    // 2. Add new unique record in live DB (State B)
    await childRepo.add(
      ChildrenCompanion.insert(
        name: 'New Child B',
        ruleId: 'test_rule',
        schoolYearStart: '2026-09-01',
        schoolYearEnd: '2027-06-30',
        createdAt: 1700000999000,
      ),
    );
    expect(await childRepo.countAll(), 2);

    // 3. Corrupt unzipped database inside summary so reopening in step 4 will throw!
    final unzippedDb = File(p.join(summary.unzippedDir.path, 'homeledger.sqlite'));
    unzippedDb.writeAsBytesSync([0xFF, 0xFE, 0x00, 0x01]); // Invalid SQLite header

    // 4. Attempt restore, expect failure
    expect(
      () => backupService.performRestore(summary),
      throwsA(anything),
    );

    // 5. Reopen live database and verify State B was fully preserved from safety folder!
    db = AppDatabase(NativeDatabase(liveDbFile));
    final liveChildren = await (db.select(db.children)).get();
    expect(liveChildren.length, 2);
    expect(liveChildren.any((c) => c.name == 'New Child B'), isTrue);
  });

  test('a failure injected during the swap (use a fake file operation): old data is back and the database is usable', () async {
    await populateStandardData();
    final backupZip = await backupService.createBackup();
    final summary = await backupService.validateBackup(backupZip);

    await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Child Before Failed Swap',
        ruleId: 'test_rule',
        schoolYearStart: '2026-09-01',
        schoolYearEnd: '2027-06-30',
        createdAt: 1700000999000,
      ),
    );
    expect(await childRepo.countAll(), 2);

    final failingService = BackupService(
      db: db,
      childRepo: ChildRepository(db),
      logRepo: LogRepository(db),
      sampleRepo: SampleRepository(db),
      settingsRepo: SettingsRepository(db),
      shareClient: fakeShareClient,
      filePickerClient: fakeFilePickerClient,
      getDocumentsDirectory: () async => docsDir,
      getTempDirectory: () async => tempCacheDir,
      createDatabase: (file) => AppDatabase(NativeDatabase(file)),
      clock: () => fixedClock,
      copyFile: (from, to) {
        throw const FileSystemException('Fake file operation failure during swap');
      },
    );

    expect(
      () => failingService.performRestore(
        summary,
        onDatabaseReopened: (reopenedDb) {
          db = reopenedDb;
        },
      ),
      throwsA(isA<BackupRestoreFailedException>()),
    );

    // Old data is back and database is usable
    expect(await childRepo.countAll(), 2);
    final children = await childRepo.getAll();
    expect(children.any((c) => c.name == 'Child Before Failed Swap'), isTrue);
  });


  test('an older-schema backup is migrated upon restore', () async {
    // 1. Create an older schema (v1) SQLite database
    final v1DbFile = File(p.join(tempCacheDir.path, 'v1_test.sqlite'));
    final rawDb = NativeDatabase(v1DbFile);
    final v1Db = AppDatabase(rawDb);
    // Create tables up to v1
    await v1Db.customStatement('PRAGMA user_version = 1;');
    await v1Db.into(v1Db.children).insert(
          ChildrenCompanion.insert(
            name: 'Old Schema Child',
            ruleId: 'test_rule',
            schoolYearStart: '2026-08-01',
            schoolYearEnd: '2027-06-30',
            createdAt: 1600000000000,
          ),
        );
    await v1Db.close();

    // 2. Package into a zip archive with schemaVersion: 1 in manifest
    final v1Zip = File(p.join(tempCacheDir.path, 'v1_backup.zip'));
    final archive = Archive();
    final manifest = const BackupManifest(
      schemaVersion: 1,
      appVersion: '0.9.0',
      createdAt: '2025-10-20T12:00:00Z',
      counts: BackupCounts(children: 1, entries: 0, samples: 0),
    );
    final manifestBytes = manifest.toRawJson().codeUnits;
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    archive.addFile(ArchiveFile('homeledger.sqlite', v1DbFile.lengthSync(), v1DbFile.readAsBytesSync()));
    v1Zip.writeAsBytesSync(ZipEncoder().encode(archive));

    // 3. Validate backup (schemaVersion 1 <= 3 is accepted)
    final summary = await backupService.validateBackup(v1Zip);
    expect(summary.manifest.schemaVersion, 1);

    // 4. Restore backup into live app
    await backupService.performRestore(
      summary,
      onDatabaseReopened: (reopenedDb) {
        db = reopenedDb;
      },
    );

    // 5. Verify the restored database automatically ran onUpgrade migrations to version 3
    final userVersionRow = await db.customSelect('PRAGMA user_version;').getSingle();
    final userVersion = userVersionRow.read<int>('user_version');
    expect(userVersion, 3);

    // Verify children row exists
    final restoredChildren = await (db.select(db.children)).get();
    expect(restoredChildren.length, 1);
    expect(restoredChildren.first.name, 'Old Schema Child');

    // Verify app_settings table was created by migration and can be written to
    final settings = SettingsRepository(db);
    await settings.setParentName('Migrated Parent');
    expect(await settings.getParentName(), 'Migrated Parent');
  });

  test('backup with missing required table is rejected during validation', () async {
    // Create a database missing the work_samples table
    final badDbFile = File(p.join(tempCacheDir.path, 'missing_table.sqlite'));
    final badExecutor = NativeDatabase(badDbFile);
    await badExecutor.ensureOpen(_DummyQueryExecutorUser());
    await badExecutor.runCustom('CREATE TABLE dummy (id INTEGER PRIMARY KEY);');
    await badExecutor.close();

    final badZip = File(p.join(tempCacheDir.path, 'missing_table.zip'));
    final archive = Archive();
    final manifest = const BackupManifest(
      schemaVersion: 3,
      appVersion: '1.0.0',
      createdAt: '2026-10-20T12:00:00Z',
      counts: BackupCounts(children: 0, entries: 0, samples: 0),
    );
    final manifestBytes = manifest.toRawJson().codeUnits;
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    archive.addFile(ArchiveFile('homeledger.sqlite', badDbFile.lengthSync(), badDbFile.readAsBytesSync()));
    badZip.writeAsBytesSync(ZipEncoder().encode(archive));

    expect(
      () => backupService.validateBackup(badZip),
      throwsA(isA<BackupInvalidBackupException>()),
    );
  });

  test('backup with corrupt database file is rejected and live data remains intact', () async {
    await populateStandardData();
    expect(await childRepo.countAll(), 1);

    final corruptZip = File(p.join(tempCacheDir.path, 'corrupt.zip'));
    final archive = Archive();
    final manifest = const BackupManifest(
      schemaVersion: 3,
      appVersion: '1.0.0',
      createdAt: '2026-10-20T12:00:00Z',
      counts: BackupCounts(children: 0, entries: 0, samples: 0),
    );
    final manifestBytes = manifest.toRawJson().codeUnits;
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    final corruptBytes = [1, 2, 3, 4, 5];
    archive.addFile(ArchiveFile('homeledger.sqlite', corruptBytes.length, corruptBytes));
    corruptZip.writeAsBytesSync(ZipEncoder().encode(archive));

    expect(
      () => backupService.validateBackup(corruptZip),
      throwsA(isA<BackupIntegrityCheckFailedException>()),
    );

    // Live data is completely untouched and readable
    expect(await childRepo.countAll(), 1);
  });

  test('backup with schema version higher than supported is rejected', () async {
    await populateStandardData();
    final highVersionZip = File(p.join(tempCacheDir.path, 'high_v.zip'));
    final archive = Archive();
    final manifest = const BackupManifest(
      schemaVersion: 99,
      appVersion: '99.0.0',
      createdAt: '2030-10-20T12:00:00Z',
      counts: BackupCounts(children: 0, entries: 0, samples: 0),
    );
    final manifestBytes = manifest.toRawJson().codeUnits;
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    archive.addFile(ArchiveFile('homeledger.sqlite', liveDbFile.lengthSync(), liveDbFile.readAsBytesSync()));
    highVersionZip.writeAsBytesSync(ZipEncoder().encode(archive));

    expect(
      () => backupService.validateBackup(highVersionZip),
      throwsA(isA<BackupNewerVersionException>()),
    );
  });

  test('restore maintains current device entitlement (free phone restoring paid backup)', () async {
    // Current phone is on the default FREE plan
    final liveEntitlements = await db.select(db.entitlements).get();
    expect(liveEntitlements.isEmpty || liveEntitlements.first.plan == 'free', isTrue);

    // Create a backup on a PAID device
    final paidDbFile = File(p.join(tempCacheDir.path, 'paid_device.sqlite'));
    final paidDb = AppDatabase(NativeDatabase(paidDbFile));
    await paidDb.into(paidDb.entitlements).insert(
          EntitlementsCompanion.insert(
            plan: const Value('supporter'),
            paidUntil: const Value('2028-12-31T23:59:59Z'),
            lastVerifiedAt: const Value('2026-10-01T00:00:00Z'),
          ),
        );
    await paidDb.into(paidDb.children).insert(
          ChildrenCompanion.insert(
            name: 'Child from Paid Phone',
            ruleId: 'test_rule',
            schoolYearStart: '2026-08-01',
            schoolYearEnd: '2027-06-30',
            createdAt: 1000,
          ),
        );
    await paidDb.close();

    final paidZip = File(p.join(tempCacheDir.path, 'paid_backup.zip'));
    final archive = Archive();
    final manifest = const BackupManifest(
      schemaVersion: 3,
      appVersion: '1.0.0',
      createdAt: '2026-10-20T12:00:00Z',
      counts: BackupCounts(children: 1, entries: 0, samples: 0),
    );
    final manifestBytes = manifest.toRawJson().codeUnits;
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    archive.addFile(ArchiveFile('homeledger.sqlite', paidDbFile.lengthSync(), paidDbFile.readAsBytesSync()));
    paidZip.writeAsBytesSync(ZipEncoder().encode(archive));

    final summary = await backupService.validateBackup(paidZip);
    await backupService.performRestore(
      summary,
      onDatabaseReopened: (reopenedDb) {
        db = reopenedDb;
      },
    );

    // Entitlement must STILL be free!
    final restoredEntitlements = await db.select(db.entitlements).get();
    expect(restoredEntitlements.length, 1);
    expect(restoredEntitlements.first.plan, 'free');
    expect(restoredEntitlements.first.paidUntil, isNull);

    // But data is restored
    final restoredChildren = await db.select(db.children).get();
    expect(restoredChildren.any((c) => c.name == 'Child from Paid Phone'), isTrue);
  });

  test('restore maintains current device entitlement (paid phone restoring free backup)', () async {
    // Current phone has an active PAID subscription
    await db.into(db.entitlements).insert(
          EntitlementsCompanion.insert(
            plan: const Value('supporter'),
            paidUntil: const Value('2029-01-01T00:00:00Z'),
            lastVerifiedAt: const Value('2026-10-01T00:00:00Z'),
          ),
        );

    // Create a backup on a FREE device
    final freeDbFile = File(p.join(tempCacheDir.path, 'free_device.sqlite'));
    final freeDb = AppDatabase(NativeDatabase(freeDbFile));
    await freeDb.into(freeDb.entitlements).insert(
          EntitlementsCompanion.insert(
            plan: const Value('free'),
            paidUntil: const Value(null),
          ),
        );
    await freeDb.into(freeDb.children).insert(
          ChildrenCompanion.insert(
            name: 'Child from Free Phone',
            ruleId: 'test_rule',
            schoolYearStart: '2026-08-01',
            schoolYearEnd: '2027-06-30',
            createdAt: 1000,
          ),
        );
    await freeDb.close();

    final freeZip = File(p.join(tempCacheDir.path, 'free_backup.zip'));
    final archive = Archive();
    final manifest = const BackupManifest(
      schemaVersion: 3,
      appVersion: '1.0.0',
      createdAt: '2026-10-20T12:00:00Z',
      counts: BackupCounts(children: 1, entries: 0, samples: 0),
    );
    final manifestBytes = manifest.toRawJson().codeUnits;
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    archive.addFile(ArchiveFile('homeledger.sqlite', freeDbFile.lengthSync(), freeDbFile.readAsBytesSync()));
    freeZip.writeAsBytesSync(ZipEncoder().encode(archive));

    final summary = await backupService.validateBackup(freeZip);
    await backupService.performRestore(
      summary,
      onDatabaseReopened: (reopenedDb) {
        db = reopenedDb;
      },
    );

    // Entitlement must STILL be paid!
    final restoredEntitlements = await db.select(db.entitlements).get();
    expect(restoredEntitlements.length, 1);
    expect(restoredEntitlements.first.plan, 'supporter');
    expect(restoredEntitlements.first.paidUntil, '2029-01-01T00:00:00Z');

    // Data is restored
    final restoredChildren = await db.select(db.children).get();
    expect(restoredChildren.any((c) => c.name == 'Child from Free Phone'), isTrue);
  });

  test('dismissed share leaves last backup date unchanged', () async {
    await populateStandardData();
    expect(await settingsRepo.getLastBackupDate(), isNull);

    fakeShareClient.nextResult = BackupShareResult.dismissed;
    final zipFile = await backupService.createBackup();

    expect(zipFile.existsSync(), isTrue);
    // Last backup date must NOT be set when dismissed
    expect(await settingsRepo.getLastBackupDate(), isNull);
  });

  test('successful share updates last backup date', () async {
    await populateStandardData();
    expect(await settingsRepo.getLastBackupDate(), isNull);

    fakeShareClient.nextResult = BackupShareResult.success;
    final zipFile = await backupService.createBackup();

    expect(zipFile.existsSync(), isTrue);
    // Last backup date must be updated
    expect(await settingsRepo.getLastBackupDate(), '2026-10-20');
  });

  test('cleanup removes files older than 24 hours and leaves newer ones', () async {
    final now = DateTime(2026, 10, 20, 12, 0);

    // Old backup zip (> 24 hours ago)
    final oldBackup = File(p.join(tempCacheDir.path, 'homeledger-backup-2026-10-18-1000.zip'));
    oldBackup.writeAsStringSync('old zip');
    oldBackup.setLastModifiedSync(now.subtract(const Duration(hours: 25)));

    // New backup zip (< 24 hours ago)
    final newBackup = File(p.join(tempCacheDir.path, 'homeledger-backup-2026-10-20-0800.zip'));
    newBackup.writeAsStringSync('new zip');
    newBackup.setLastModifiedSync(now.subtract(const Duration(hours: 4)));

    // Old portfolio PDF (> 24 hours ago)
    final oldPdf = File(p.join(tempCacheDir.path, 'homeledger-maya-2026-09-01-to-2026-10-01.pdf'));
    oldPdf.writeAsStringSync('old pdf');
    oldPdf.setLastModifiedSync(now.subtract(const Duration(hours: 26)));

    // New portfolio PDF (< 24 hours ago)
    final newPdf = File(p.join(tempCacheDir.path, 'homeledger-maya-2026-10-15-to-2026-10-20.pdf'));
    newPdf.writeAsStringSync('new pdf');
    newPdf.setLastModifiedSync(now.subtract(const Duration(hours: 2)));

    // Unrelated file (> 24 hours ago)
    final otherFile = File(p.join(tempCacheDir.path, 'unrelated_data.txt'));
    otherFile.writeAsStringSync('keep me');
    otherFile.setLastModifiedSync(now.subtract(const Duration(hours: 40)));

    final deleted = await cleanupOldTempFiles(tempCacheDir, now: now);

    expect(deleted, contains(oldBackup.path));
    expect(deleted, contains(oldPdf.path));
    expect(deleted.length, 2);

    expect(oldBackup.existsSync(), isFalse);
    expect(oldPdf.existsSync(), isFalse);
    expect(newBackup.existsSync(), isTrue);
    expect(newPdf.existsSync(), isTrue);
    expect(otherFile.existsSync(), isTrue);
  });
}
