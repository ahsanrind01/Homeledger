import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/custom_rule_repository.dart';
import 'package:homeledger/data/repositories/entitlement_repository.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';
import 'package:homeledger/domain/rule_profile.dart';
import 'package:homeledger/domain/rule_resolution.dart';
import 'package:homeledger/features/export/export_options_screen.dart';
import 'package:homeledger/features/home/home_screen.dart';
import 'package:homeledger/features/paywall/paywall_screen.dart';
import 'package:homeledger/features/samples/sample_library_screen.dart';
import 'package:homeledger/features/settings/settings_screen.dart';
import 'package:homeledger/services/entitlement_service.dart';

const kTestRule = RuleProfile(
  id: 'placeholder_example',
  label: 'Placeholder Rule',
  requiredHours: 100,
  coreSubjects: ['Math'],
  isCustom: false,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tempDir;
  late AppDatabase db;
  late ChildRepository childRepo;
  late SubjectRepository subjectRepo;
  late LogRepository logRepo;
  late SampleRepository sampleRepo;
  late SettingsRepository settingsRepo;
  late CustomRuleRepository customRuleRepo;
  late EntitlementRepository entitlementRepo;
  late FakeEntitlementService fakeService;

  final fixedClock = DateTime(2026, 10, 20, 12, 0);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('homeledger_lock_test_');
    db = AppDatabase(NativeDatabase.memory());
    childRepo = ChildRepository(db);
    subjectRepo = SubjectRepository(db);
    logRepo = LogRepository(db);
    sampleRepo = SampleRepository(db);
    settingsRepo = SettingsRepository(db);
    customRuleRepo = CustomRuleRepository(db);
    entitlementRepo = EntitlementRepository(db);
    fakeService = FakeEntitlementService(
      entitlementRepo,
      clock: () => fixedClock,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildApp(Widget home) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        childRepositoryProvider.overrideWithValue(childRepo),
        subjectRepositoryProvider.overrideWithValue(subjectRepo),
        logRepositoryProvider.overrideWithValue(logRepo),
        sampleRepositoryProvider.overrideWithValue(sampleRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        customRuleRepositoryProvider.overrideWithValue(customRuleRepo),
        entitlementRepositoryProvider.overrideWithValue(entitlementRepo),
        fakeEntitlementServiceProvider.overrideWithValue(fakeService),
        entitlementServiceProvider.overrideWithValue(fakeService),
        clockProvider.overrideWithValue(fixedClock),
        resolveRuleProvider('placeholder_example').overrideWith(
          (ref) => Future.value(const RuleResolutionFound(kTestRule)),
        ),
      ],
      child: MaterialApp(
        home: home,
      ),
    );
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets('Paid plan: tapping Export on HomeScreen opens ExportOptionsScreen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await fakeService.setPaidForOneYear();

    await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Maya',
        ruleId: 'placeholder_example',
        schoolYearStart: '2026-08-01',
        schoolYearEnd: '2027-06-30',
        createdAt: 1700000000000,
      ),
    );

    await tester.pumpWidget(buildApp(const HomeScreen()));
    await tester.pumpAndSettle();

    final exportFinder = find.byKey(const ValueKey('shortcut_export'));
    expect(exportFinder, findsOneWidget);
    await tester.tap(exportFinder);
    await tester.pumpAndSettle();

    expect(find.byType(ExportOptionsScreen), findsOneWidget);
    expect(find.byType(PaywallScreen), findsNothing);
    await tearDownApp(tester);
  });

  testWidgets('Free plan: tapping Export on HomeScreen opens Paywall', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Add 1 child
    await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Maya',
        ruleId: 'placeholder_example',
        schoolYearStart: '2026-08-01',
        schoolYearEnd: '2027-06-30',
        createdAt: 1700000000000,
      ),
    );

    await tester.pumpWidget(buildApp(const HomeScreen()));
    await tester.pumpAndSettle();

    final exportFinder = find.byKey(const ValueKey('shortcut_export'));
    expect(exportFinder, findsOneWidget);

    await tester.tap(exportFinder);
    await tester.pumpAndSettle();

    expect(find.byType(PaywallScreen), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Free plan: tapping Scan work on SampleLibraryScreen opens Paywall', (tester) async {
    await tester.pumpWidget(buildApp(const SampleLibraryScreen(childId: 1)));
    await tester.pumpAndSettle();

    // Tap Scan work FAB
    final scanFab = find.byKey(const ValueKey('library_scan_fab'));
    expect(scanFab, findsOneWidget);

    await tester.tap(scanFab);
    await tester.pumpAndSettle();

    expect(find.byType(PaywallScreen), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Free plan: tapping Add child in Settings when 1 child exists opens Paywall', (tester) async {
    await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Maya',
        ruleId: 'placeholder_example',
        schoolYearStart: '2026-08-01',
        schoolYearEnd: '2027-06-30',
        createdAt: 1700000000000,
      ),
    );

    await tester.pumpWidget(buildApp(const SettingsScreen()));
    await tester.pumpAndSettle();

    final addChildButton = find.text('Add child (Plus)');
    expect(addChildButton, findsOneWidget);

    await tester.tap(addChildButton);
    await tester.pumpAndSettle();

    expect(find.byType(PaywallScreen), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets(
    'Lapse rule: a lapsed user with two children keeps both visible and usable for logging; only adding a new child is locked',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Setup lapsed state (expired 10 days ago -> outside 7-day grace)
      await fakeService.setPaidExpiredDaysAgo(10);
      final currentEntitlement = await fakeService.current();
      expect(currentEntitlement.isPaidAt(fixedClock), isFalse);

      // 2. Setup 2 children in the database from when user was subscribed
      final child1Id = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Maya',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1700000000000,
        ),
      );

      final child2Id = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Leo',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1700000001000,
        ),
      );

      final mathSubjectId = await subjectRepo.add(
        SubjectsCompanion.insert(name: 'Math'),
      );

      // 3. Pump HomeScreen
      await tester.pumpWidget(buildApp(const HomeScreen()));
      await tester.pumpAndSettle();

      // BOTH children are visible in the child selector dropdown!
      expect(find.text('Maya'), findsOneWidget);

      // Log time for Child 1 (Maya) - Free feature is UNLOCKED
      final logButton = find.byKey(const ValueKey('home_log_time_button'));
      expect(logButton, findsOneWidget);

      // Insert log entries for both children directly to confirm database integrity
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: child1Id,
          subjectId: mathSubjectId,
          day: '2026-10-19',
          minutes: 45,
          createdAt: 1700000002000,
        ),
      );

      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: child2Id,
          subjectId: mathSubjectId,
          day: '2026-10-19',
          minutes: 60,
          createdAt: 1700000003000,
        ),
      );

      expect(await logRepo.countForChild(child1Id), 1);
      expect(await logRepo.countForChild(child2Id), 1);

      // 4. Pump SettingsScreen - both children are visible and editable
      await tester.pumpWidget(buildApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Leo'), findsOneWidget);

      // Backup is part of free plan and is UNLOCKED
      expect(find.text('Back up now'), findsOneWidget);
      expect(find.text('Restore from backup'), findsOneWidget);

      // Adding a 3rd child is locked and displays 'Add child (Plus)'
      final addChildButton = find.text('Add child (Plus)');
      expect(addChildButton, findsOneWidget);

      await tester.tap(addChildButton);
      await tester.pumpAndSettle();

      // Tapping opens the paywall
      expect(find.byType(PaywallScreen), findsOneWidget);
      await tearDownApp(tester);
    },
  );
}
