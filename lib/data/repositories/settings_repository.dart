import '../db/app_database.dart';

/// Repository for persistent application settings (e.g. disclaimer acceptance).
class SettingsRepository {
  final AppDatabase _db;

  const SettingsRepository(this._db);

  static const String keyDisclaimerAccepted = 'disclaimer_accepted';

  /// Returns true if the one-time legal disclaimer has been accepted.
  Future<bool> isDisclaimerAccepted() async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(keyDisclaimerAccepted)))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  /// Sets the disclaimer accepted flag.
  Future<void> setDisclaimerAccepted(bool accepted) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: keyDisclaimerAccepted,
            value: accepted.toString(),
          ),
        );
  }

  /// Generic getter for string settings.
  Future<String?> getSetting(String key) async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Generic setter for string settings.
  Future<void> setSetting(String key, String value) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: value,
          ),
        );
  }

  /// Gets the last used subject ID for a child.
  Future<int?> getLastUsedSubjectId(int childId) async {
    final val = await getSetting('last_subject_$childId');
    return val != null ? int.tryParse(val) : null;
  }

  /// Sets the last used subject ID for a child.
  Future<void> setLastUsedSubjectId(int childId, int subjectId) async {
    await setSetting('last_subject_$childId', subjectId.toString());
  }

  static const String keyParentName = 'parent_name';

  /// Returns the optional parent name saved in settings, or null if none set.
  Future<String?> getParentName() async {
    final val = await getSetting(keyParentName);
    if (val == null || val.trim().isEmpty) return null;
    return val.trim();
  }

  /// Sets or clears the optional parent name.
  Future<void> setParentName(String? name) async {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await (_db.delete(_db.appSettings)
            ..where((t) => t.key.equals(keyParentName)))
          .go();
    } else {
      await setSetting(keyParentName, trimmed);
    }
  }

  /// Watches the optional parent name reactively.
  Stream<String?> watchParentName() {
    return (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(keyParentName)))
        .watchSingleOrNull()
        .map((row) {
      final val = row?.value;
      if (val == null || val.trim().isEmpty) return null;
      return val.trim();
    });
  }

  static const String keyLastBackupDate = 'last_backup_date';
  static const String keyDismissedBackupReminderDate = 'dismissed_backup_reminder_date';

  /// Returns the date when the last backup was created, or null if none.
  Future<String?> getLastBackupDate() async {
    return getSetting(keyLastBackupDate);
  }

  /// Sets the date when the last backup was completed.
  Future<void> setLastBackupDate(String date) async {
    await setSetting(keyLastBackupDate, date);
  }

  /// Watches the last backup date reactively.
  Stream<String?> watchLastBackupDate() {
    return (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(keyLastBackupDate)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  /// Gets the date when the backup reminder was dismissed, if any.
  Future<String?> getDismissedBackupReminderDate() async {
    return getSetting(keyDismissedBackupReminderDate);
  }

  /// Dismisses the backup reminder on the given date.
  Future<void> dismissBackupReminder(String date) async {
    await setSetting(keyDismissedBackupReminderDate, date);
  }

  /// Watches the dismissed backup reminder date reactively.
  Stream<String?> watchDismissedBackupReminderDate() {
    return (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(keyDismissedBackupReminderDate)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }
}

