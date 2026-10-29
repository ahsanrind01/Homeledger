import 'dart:io';

import '../data/repositories/child_repository.dart';
import 'sample_storage_service.dart';

/// Result summary of deleting a child and its associated sample files.
class ChildDeletionResult {
  /// Number of files successfully removed from disk.
  final int filesDeleted;

  /// Number of files either already missing from disk or that failed to delete.
  final int filesMissingOrFailed;

  const ChildDeletionResult({
    required this.filesDeleted,
    required this.filesMissingOrFailed,
  });
}

/// Service that coordinates deleting a child record, cascading database deletions,
/// resolving and deleting physical work sample files, and removing the child's sample directory.
class ChildDeletionService {
  final ChildRepository childRepository;
  final SampleStorageService sampleStorageService;

  ChildDeletionService({
    required this.childRepository,
    required this.sampleStorageService,
  });

  /// Deletes a child by ID:
  /// 1. Executes [ChildRepository.deleteChildCascade] in a single transaction, returning relative file paths.
  /// 2. Resolves each relative path via [sampleStorageService.resolveFile] and deletes it if present.
  /// 3. Recursively deletes the child's sample folder (`samples/<childId>`) if it exists.
  /// 4. Returns a [ChildDeletionResult] with counts of deleted and missing/failed files.
  Future<ChildDeletionResult> deleteChild(int childId) async {
    final filePaths = await childRepository.deleteChildCascade(childId);

    var filesDeleted = 0;
    var filesMissingOrFailed = 0;

    for (final path in filePaths) {
      try {
        final file = await sampleStorageService.resolveFile(path);
        if (file.existsSync()) {
          file.deleteSync();
          filesDeleted++;
        } else {
          filesMissingOrFailed++;
        }
      } catch (_) {
        filesMissingOrFailed++;
      }
    }

    try {
      final childFolderFile = await sampleStorageService.resolveFile('samples/$childId');
      final childFolder = Directory(childFolderFile.path);
      if (childFolder.existsSync()) {
        childFolder.deleteSync(recursive: true);
      }
    } catch (_) {
      // Ignore folder deletion errors
    }

    return ChildDeletionResult(
      filesDeleted: filesDeleted,
      filesMissingOrFailed: filesMissingOrFailed,
    );
  }
}
