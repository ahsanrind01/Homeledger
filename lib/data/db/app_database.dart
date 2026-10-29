import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Table storing homeschooling children profiles.
@DataClassName('Child')
class Children extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get ruleId => text()();
  TextColumn get schoolYearStart => text()();
  TextColumn get schoolYearEnd => text()();
  IntColumn get createdAt => integer()();
}

/// Table storing subjects (e.g. Math, Reading, Science).
/// Subject names are unique ignoring case.
class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name =>
      text().customConstraint('NOT NULL COLLATE NOCASE UNIQUE')();
  BoolColumn get isCore => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Table storing daily learning time logged per child and subject.
/// Note: day is stored strictly as text (YYYY-MM-DD). Never as a timestamp.
/// Time is stored strictly as integer minutes.
class LogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get childId => integer().references(Children, #id)();
  IntColumn get subjectId => integer().references(Subjects, #id)();
  TextColumn get day => text()();
  IntColumn get minutes => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
}

/// Table storing metadata for scanned/saved work sample files.
class WorkSamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get childId => integer().references(Children, #id)();
  IntColumn get subjectId => integer().nullable().references(Subjects, #id)();
  TextColumn get day => text()();
  TextColumn get title => text().nullable()();
  TextColumn get filePath => text()();
  IntColumn get createdAt => integer()();
}

/// Table storing parent-defined custom rule profiles.
/// Enforces that at least one of requiredHours or requiredDays must be set.
class CustomRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  IntColumn get requiredHours => integer().nullable()();
  IntColumn get requiredDays => integer().nullable()();

  @override
  List<String> get customConstraints => [
        'CHECK (required_hours IS NOT NULL OR required_days IS NOT NULL)',
      ];
}

/// Table storing app subscription / entitlement state.
/// Designed for a single row representing the device entitlement.
@DataClassName('EntitlementData')
class Entitlements extends Table {
  @override
  String get tableName => 'entitlement';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get paidUntil => text().nullable()();
  TextColumn get lastVerifiedAt => text().nullable()();
  TextColumn get plan => text().withDefault(const Constant('free'))();
}

/// Table storing simple key-value settings (e.g. disclaimer acceptance).
@DataClassName('AppSetting')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Children,
    Subjects,
    LogEntries,
    WorkSamples,
    CustomRules,
    Entitlements,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        // Enforce SQLite foreign key constraints
        await customStatement('PRAGMA foreign_keys = ON;');
      },
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.createTable(appSettings);
        }
        if (from < 3) {
          // Schema version 3: supports optional 'Parent name' field in Settings (stored in app_settings).
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'homeledger.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
