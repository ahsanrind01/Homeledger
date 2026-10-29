import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/core/strings.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/custom_rule_repository.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';
import 'package:homeledger/domain/rule_profile.dart';
import 'package:homeledger/domain/rule_resolution.dart';
import 'package:homeledger/features/progress/progress_screen.dart';

void main() {
  late AppDatabase db;
  late ChildRepository childRepo;
  late SubjectRepository subjectRepo;
  late LogRepository logRepo;
  late SettingsRepository settingsRepo;
  late CustomRuleRepository customRuleRepo;

  final fixedClock = DateTime(2026, 9, 15, 10, 0);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    childRepo = ChildRepository(db);
    subjectRepo = SubjectRepository(db);
    logRepo = LogRepository(db);
    settingsRepo = SettingsRepository(db);
    customRuleRepo = CustomRuleRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp({
    required Widget child,
    List<dynamic> additionalOverrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        childRepositoryProvider.overrideWithValue(childRepo),
        subjectRepositoryProvider.overrideWithValue(subjectRepo),
        logRepositoryProvider.overrideWithValue(logRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        customRuleRepositoryProvider.overrideWithValue(customRuleRepo),
        clockProvider.overrideWithValue(fixedClock),
        ...additionalOverrides,
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('ProgressScreen Widget Tests', () {
    testWidgets(
        'Renders required vs done, expected, remaining, days left, core subjects, bar chart, and disclaimer',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Ben',
          ruleId: 'test_state_rule',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );

      final mathId = await subjectRepo.add(
        SubjectsCompanion.insert(
          name: 'Math',
          isCore: const drift.Value(true),
          sortOrder: const drift.Value(1),
        ),
      );

      final artId = await subjectRepo.add(
        SubjectsCompanion.insert(
          name: 'Art',
          isCore: const drift.Value(false),
          sortOrder: const drift.Value(2),
        ),
      );

      // Log 120 min of Math (2h) and 60 min of Art (1h)
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: mathId,
          day: '2026-09-10',
          minutes: 120,
          createdAt: 1001,
        ),
      );
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: artId,
          day: '2026-09-12',
          minutes: 60,
          createdAt: 1002,
        ),
      );

      const testProfile = RuleProfile(
        id: 'test_state_rule',
        label: 'Test State Rule',
        requiredHours: 180, // 180 hours
        coreSubjects: ['Math'],
        isCustom: false,
      );

      final overrides = [
        resolveRuleProvider('test_state_rule').overrideWith(
          (ref) => Future.value(const RuleResolutionFound(testProfile)),
        ),
      ];

      await tester.pumpWidget(
        buildTestApp(
          child: ProgressScreen(childId: childId),
          additionalOverrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Status banner
      expect(find.text('3 h 0 min of 180 h'), findsOneWidget);

      // Summary grid
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('3 h'), findsWidgets);
      expect(find.text('Expected to date'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('177 h'), findsOneWidget);
      expect(find.text('Days left in year'), findsOneWidget);

      // Core subjects section
      expect(find.text('Core subjects'), findsOneWidget);
      expect(find.text('Total: 2 h'), findsOneWidget);

      // Hours by subject and chart
      expect(find.text('Hours by subject'), findsOneWidget);
      expect(find.text('Math (Core)'), findsOneWidget);
      expect(find.text('2 h'), findsWidgets);
      expect(find.text('Art'), findsOneWidget);
      expect(find.text('1 h'), findsWidgets);

      // Disclaimer line at the bottom
      expect(find.text(AppStrings.legalDisclaimer), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('Missing rule shows friendly card and choose rule button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Ben',
          ruleId: 'unknown_rule',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );

      final overrides = [
        resolveRuleProvider('unknown_rule').overrideWith(
          (ref) => Future.value(const RuleResolutionMissing('unknown_rule')),
        ),
      ];

      await tester.pumpWidget(
        buildTestApp(
          child: ProgressScreen(childId: childId),
          additionalOverrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rule profile missing'), findsOneWidget);
      expect(find.text('Choose a rule'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
