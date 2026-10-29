import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/features/backup/backup_clients.dart';
import 'package:homeledger/features/backup/backup_manifest.dart';
import 'package:homeledger/features/backup/backup_reminder_card.dart';
import 'package:homeledger/features/backup/backup_service.dart';
import 'package:homeledger/features/home/home_screen.dart';
import 'package:homeledger/features/settings/settings_screen.dart';
import 'package:path/path.dart' as p;

class MockBackupShareClient implements BackupShareClient {
  String? sharedFilePath;
  BackupShareResult nextResult = BackupShareResult.success;

  @override
  Future<BackupShareResult> shareZip(String filePath, String subject) async {
    sharedFilePath = filePath;
    return nextResult;
  }
}


class MockFilePickerClient implements FilePickerClient {
  String? pathToReturn;

  @override
  Future<String?> pickZipFile() async => pathToReturn;
}

class MockSelectedChildIdNotifier extends SelectedChildIdNotifier {
  final int? initial;
  MockSelectedChildIdNotifier(this.initial);

  @override
  int? build() => initial;
}

void main() {
  late Directory tempDir;
  late MockBackupShareClient mockShareClient;
  late MockFilePickerClient mockFilePickerClient;
  late AppDatabase db;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('homeledger_backup_ui_test_');
    mockShareClient = MockBackupShareClient();
    mockFilePickerClient = MockFilePickerClient();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('Settings screen displays "Last backup: Never" initially', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          lastBackupDateStreamProvider.overrideWith((ref) => Stream.value(null)),
          childrenStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Backup & restore'), findsOneWidget);
    expect(find.text('Back up now'), findsOneWidget);
    expect(find.text('Last backup: Never'), findsOneWidget);
    expect(find.text('Restore from backup'), findsOneWidget);
    expect(find.text('This replaces all data on this phone.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('Settings screen displays formatted date when backup exists', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          lastBackupDateStreamProvider.overrideWith((ref) => Stream.value('2026-10-15')),
          childrenStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last backup: Oct 15, 2026'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('Restore from backup displays warning, summary, and cancels on Cancel', (tester) async {
    final unzippedDir = Directory(p.join(tempDir.path, 'mock_unzip'))..createSync(recursive: true);
    final mockZip = File(p.join(tempDir.path, 'mock.zip'))..writeAsBytesSync([1, 2, 3]);
    mockFilePickerClient.pathToReturn = mockZip.path;

    // Prepare a mock BackupService
    final fakeSummary = BackupValidationSummary(
      manifest: const BackupManifest(
        schemaVersion: 3,
        appVersion: '1.0.0',
        createdAt: '2026-10-20T10:00:00Z',
        counts: BackupCounts(children: 2, entries: 15, samples: 3),
      ),
      unzippedDir: unzippedDir,
      missingSamplePaths: const ['samples/1/missing.jpg'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          lastBackupDateStreamProvider.overrideWith((ref) => Stream.value('2026-10-15')),
          childrenStreamProvider.overrideWith((ref) => Stream.value([])),
          backupServiceProvider.overrideWith((ref) {
            return _MockBackupService(
              summaryToReturn: fakeSummary,
              db: db,
              childRepo: ref.watch(childRepositoryProvider),
              logRepo: ref.watch(logRepositoryProvider),
              sampleRepo: ref.watch(sampleRepositoryProvider),
              settingsRepo: ref.watch(settingsRepositoryProvider),
              shareClient: mockShareClient,
              filePickerClient: mockFilePickerClient,
              clock: () => DateTime(2026, 10, 20),
            );
          }),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to reveal Restore from backup if needed
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();

    // Dialog must show with required warning and summary
    expect(find.text('Restore from backup?'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('This replaces all data on this phone.'),
      ),
      findsOneWidget,
    );
    expect(find.text('Students: 2'), findsOneWidget);
    expect(find.text('Log entries: 15'), findsOneWidget);
    expect(find.text('Work samples: 3'), findsOneWidget);
    expect(find.textContaining('1 sample file(s) could not be found'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Restore from backup?'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('BackupReminderCard appears on Home when reminder is active and dismisses', (tester) async {
    const child = Child(
      id: 1,
      name: 'Maya Lin',
      ruleId: 'placeholder_example',
      schoolYearStart: '2026-08-01',
      schoolYearEnd: '2027-06-30',
      createdAt: 1700000000000,
    );

    bool dismissed = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          childrenStreamProvider.overrideWith((ref) => Stream.value([child])),
          selectedChildIdProvider.overrideWith(() => MockSelectedChildIdNotifier(1)),
          todayMinutesProvider(1).overrideWith((ref) => Stream.value(0)),
          weekMinutesProvider(1).overrideWith((ref) => Stream.value(0)),
          childProgressProvider(1).overrideWith((ref) => Stream.value(null)),
          shouldShowBackupReminderProvider.overrideWith((ref) async => !dismissed),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Reminder is shown
    expect(find.byType(BackupReminderCard), findsOneWidget);
    expect(find.text('Backup recommended'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
    expect(find.text('Back up now'), findsOneWidget);

    // Tap Dismiss
    dismissed = true;
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

class _MockBackupService extends BackupService {
  final BackupValidationSummary summaryToReturn;
  bool restorePerformed = false;

  _MockBackupService({
    required this.summaryToReturn,
    required super.db,
    required super.childRepo,
    required super.logRepo,
    required super.sampleRepo,
    required super.settingsRepo,
    required super.shareClient,
    required super.filePickerClient,
    required super.clock,
  });

  @override
  Future<BackupValidationSummary?> pickAndValidateBackup() async {
    return summaryToReturn;
  }

  @override
  Future<void> performRestore(
    BackupValidationSummary summary, {
    void Function(AppDatabase newDb)? onDatabaseReopened,
  }) async {
    restorePerformed = true;
  }
}
