/// Base class for all backup and restore errors.
/// Always contains a human-readable message suitable for display to parents.
abstract class BackupException implements Exception {
  final String message;

  const BackupException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the file is not a valid zip archive or has corrupted zip headers.
class BackupCorruptedException extends BackupException {
  const BackupCorruptedException([
    super.message = 'The selected file is not a valid or readable backup archive.',
  ]);
}

/// Thrown when the archive is missing required files (manifest.json or homeledger.sqlite).
class BackupInvalidBackupException extends BackupException {
  const BackupInvalidBackupException([
    super.message = 'The selected file is not a Homeledger backup.',
  ]);
}

/// Thrown when the backup's schema version is newer than the app's current schema.
class BackupNewerVersionException extends BackupException {
  const BackupNewerVersionException([
    super.message = 'This backup is from a newer version of Homeledger. Please update the app.',
  ]);
}

/// Thrown when the unzipped SQLite database fails PRAGMA integrity_check.
class BackupIntegrityCheckFailedException extends BackupException {
  const BackupIntegrityCheckFailedException([
    super.message = 'Database integrity check failed. The backup file may be corrupted.',
  ]);
}

/// Thrown when an archive entry attempts path traversal (e.g. `../../`) or unsafe extraction.
class BackupSecurityException extends BackupException {
  const BackupSecurityException([
    super.message = 'The backup archive contains invalid or unsafe file paths.',
  ]);
}

/// Thrown when a backup zip exceeds the safety size limit.
class BackupTooLargeException extends BackupException {
  const BackupTooLargeException([
    super.message = 'The selected backup exceeds the maximum allowed file size of 2 GB.',
  ]);
}

/// Thrown when performRestore fails and the safety copy is restored.
class BackupRestoreFailedException extends BackupException {
  const BackupRestoreFailedException([
    super.message = 'Restore failed. Your data on this phone was not changed.',
  ]);
}

