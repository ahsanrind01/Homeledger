import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/app/app.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/domain/rule_profile.dart';
import 'package:homeledger/domain/rule_resolution.dart';
import 'package:homeledger/features/log/log_screen.dart';
import 'package:homeledger/features/subjects/subjects_screen.dart';

void main() {
  const kTestRule = RuleProfile(
    id: 'placeholder_example',
    label: 'Standard (180 days, 900 hours)',
    requiredHours: 900,
    requiredDays: 180,
    coreSubjects: ['Math', 'Reading', 'Writing', 'Science', 'History'],
    isCustom: false,
  );

  testWidgets(
      'First run E2E without manual subject creation: seeds subjects, allows adding child, logging time and shows 30 min on Home',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Fixed clock date falling comfortably inside default school year (Aug 1 to May 31 or Sep 1 to Jun 30)
    final fixedClock = DateTime(2026, 10, 20, 10, 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(fixedClock),
          ruleProfilesProvider.overrideWith((ref) => [kTestRule]),
          resolveRuleProvider('placeholder_example').overrideWith(
            (ref) => Future.value(const RuleResolutionFound(kTestRule)),
          ),
        ],
        child: const HomeledgerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Disclaimer screen shown
    expect(find.text('I understand'), findsOneWidget);
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();

    // 2. Add Child screen shown
    expect(find.text("Child's name"), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Emma');
    await tester.pumpAndSettle();

    // Save child
    final saveButton = find.widgetWithText(FilledButton, 'Save child');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // 3. Home screen shown with Emma
    expect(find.text('Emma'), findsOneWidget);

    // Tap 'Log time'
    final logTimeButton = find.widgetWithText(FilledButton, 'Log time');
    await tester.ensureVisible(logTimeButton);
    await tester.tap(logTimeButton);
    await tester.pumpAndSettle();

    // 4. Verify six seeded subject chips are present
    expect(find.text('Math'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Writing'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);

    // 5. Tap '+30 min' and 'Add lesson'
    final plus30Button = find.text('+30 min');
    await tester.ensureVisible(plus30Button);
    await tester.tap(plus30Button);
    await tester.pumpAndSettle();
    final addLessonButton = find.widgetWithText(FilledButton, 'Add lesson');
    await tester.ensureVisible(addLessonButton);
    await tester.tap(addLessonButton);
    await tester.pumpAndSettle();

    // Navigate back to Home
    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
    } else {
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
    }
    await tester.pumpAndSettle();

    // 6. Verify Home screen Today shows '30 min'
    expect(find.text('30 min'), findsWidgets);

    // Clean up timers
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
      'LogScreen with an empty subject table shows informative message and Add subject button',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final childRepo = ChildRepository(db);
    final childId = await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Noah',
        ruleId: 'placeholder_example',
        schoolYearStart: '2026-08-01',
        schoolYearEnd: '2027-05-31',
        createdAt: 1000,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(DateTime(2026, 10, 20)),
        ],
        child: MaterialApp(
          home: LogScreen(childId: childId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify empty state text and button
    expect(
      find.text('You have no subjects yet. Add one to start logging.'),
      findsOneWidget,
    );
    final addSubjectButton = find.widgetWithText(FilledButton, 'Add subject');
    expect(addSubjectButton, findsOneWidget);

    // Verify tap target minimum size is at least 48x48
    final size = tester.getSize(addSubjectButton);
    expect(size.width, greaterThanOrEqualTo(48.0));
    expect(size.height, greaterThanOrEqualTo(48.0));

    // Tap 'Add subject' and verify it navigates to SubjectsScreen
    await tester.tap(addSubjectButton);
    await tester.pumpAndSettle();

    expect(find.byType(SubjectsScreen), findsOneWidget);

    // Clean up timers
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
