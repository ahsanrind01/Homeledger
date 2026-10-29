import 'dart:io';

import 'package:path/path.dart' as p;

/// Deletes old `homeledger-backup-*.zip` and portfolio PDF files in [tempDir]
/// that are older than 24 hours relative to [now].
/// Returns the list of deleted file paths.
Future<List<String>> cleanupOldTempFiles(
  Directory tempDir, {
  required DateTime now,
}) async {
  final deletedPaths = <String>[];
  if (!tempDir.existsSync()) {
    return deletedPaths;
  }

  try {
    final entities = tempDir.listSync(followLinks: false);
    for (final entity in entities) {
      if (entity is File) {
        final name = p.basename(entity.path);
        final isBackupZip =
            name.startsWith('homeledger-backup-') && name.endsWith('.zip');
        final isPortfolioPdf =
            name.startsWith('homeledger-') && name.endsWith('.pdf');

        if (isBackupZip || isPortfolioPdf) {
          try {
            final lastModified = entity.lastModifiedSync();
            if (now.difference(lastModified) >= const Duration(hours: 24)) {
              entity.deleteSync();
              deletedPaths.add(entity.path);
            }
          } catch (_) {}
        }
      }
    }
  } catch (_) {}

  return deletedPaths;
}
