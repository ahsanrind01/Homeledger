import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/formatters.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/child_repository.dart';
import '../../data/repositories/log_repository.dart';
import '../../data/repositories/sample_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/temp_file_cleanup.dart';
import 'backup_clients.dart';
import 'backup_exceptions.dart';
import 'backup_manifest.dart';

/// Maximum allowed backup zip file size (2 GB).
const int kMaxBackupZipSizeBytes = 2 * 1024 * 1024 * 1024;

/// Maximum total uncompressed size across all entries to prevent decompression bombs (4 GB).
const int kMaxUncompressedBackupBytes = 4 * 1024 * 1024 * 1024;

/// Summary of a successfully validated backup ready for user confirmation.
class BackupValidationSummary {
  final BackupManifest manifest;
  final Directory unzippedDir;
  final List<String> missingSamplePaths;

  const BackupValidationSummary({
    required this.manifest,
    required this.unzippedDir,
    required this.missingSamplePaths,
  });
}

/// Generates a standardized backup filename in the format:
/// `homeledger-backup-yyyy-MM-dd-HHmm.zip`.
String generateBackupZipName(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return 'homeledger-backup-$y-$m-$d-$h$min.zip';
}

/// Recursively copies directory contents synchronously.
void copyDirectorySync(Directory source, Directory destination) {
  if (!destination.existsSync()) {
    destination.createSync(recursive: true);
  }
  for (final entity in source.listSync(recursive: false)) {
    if (entity is Directory) {
      final newDir = Directory(p.join(destination.path, p.basename(entity.path)));
      copyDirectorySync(entity, newDir);
    } else if (entity is File) {
      entity.copySync(p.join(destination.path, p.basename(entity.path)));
    }
  }
}

/// Top-level isolate function for creating a zip archive without blocking the UI.
void _createZipIsolate(List<String> args) {
  final stagingDirPath = args[0];
  final targetZipPath = args[1];

  final encoder = ZipFileEncoder();
  encoder.create(targetZipPath);

  // 1. Add manifest.json
  final manifestFile = File(p.join(stagingDirPath, 'manifest.json'));
  if (manifestFile.existsSync()) {
    encoder.addFileSync(manifestFile, 'manifest.json');
  }

  // 2. Add database file
  final dbFile = File(p.join(stagingDirPath, 'homeledger.sqlite'));
  if (dbFile.existsSync()) {
    encoder.addFileSync(dbFile, 'homeledger.sqlite');
  }

  // 3. Add samples directory
  final samplesDir = Directory(p.join(stagingDirPath, 'samples'));
  if (samplesDir.existsSync()) {
    encoder.addDirectorySync(samplesDir, includeDirName: true);
  }

  encoder.closeSync();
}

/// Top-level isolate function for extracting a zip archive safely.
/// Enforces path traversal rejection and maximum decompressed size limits.
void _extractZipIsolate(List<String> args) {
  final zipFilePath = args[0];
  final targetExtractPath = args[1];

  final zipFile = File(zipFilePath);
  if (!zipFile.existsSync()) {
    throw const BackupCorruptedException('Backup file does not exist on disk.');
  }

  final bytes = zipFile.readAsBytesSync();
  // Valid zip archives must start with PK signature (0x50, 0x4B)
  if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
    throw const BackupCorruptedException();
  }

  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
    if (archive.isEmpty) {
      throw const BackupCorruptedException();
    }
  } catch (e) {
    if (e is BackupException) rethrow;
    throw const BackupCorruptedException();
  }

  int totalBytes = 0;
  for (final file in archive) {
    final rawName = file.name;
    final normalized = rawName.replaceAll('\\', '/');

    // Reject path traversal attacks (e.g. `../../` or absolute roots)
    if (normalized.startsWith('/') ||
        normalized.contains('../') ||
        normalized.contains('/..')) {
      throw const BackupSecurityException('Zip entry escapes target folder.');
    }

    final destinationPath = p.normalize(p.join(targetExtractPath, normalized));
    if (!p.isWithin(targetExtractPath, destinationPath) && destinationPath != targetExtractPath) {
      throw const BackupSecurityException('Zip entry path escapes destination.');
    }

    totalBytes += file.size;
    if (totalBytes > kMaxUncompressedBackupBytes) {
      throw const BackupTooLargeException();
    }

    if (file.isFile) {
      final outFile = File(destinationPath);
      outFile.parent.createSync(recursive: true);
      outFile.writeAsBytesSync(file.content as List<int>, flush: true);
    } else {
      Directory(destinationPath).createSync(recursive: true);
    }
  }
}

/// Minimal read-only database accessor that does not run migrations or create tables.
class _ReadOnlyBackupCheckDatabase extends drift.GeneratedDatabase {
  _ReadOnlyBackupCheckDatabase(super.executor);

  @override
  Iterable<drift.TableInfo<drift.Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  @override
  drift.MigrationStrategy get migration => drift.MigrationStrategy(
        onCreate: (m) async {},
        onUpgrade: (m, from, to) async {},
      );
}

/// Service that coordinates manual backup creation, safe validation, and restore.
class BackupService {
  final AppDatabase db;
  final ChildRepository childRepo;
  final LogRepository logRepo;
  final SampleRepository sampleRepo;
  final SettingsRepository settingsRepo;
  final BackupShareClient shareClient;
  final FilePickerClient filePickerClient;
  final Future<Directory> Function() getDocumentsDirectory;
  final Future<Directory> Function() getTempDirectory;
  final AppDatabase Function(File dbFile)? createDatabase;
  final void Function(File from, File to)? copyFile;
  final DateTime Function() clock;

  const BackupService({
    required this.db,
    required this.childRepo,
    required this.logRepo,
    required this.sampleRepo,
    required this.settingsRepo,
    required this.shareClient,
    required this.filePickerClient,
    this.getDocumentsDirectory = getApplicationDocumentsDirectory,
    this.getTempDirectory = getTemporaryDirectory,
    this.createDatabase,
    this.copyFile,
    required this.clock,
  });

  /// Creates a backup zip archive containing the SQLite database, samples, and manifest.
  /// Runs zipping in a background isolate and triggers the system share sheet.
  Future<File> createBackup() async {
    final now = clock();
    final tempDir = await getTempDirectory();
    final docsDir = await getDocumentsDirectory();

    // Clean up old backup zips and portfolio PDFs older than 24h at the start of backup
    await cleanupOldTempFiles(tempDir, now: now);

    // 1. Gather exact table counts
    final childCount = await childRepo.countAll();
    final entryCount = await logRepo.countAll();
    final sampleCount = await sampleRepo.countAll();

    final manifest = BackupManifest(
      schemaVersion: db.schemaVersion,
      appVersion: '1.0.0',
      createdAt: now.toUtc().toIso8601String(),
      counts: BackupCounts(
        children: childCount,
        entries: entryCount,
        samples: sampleCount,
      ),
    );

    // 2. Prepare staging directory
    final stageDir = Directory(
      p.join(tempDir.path, 'homeledger_backup_stage_${now.millisecondsSinceEpoch}'),
    );
    if (stageDir.existsSync()) {
      stageDir.deleteSync(recursive: true);
    }
    stageDir.createSync(recursive: true);

    try {
      // 3. Write manifest.json
      final manifestFile = File(p.join(stageDir.path, 'manifest.json'));
      manifestFile.writeAsStringSync(manifest.toRawJson(), flush: true);

      // 4. Export a consistent database file via SQLite VACUUM INTO
      final stageDbFile = File(p.join(stageDir.path, 'homeledger.sqlite'));
      final escapedDbPath = stageDbFile.path.replaceAll("'", "''");
      await db.customStatement("VACUUM INTO '$escapedDbPath';");

      // 5. Copy samples directory to staging if it exists
      final liveSamplesDir = Directory(p.join(docsDir.path, 'samples'));
      if (liveSamplesDir.existsSync()) {
        final stageSamplesDir = Directory(p.join(stageDir.path, 'samples'));
        copyDirectorySync(liveSamplesDir, stageSamplesDir);
      }

      // 6. Zip in background isolate
      final zipFileName = generateBackupZipName(now);
      final zipFile = File(p.join(tempDir.path, zipFileName));
      if (zipFile.existsSync()) {
        zipFile.deleteSync();
      }

      await Isolate.run(() => _createZipIsolate([stageDir.path, zipFile.path]));

      // 7. Open Android system share sheet
      final shareResult = await shareClient.shareZip(
        zipFile.path,
        'Homeledger Backup - ${formatDisplayDate(now)}',
      );

      // 8. Record last backup date only if share was not dismissed
      // (accept success and unavailable)
      if (shareResult != BackupShareResult.dismissed) {
        await settingsRepo.setLastBackupDate(formatIsoDate(now));
      }

      return zipFile;
    } finally {
      // Cleanup staging folder
      if (stageDir.existsSync()) {
        try {
          stageDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
  }

  /// Picks a zip file using the document picker and validates it before prompting the user.
  /// Returns null if the parent cancelled the file picker.
  Future<BackupValidationSummary?> pickAndValidateBackup() async {
    final pickedPath = await filePickerClient.pickZipFile();
    if (pickedPath == null || pickedPath.trim().isEmpty) {
      return null;
    }

    final file = File(pickedPath);
    if (!file.existsSync()) {
      throw const BackupCorruptedException('Selected backup file could not be found.');
    }

    return validateBackup(file);
  }

  /// Unzips and validates a backup zip file in a temporary staging directory.
  /// Checks manifest, schema compatibility, database integrity, and sample presence.
  Future<BackupValidationSummary> validateBackup(File zipFile) async {
    // 1. File size check
    final fileSize = zipFile.lengthSync();
    if (fileSize > kMaxBackupZipSizeBytes) {
      throw const BackupTooLargeException();
    }

    final tempDir = await getTempDirectory();
    final nowMs = clock().millisecondsSinceEpoch;
    final unzipDir = Directory(p.join(tempDir.path, 'homeledger_restore_stage_$nowMs'));
    if (unzipDir.existsSync()) {
      unzipDir.deleteSync(recursive: true);
    }
    unzipDir.createSync(recursive: true);

    try {
      // 2. Unzip in background isolate with security and decompression limit checks
      await Isolate.run(() => _extractZipIsolate([zipFile.path, unzipDir.path]));

      // 3. Validate manifest.json exists and parses
      final manifestFile = File(p.join(unzipDir.path, 'manifest.json'));
      if (!manifestFile.existsSync()) {
        throw const BackupInvalidBackupException();
      }

      final BackupManifest manifest;
      try {
        manifest = BackupManifest.fromRawJson(manifestFile.readAsStringSync());
      } catch (_) {
        throw const BackupInvalidBackupException('manifest.json is missing or corrupted.');
      }

      // 4. Validate schema version is not newer than current app
      if (manifest.schemaVersion > db.schemaVersion) {
        throw const BackupNewerVersionException();
      }

      // 5. Validate database file exists
      final dbFile = File(p.join(unzipDir.path, 'homeledger.sqlite'));
      if (!dbFile.existsSync()) {
        throw const BackupInvalidBackupException(
          'Backup archive does not contain the database file.',
        );
      }

      // 6. Open database read-only and run quick integrity check
      final checkDb = _ReadOnlyBackupCheckDatabase(NativeDatabase(dbFile));
      try {
        final rows = await checkDb.customSelect('PRAGMA integrity_check;').get();
        final result = rows.isNotEmpty && rows.first.data.isNotEmpty
            ? rows.first.data.values.first as String
            : '';
        if (result != 'ok') {
          throw const BackupIntegrityCheckFailedException();
        }

        // Check required tables exist in the raw database (no auto-creation)
        final tableRows = await checkDb.customSelect(
          "SELECT name FROM sqlite_master WHERE type='table';",
        ).get();
        final existingTables = tableRows
            .map((r) => r.data['name'] as String)
            .toSet();
        const requiredTables = {
          'children',
          'subjects',
          'log_entries',
          'work_samples',
          'custom_rules',
          'entitlement',
          'app_settings',
        };
        for (final reqTable in requiredTables) {
          if (!existingTables.contains(reqTable)) {
            throw BackupInvalidBackupException(
              'Required table "$reqTable" is missing from the backup database.',
            );
          }
        }

        final versionRows = await checkDb.customSelect('PRAGMA user_version;').get();
        final dbUserVersion = versionRows.isNotEmpty && versionRows.first.data.isNotEmpty
            ? versionRows.first.data.values.first as int
            : 0;
        if (dbUserVersion > db.schemaVersion) {
          throw const BackupNewerVersionException();
        }

        // 7. Check work sample paths in database against unzipped samples folder
        final sampleRows = await checkDb.customSelect('SELECT file_path FROM work_samples;').get();
        final missingSamples = <String>[];
        for (final s in sampleRows) {
          final filePath = s.data['file_path'] as String;
          final sampleFile = File(p.join(unzipDir.path, filePath));
          if (!sampleFile.existsSync()) {
            missingSamples.add(filePath);
          }
        }

        return BackupValidationSummary(
          manifest: manifest,
          unzippedDir: unzipDir,
          missingSamplePaths: missingSamples,
        );
      } on BackupException {
        rethrow;
      } catch (_) {
        throw const BackupIntegrityCheckFailedException();
      } finally {
        await checkDb.close();
      }
    } catch (e) {
      // Cleanup staging folder on failure
      if (unzipDir.existsSync()) {
        try {
          unzipDir.deleteSync(recursive: true);
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Performs the atomic swap restore after final parent confirmation:
  /// 1. Closes the live database connection.
  /// 2. Moves current live data to a safety folder.
  /// 3. Moves restored data into place.
  /// 4. Reopens the database (running migrations automatically if backup schema is older).
  /// 5. Writes back the phone's current entitlement state.
  /// 6. If successful, deletes safety folder and unzipped folder.
  /// 7. If anything fails, restores the safety folder and reports:
  ///    'Restore failed. Your data on this phone was not changed.'
  Future<void> performRestore(
    BackupValidationSummary summary, {
    void Function(AppDatabase newDb)? onDatabaseReopened,
  }) async {
    final docsDir = await getDocumentsDirectory();
    final tempDir = await getTempDirectory();
    final nowMs = clock().millisecondsSinceEpoch;

    final liveDbFile = File(p.join(docsDir.path, 'homeledger.sqlite'));
    final liveDbWal = File(p.join(docsDir.path, 'homeledger.sqlite-wal'));
    final liveDbShm = File(p.join(docsDir.path, 'homeledger.sqlite-shm'));
    final liveSamplesDir = Directory(p.join(docsDir.path, 'samples'));

    final safetyDir = Directory(p.join(tempDir.path, 'homeledger_safety_backup_$nowMs'));
    if (safetyDir.existsSync()) {
      safetyDir.deleteSync(recursive: true);
    }
    safetyDir.createSync(recursive: true);

    // 1. Read current entitlement state before swap (Task 2)
    Map<String, dynamic>? currentEntitlement;
    try {
      final rows = await db.customSelect('SELECT * FROM entitlement LIMIT 1;').get();
      if (rows.isNotEmpty) {
        currentEntitlement = rows.first.data;
      }
    } catch (_) {}

    // 2. Close the live database
    await db.close();

    // 3. Keep a safety copy of current live data
    try {
      if (liveDbFile.existsSync()) {
        liveDbFile.copySync(p.join(safetyDir.path, 'homeledger.sqlite'));
      }
      if (liveDbWal.existsSync()) {
        liveDbWal.copySync(p.join(safetyDir.path, 'homeledger.sqlite-wal'));
      }
      if (liveDbShm.existsSync()) {
        liveDbShm.copySync(p.join(safetyDir.path, 'homeledger.sqlite-shm'));
      }
      if (liveSamplesDir.existsSync()) {
        final targetSamples = Directory(p.join(safetyDir.path, 'samples'));
        copyDirectorySync(liveSamplesDir, targetSamples);
      }
    } catch (e) {
      _restoreSafetyFolder(safetyDir, docsDir);
      _cleanupDir(safetyDir);
      throw const BackupRestoreFailedException(
        'Restore failed. Your data on this phone was not changed.',
      );
    }

    AppDatabase? reopenedDb;
    final shouldCloseReopenedDb = onDatabaseReopened == null;
    try {
      // 4. Move restored data into live place
      if (liveDbFile.existsSync()) liveDbFile.deleteSync();
      if (liveDbWal.existsSync()) liveDbWal.deleteSync();
      if (liveDbShm.existsSync()) liveDbShm.deleteSync();
      if (liveSamplesDir.existsSync()) liveSamplesDir.deleteSync(recursive: true);

      final restoredDbFile = File(p.join(summary.unzippedDir.path, 'homeledger.sqlite'));
      if (copyFile != null) {
        copyFile!(restoredDbFile, liveDbFile);
      } else {
        restoredDbFile.copySync(liveDbFile.path);
      }

      final restoredSamplesDir = Directory(p.join(summary.unzippedDir.path, 'samples'));
      if (restoredSamplesDir.existsSync()) {
        copyDirectorySync(restoredSamplesDir, liveSamplesDir);
      }

      // 5. Reopen database and verify it can execute queries (triggers onUpgrade migrations)
      reopenedDb = createDatabase != null
          ? createDatabase!(liveDbFile)
          : AppDatabase(NativeDatabase(liveDbFile));
      await reopenedDb.customSelect('SELECT 1;').get();

      // Task 2: Write back the phone's entitlement state
      await reopenedDb.customStatement('DELETE FROM entitlement;');
      if (currentEntitlement != null && currentEntitlement.isNotEmpty) {
        final cols = currentEntitlement.keys.join(', ');
        final placeholders = List.filled(currentEntitlement.length, '?').join(', ');
        await reopenedDb.customStatement(
          'INSERT INTO entitlement ($cols) VALUES ($placeholders);',
          currentEntitlement.values.toList(),
        );
      } else {
        await reopenedDb.customStatement(
          "INSERT INTO entitlement (plan) VALUES ('free');",
        );
      }

      if (onDatabaseReopened != null) {
        onDatabaseReopened(reopenedDb);
      }
    } catch (e) {

      if (reopenedDb != null) {
        try {
          await reopenedDb.close();
        } catch (_) {}
        reopenedDb = null;
      }

      // 6. Restore safety folder if anything fails
      _restoreSafetyFolder(safetyDir, docsDir);

      // Verify safety database is readable after rollback
      final safeCheckDb = createDatabase != null
          ? createDatabase!(liveDbFile)
          : AppDatabase(NativeDatabase(liveDbFile));
      try {
        await safeCheckDb.customSelect('SELECT 1;').get();
        if (onDatabaseReopened != null) {
          onDatabaseReopened(safeCheckDb);
        }
      } finally {
        if (onDatabaseReopened == null) {
          await safeCheckDb.close();
        }
      }

      throw const BackupRestoreFailedException(
        'Restore failed. Your data on this phone was not changed.',
      );
    } finally {
      if (shouldCloseReopenedDb && reopenedDb != null) {
        try {
          await reopenedDb.close();
        } catch (_) {}
      }

      // 7. Always delete safety folder and staging folder at the end
      _cleanupDir(safetyDir);
      _cleanupDir(summary.unzippedDir);
    }
  }

  void _cleanupDir(Directory dir) {
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  void _restoreSafetyFolder(Directory safetyDir, Directory docsDir) {
    try {
      final safeDb = File(p.join(safetyDir.path, 'homeledger.sqlite'));
      if (safeDb.existsSync()) {
        final target = File(p.join(docsDir.path, 'homeledger.sqlite'));
        if (target.existsSync()) target.deleteSync();
        safeDb.copySync(target.path);
      }

      final safeWal = File(p.join(safetyDir.path, 'homeledger.sqlite-wal'));
      if (safeWal.existsSync()) {
        final target = File(p.join(docsDir.path, 'homeledger.sqlite-wal'));
        if (target.existsSync()) target.deleteSync();
        safeWal.copySync(target.path);
      }

      final safeShm = File(p.join(safetyDir.path, 'homeledger.sqlite-shm'));
      if (safeShm.existsSync()) {
        final target = File(p.join(docsDir.path, 'homeledger.sqlite-shm'));
        if (target.existsSync()) target.deleteSync();
        safeShm.copySync(target.path);
      }

      final safeSamples = Directory(p.join(safetyDir.path, 'samples'));
      if (safeSamples.existsSync()) {
        final targetSamples = Directory(p.join(docsDir.path, 'samples'));
        if (targetSamples.existsSync()) targetSamples.deleteSync(recursive: true);
        copyDirectorySync(safeSamples, targetSamples);
      }
    } catch (_) {}
  }
}
