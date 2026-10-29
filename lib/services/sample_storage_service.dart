import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/db/app_database.dart';
import '../data/repositories/sample_repository.dart';
import '../domain/image_processor.dart';

/// Summary of an orphan cleanup execution.
class OrphanCleanupResult {
  /// Relative paths of orphan files removed from disk.
  final List<String> deletedFiles;

  /// IDs of database rows whose files could not be found on disk.
  final List<int> missingFileSampleIds;

  const OrphanCleanupResult({
    required this.deletedFiles,
    required this.missingFileSampleIds,
  });
}

/// Service coordinating atomic storage of work sample files on disk and records in SQLite.
/// All file paths stored in the database are strictly relative to the app documents directory.
class SampleStorageService {
  final SampleRepository _sampleRepo;
  final Future<Directory> Function() _getDocumentsDirectory;
  final Future<Uint8List> Function(Uint8List) _imageProcessor;
  final DateTime Function()? clock;

  SampleStorageService({
    required SampleRepository sampleRepository,
    Future<Directory> Function()? getDocumentsDirectory,
    Future<Uint8List> Function(Uint8List)? imageProcessor,
    this.clock,
  })  : _sampleRepo = sampleRepository,
        _getDocumentsDirectory =
            getDocumentsDirectory ?? getApplicationDocumentsDirectory,
        _imageProcessor = imageProcessor ?? processImageInBackground;



  /// Generates a random alphanumeric suffix for uniqueness.
  String _randomSuffix() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Resolves a database-stored relative path to an absolute File on disk.
  Future<File> resolveFile(String relativePath) async {
    final docsDir = await _getDocumentsDirectory();
    return File(p.join(docsDir.path, relativePath));
  }

  /// Checks if a sample file exists on disk.
  Future<bool> fileExists(String relativePath) async {
    final file = await resolveFile(relativePath);
    return file.existsSync();
  }

  /// Saves a work sample:
  /// 1. Processes the image in a background isolate (orientation + resize <=1600px + JPEG ~80%).
  /// 2. Writes the processed file to `samples/<childId>/<fileName>.jpg`.
  /// 3. Inserts the database row with the relative path `samples/<childId>/<fileName>.jpg`.
  /// 4. If the database insertion fails, the created file is removed immediately.
  /// 5. If the file creation fails, no row is created.
  Future<WorkSample> saveSample({
    required int childId,
    required Uint8List rawBytes,
    required String day,
    int? subjectId,
    String? title,
  }) async {
    // 1. Process in background isolate - original bytes are not saved to disk
    final processedBytes = await _imageProcessor(rawBytes);

    // 2. Prepare directory
    final docsDir = await _getDocumentsDirectory();
    final relativeDir = p.join('samples', childId.toString());
    final absoluteDir = Directory(p.join(docsDir.path, relativeDir));
    if (!absoluteDir.existsSync()) {
      absoluteDir.createSync(recursive: true);
    }

    // 3. Unique file name and relative path
    final clockFn = clock;
    final nowMs = (clockFn != null
            ? clockFn()
            : DateTime.fromMillisecondsSinceEpoch(0))
        .millisecondsSinceEpoch;
    final fileName = 'sample_${nowMs}_${_randomSuffix()}.jpg';
    final relativePath = p.posix.join('samples', childId.toString(), fileName);
    final absoluteFile = File(p.join(docsDir.path, relativePath));

    // 4. Write file first
    absoluteFile.writeAsBytesSync(processedBytes, flush: true);

    // 5. Insert row into database
    try {
      final trimmedTitle = title?.trim();
      final rowId = await _sampleRepo.add(
        WorkSamplesCompanion(
          childId: Value(childId),
          subjectId: Value(subjectId),
          day: Value(day),
          title: Value(trimmedTitle == null || trimmedTitle.isEmpty ? null : trimmedTitle),
          filePath: Value(relativePath),
          createdAt: Value(nowMs),
        ),
      );

      final sample = await _sampleRepo.getById(rowId);
      if (sample == null) {
        throw StateError('Failed to retrieve inserted work sample row: $rowId');
      }
      return sample;
    } catch (e) {
      // Rollback: if database row creation fails, delete the written file
      if (absoluteFile.existsSync()) {
        try {
          absoluteFile.deleteSync();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Deletes a work sample and its corresponding file.
  /// If the file is already missing on disk, the database row is still deleted.
  Future<void> deleteSample(int sampleId) async {
    final sample = await _sampleRepo.getById(sampleId);
    if (sample == null) return;

    // Delete file if it exists
    final file = await resolveFile(sample.filePath);
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {}
    }

    // Always delete the row
    await _sampleRepo.delete(sampleId);
  }

  /// Finds orphan files with no database row and removes them.
  /// Finds database rows with no file on disk and returns their IDs (retaining them in the database).
  Future<OrphanCleanupResult> runOrphanCleanup() async {
    final docsDir = await _getDocumentsDirectory();
    final samplesDir = Directory(p.join(docsDir.path, 'samples'));

    final allRows = await _sampleRepo.getAll();
    final dbPaths = allRows.map((r) => p.normalize(r.filePath)).toSet();

    final missingRowIds = <int>[];
    for (final row in allRows) {
      final file = File(p.join(docsDir.path, row.filePath));
      if (!file.existsSync()) {
        missingRowIds.add(row.id);
      }
    }

    final deletedFiles = <String>[];
    if (samplesDir.existsSync()) {
      final entities = samplesDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          final relPath = p.normalize(p.relative(entity.path, from: docsDir.path));
          // If not in database, it's an orphan file -> delete it
          if (!dbPaths.contains(relPath)) {
            try {
              entity.deleteSync();
              deletedFiles.add(relPath);
            } catch (_) {}
          }
        }
      }
    }

    return OrphanCleanupResult(
      deletedFiles: deletedFiles,
      missingFileSampleIds: missingRowIds,
    );
  }
}
