import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';

void main() {
  test('Migrates from schema version 1 to 2 cleanly', () async {
    // 1. Create in-memory database initialized at schema version 1 via setup hook
    final connection = NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute('''
          CREATE TABLE IF NOT EXISTS children (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            rule_id TEXT NOT NULL,
            school_year_start TEXT NOT NULL,
            school_year_end TEXT NOT NULL,
            created_at INTEGER NOT NULL
          );
          CREATE TABLE IF NOT EXISTS subjects (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL COLLATE NOCASE UNIQUE,
            is_core INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0
          );
          CREATE TABLE IF NOT EXISTS log_entries (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            child_id INTEGER NOT NULL REFERENCES children(id),
            subject_id INTEGER NOT NULL REFERENCES subjects(id),
            day TEXT NOT NULL,
            minutes INTEGER NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL
          );
          CREATE TABLE IF NOT EXISTS work_samples (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            child_id INTEGER NOT NULL REFERENCES children(id),
            subject_id INTEGER REFERENCES subjects(id),
            day TEXT NOT NULL,
            title TEXT,
            file_path TEXT NOT NULL,
            created_at INTEGER NOT NULL
          );
          CREATE TABLE IF NOT EXISTS custom_rules (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            label TEXT NOT NULL,
            required_hours INTEGER,
            required_days INTEGER,
            CHECK (required_hours IS NOT NULL OR required_days IS NOT NULL)
          );
          CREATE TABLE IF NOT EXISTS entitlement (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            paid_until TEXT,
            last_verified_at TEXT,
            plan TEXT NOT NULL DEFAULT 'free'
          );
          PRAGMA user_version = 1;
        ''');

        rawDb.execute('''
          INSERT INTO children (name, rule_id, school_year_start, school_year_end, created_at)
          VALUES ('Emma', 'placeholder_example', '2026-09-01', '2027-06-30', 1700000000000);
          INSERT INTO subjects (name, is_core, sort_order)
          VALUES ('Math', 1, 0);
        ''');
      },
    );

    // 2. Open this database with AppDatabase (which is schemaVersion 3)
    final db = AppDatabase(connection);
    final settingsRepo = SettingsRepository(db);

    // Trigger drift database opening / migration
    await db.customSelect('SELECT 1').get();

    // 3. Verify user_version upgraded to 3
    final versionRow = await db.customSelect('PRAGMA user_version;').getSingle();
    expect(versionRow.data['user_version'], 3);

    // 4. Verify existing v1 data was preserved
    final children = await db.select(db.children).get();
    expect(children.length, 1);
    expect(children.first.name, 'Emma');
    expect(children.first.ruleId, 'placeholder_example');

    final subjects = await db.select(db.subjects).get();
    expect(subjects.length, 1);
    expect(subjects.first.name, 'Math');

    // 5. Verify newly created app_settings table exists and functions properly
    expect(await settingsRepo.isDisclaimerAccepted(), isFalse);
    await settingsRepo.setDisclaimerAccepted(true);
    expect(await settingsRepo.isDisclaimerAccepted(), isTrue);

    // 6. Verify parent name setting can be saved and retrieved
    expect(await settingsRepo.getParentName(), isNull);
    await settingsRepo.setParentName('Sarah Jenkins');
    expect(await settingsRepo.getParentName(), 'Sarah Jenkins');

    await db.close();
  });

  test('Migrates from schema version 2 to 3 cleanly with parent name support', () async {
    // 1. Create in-memory database initialized at schema version 2
    final connection = NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute('''
          CREATE TABLE IF NOT EXISTS children (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            rule_id TEXT NOT NULL,
            school_year_start TEXT NOT NULL,
            school_year_end TEXT NOT NULL,
            created_at INTEGER NOT NULL
          );
          CREATE TABLE IF NOT EXISTS subjects (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL COLLATE NOCASE UNIQUE,
            is_core INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0
          );
          CREATE TABLE IF NOT EXISTS log_entries (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            child_id INTEGER NOT NULL REFERENCES children(id),
            subject_id INTEGER NOT NULL REFERENCES subjects(id),
            day TEXT NOT NULL,
            minutes INTEGER NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL
          );
          CREATE TABLE IF NOT EXISTS work_samples (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            child_id INTEGER NOT NULL REFERENCES children(id),
            subject_id INTEGER REFERENCES subjects(id),
            day TEXT NOT NULL,
            title TEXT,
            file_path TEXT NOT NULL,
            created_at INTEGER NOT NULL
          );
          CREATE TABLE IF NOT EXISTS custom_rules (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            label TEXT NOT NULL,
            required_hours INTEGER,
            required_days INTEGER,
            CHECK (required_hours IS NOT NULL OR required_days IS NOT NULL)
          );
          CREATE TABLE IF NOT EXISTS entitlement (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            paid_until TEXT,
            last_verified_at TEXT,
            plan TEXT NOT NULL DEFAULT 'free'
          );
          CREATE TABLE IF NOT EXISTS app_settings (
            "key" TEXT NOT NULL PRIMARY KEY,
            "value" TEXT NOT NULL
          );
          PRAGMA user_version = 2;
        ''');

        rawDb.execute('''
          INSERT INTO children (name, rule_id, school_year_start, school_year_end, created_at)
          VALUES ('Lucas', 'placeholder_example', '2026-09-01', '2027-06-30', 1700000000000);
          INSERT INTO app_settings ("key", "value") VALUES ('disclaimer_accepted', 'true');
        ''');
      },
    );

    // 2. Open this database with AppDatabase (schemaVersion 3)
    final db = AppDatabase(connection);
    final settingsRepo = SettingsRepository(db);

    await db.customSelect('SELECT 1').get();

    // 3. Verify user_version upgraded to 3
    final versionRow = await db.customSelect('PRAGMA user_version;').getSingle();
    expect(versionRow.data['user_version'], 3);

    // 4. Verify existing v2 data was preserved
    final children = await db.select(db.children).get();
    expect(children.length, 1);
    expect(children.first.name, 'Lucas');
    expect(await settingsRepo.isDisclaimerAccepted(), isTrue);

    // 5. Verify parent name setting
    expect(await settingsRepo.getParentName(), isNull);
    await settingsRepo.setParentName('David Miller');
    expect(await settingsRepo.getParentName(), 'David Miller');

    await db.close();
  });
}
