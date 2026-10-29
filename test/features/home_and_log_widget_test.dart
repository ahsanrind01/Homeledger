import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/custom_rule_repository.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';
import 'package:homeledger/domain/rule_profile.dart';
import 'package:homeledger/domain/rule_resolution.dart';
import 'package:homeledger/features/home/home_screen.dart';
import 'package:homeledger/features/log/log_screen.dart';

void main() {
  late AppDatabase db;
  late ChildRepository childRepo;
  late SubjectRepository subjectRepo;
  late LogRepository logRepo;
  late SettingsRepository settingsRepo;
  late CustomRuleRepository customRuleRepo;

  final fixedClock = DateTime(2026, 9, 15, 10, 0); // September 15, 2026

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
    DateTime? clock,
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
        clockProvider.overrideWithValue(clock ?? fixedClock),
        ...additionalOverrides,
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  Future<int> createTestChild({
    String name = 'Alice',
    String ruleId = 'test_rule',
    String start = '2026-09-01',
    String end = '2027-06-30',
  }) {
    return childRepo.add(
      ChildrenCompanion.insert(
        name: name,
        ruleId: ruleId,
        schoolYearStart: start,
        schoolYearEnd: end,
        createdAt: 1000,
      ),
    );
  }

  Future<int> createTestSubject({
    String name = 'Math',
    bool isCore = true,
  }) {
    return subjectRepo.add(
      SubjectsCompanion.insert(
        name: name,
        isCore: drift.Value(isCore),
        sortOrder: const drift.Value(1),
      ),
    );
  }

  group('Home and Log Screen Widget Tests', () {
    testWidgets('Quick +30 adds an entry and deleting it removes it',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final childId = await createTestChild();
      final subjectId = await createTestSubject(name: 'Math');

      await tester.pumpWidget(
        buildTestApp(
          child: LogScreen(childId: childId),
        ),
      );
      await tester.pumpAndSettle();

      // Subject chip should be present
      expect(find.byKey(ValueKey('subject_chip_$subjectId')), findsOneWidget);

      // Verify no entries yet
      expect(find.text('No entries logged for this date.'), findsOneWidget);

      // Tap +30 min quick button
      final quick30Btn = find.byKey(const ValueKey('quick_add_30'));
      expect(quick30Btn, findsOneWidget);
      await tester.tap(quick30Btn);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('custom_add_button')));
      await tester.pumpAndSettle();

      // Entry should now exist in database and on screen
      final dayEntries = await logRepo.getForDay(childId, '2026-09-15');
      expect(dayEntries.length, 1);
      expect(dayEntries.first.minutes, 30);
      expect(find.text('30 min'), findsWidgets);
      expect(find.text('Added 30 min of Math.'), findsOneWidget);

      // Delete entry directly via delete icon
      final deleteBtn = find.byTooltip('Delete entry');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Entry should now be removed
      final dayEntriesAfterUndo =
          await logRepo.getForDay(childId, '2026-09-15');
      expect(dayEntriesAfterUndo.isEmpty, isTrue);
      expect(find.text('No entries logged for this date.'), findsOneWidget);

      // Flush SnackBar and query stream timers
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('Blocked entry (>24 h) shows error message and does not log',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final childId = await createTestChild();
      await createTestSubject(name: 'Reading');

      await tester.pumpWidget(
        buildTestApp(
          child: LogScreen(childId: childId),
        ),
      );
      await tester.pumpAndSettle();

      // Enter 1500 minutes (25 hours) in custom minutes field
      final minutesInput = find.byKey(const ValueKey('custom_minutes_input'));
      await tester.enterText(minutesInput, '1500');
      await tester.pumpAndSettle();

      // Tap Add button
      final addBtn = find.byKey(const ValueKey('custom_add_button'));
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Blocked message should appear
      expect(find.text('Daily total cannot exceed 24 hours'), findsOneWidget);

      // Database should remain empty
      final dayEntries = await logRepo.getForDay(childId, '2026-09-15');
      expect(dayEntries.isEmpty, isTrue);

      // Flush SnackBar and query stream timers
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('Editing an entry updates the total on Home',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final childId = await createTestChild();
      final subjectId = await createTestSubject(name: 'Science');

      // Add initial 30 min entry
      final entryId = await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: subjectId,
          day: '2026-09-15',
          minutes: 30,
          createdAt: 1000,
        ),
      );

      // Pump Home screen
      await tester.pumpWidget(
        buildTestApp(
          child: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Home should show 30 min today
      final todayText =
          tester.widget<Text>(find.byKey(const ValueKey('home_today_total_text')));
      expect(todayText.data, '30 min');

      // Tap "Log time" to navigate to LogScreen
      final logTimeBtn = find.byKey(const ValueKey('home_log_time_button'));
      await tester.tap(logTimeBtn);
      await tester.pumpAndSettle();

      // Edit the entry
      final editBtn = find.byTooltip('Edit entry');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Change minutes to 45
      final minutesField = find.widgetWithText(TextField, '45').evaluate().isEmpty
          ? find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            ).first
          : find.widgetWithText(TextField, '45');

      await tester.enterText(minutesField, '45');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Check DB
      final updatedEntry = await logRepo.getById(entryId);
      expect(updatedEntry!.minutes, 45);

      // Navigate back to Home screen
      final backButton = find.byType(BackButton).evaluate().isNotEmpty
          ? find.byType(BackButton)
          : find.byTooltip('Back');
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Home should now reflect 45 min today
      final updatedTodayText =
          tester.widget<Text>(find.byKey(const ValueKey('home_today_total_text')));
      expect(updatedTodayText.data, '45 min');

      // Flush SnackBar and query stream timers
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('Home status changes after logging, using a fixed clock',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Setup child with rule resolution returning 100 hours
      final childId = await createTestChild();
      final subjectId = await createTestSubject(name: 'Math');

      const testRule = RuleProfile(
        id: 'test_rule',
        label: 'Test Rule',
        requiredHours: 100, // 6000 minutes
        coreSubjects: ['Math'],
        isCustom: false,
      );

      final overrides = [
        resolveRuleProvider('test_rule')
            .overrideWith((ref) => Future.value(const RuleResolutionFound(testRule))),
      ];

      // On September 15 (day 15 of 303), with 0 logged minutes, status is 'Behind'
      await tester.pumpWidget(
        buildTestApp(
          child: const HomeScreen(),
          additionalOverrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Verify status is 'Behind'
      expect(find.text('Behind'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      // Now add a log entry of 300 minutes (5 hours)
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: subjectId,
          day: '2026-09-15',
          minutes: 300,
          createdAt: 1000,
        ),
      );

      // Re-pump widget to see reactive update
      await tester.pump();
      await tester.pumpAndSettle();

      // Status should have changed from 'Behind' to 'On pace'
      expect(find.text('Behind'), findsNothing);
      expect(find.text('On pace'), findsOneWidget);
      expect(find.text('5%'), findsOneWidget); // 300 min / 6000 min = 5%

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('Missing child rule shows clear message and button to choose a rule',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Child with rule that cannot be resolved
      await createTestChild(ruleId: 'missing_rule_id');

      final overrides = [
        resolveRuleProvider('missing_rule_id')
            .overrideWith((ref) => Future.value(const RuleResolutionMissing('missing_rule_id'))),
      ];

      await tester.pumpWidget(
        buildTestApp(
          child: const HomeScreen(),
          additionalOverrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Should show rule missing card and button without crashing
      expect(find.byKey(const ValueKey('home_rule_missing_card')), findsOneWidget);
      expect(find.text('Rule missing'), findsOneWidget);
      expect(find.byKey(const ValueKey('home_choose_rule_button')), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
