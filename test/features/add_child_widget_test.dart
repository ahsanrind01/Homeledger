import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/core/strings.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/domain/rule_profile.dart';
import 'package:homeledger/features/children/add_child_screen.dart';

void main() {
  late AppDatabase db;

  final sampleProfiles = [
    const RuleProfile(
      id: 'placeholder_example',
      label: 'Example State Goal (100h / 100d)',
      requiredHours: 100,
      requiredDays: 100,
      sourceUrl: 'https://example.com/statute',
      lastChecked: '2026-10-18',
    ),
    const RuleProfile(
      id: 'test_standard_profile',
      label: 'Standard Profile (900h)',
      requiredHours: 900,
      sourceUrl: 'https://state.edu/rules',
      lastChecked: '2026-10-15',
    ),
  ];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget createSubjectUnderTest() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        ruleProfilesProvider.overrideWith((ref) => sampleProfiles),
      ],
      child: const MaterialApp(
        home: AddChildScreen(),
      ),
    );
  }

  testWidgets('Validation: empty name triggers error', (WidgetTester tester) async {
    await tester.pumpWidget(createSubjectUnderTest());
    await tester.pumpAndSettle();

    // Verify placeholder warning is NOT shown for new child
    expect(find.text(AppStrings.placeholderStateWarning), findsNothing);
    expect(find.text('Source: https://example.com/statute'), findsNothing);

    // Tap Save without entering a name
    await tester.ensureVisible(find.text('Save child'));
    await tester.tap(find.text('Save child'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('When only placeholder exists (production default), Goal Setup is default',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          ruleProfilesProvider.overrideWith((ref) => [sampleProfiles.first]),
        ],
        child: const MaterialApp(home: AddChildScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Homeschool Goal (Custom)'), findsOneWidget);
    expect(find.text(AppStrings.placeholderStateWarning), findsNothing);
  });

  testWidgets('Validation: end date before start date triggers error',
      (WidgetTester tester) async {
    await tester.pumpWidget(createSubjectUnderTest());
    await tester.pumpAndSettle();

    // Enter name
    await tester.enterText(find.byType(TextField).first, 'Benjamin');

    // Change End Date to before Start Date (e.g. 2026-08-01)
    // Tap End date field to open DatePicker
    await tester.tap(find.text('End date'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // In the date picker, switch to text input mode
    final editModeButton = find.byIcon(Icons.edit_outlined);
    if (editModeButton.evaluate().isNotEmpty) {
      await tester.tap(editModeButton);
      await tester.pumpAndSettle();
    }

    // Enter date 08/01/2026 (or earlier than Sept 1 2026)
    final dateTextField = find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dateTextField, '08/01/2026');
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Tap Save
    await tester.ensureVisible(find.text('Save child'));
    await tester.tap(find.text('Save child'));
    await tester.pumpAndSettle();

    expect(find.text('End date must be after start date'), findsOneWidget);
  });

  testWidgets('Validation: school year longer than 400 days triggers error',
      (WidgetTester tester) async {
    await tester.pumpWidget(createSubjectUnderTest());
    await tester.pumpAndSettle();

    // Enter name
    await tester.enterText(find.byType(TextField).first, 'Chloe');

    // Pick End date 500 days out (e.g. 12/31/2028)
    await tester.tap(find.text('End date'), warnIfMissed: false);
    await tester.pumpAndSettle();

    final editModeButton = find.byIcon(Icons.edit_outlined);
    if (editModeButton.evaluate().isNotEmpty) {
      await tester.tap(editModeButton);
      await tester.pumpAndSettle();
    }

    final dateTextField = find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dateTextField, '12/31/2028');
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Tap Save
    await tester.ensureVisible(find.text('Save child'));
    await tester.tap(find.text('Save child'));
    await tester.pumpAndSettle();

    expect(find.text('School year cannot exceed 400 days'), findsOneWidget);
  });

  testWidgets('Custom rule creation and validation', (WidgetTester tester) async {
    await tester.pumpWidget(createSubjectUnderTest());
    await tester.pumpAndSettle();

    // Tap "Make my own rule"
    await tester.tap(find.text('Make my own rule'));
    await tester.pumpAndSettle();

    expect(find.text('Make my own rule'), findsAtLeastNWidgets(1));

    // Try submitting without hours or days
    final dialog = find.byType(AlertDialog);
    final labelField = find.descendant(
      of: dialog,
      matching: find.widgetWithText(TextField, 'Rule label'),
    );
    await tester.enterText(labelField, 'My Homeschool Rule');

    await tester.tap(find.descendant(of: dialog, matching: find.text('Save rule')));
    await tester.pumpAndSettle();

    expect(find.text('Provide hours, days, or both'), findsOneWidget);

    // Enter hours: 1000
    final hoursField = find.descendant(
      of: dialog,
      matching: find.widgetWithText(TextField, 'Required hours (optional)'),
    );
    await tester.enterText(hoursField, '1000');
    await tester.pumpAndSettle();

    // Save rule
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save rule')));
    await tester.pumpAndSettle();

    // Verify dialog closed and custom rule is selected
    expect(find.text('My Homeschool Rule (Custom)'), findsOneWidget);
    expect(find.text('Custom goal: 1000 hours'), findsOneWidget);
  });

  testWidgets('Edit child whose stored profile id is unknown: screen opens, shows fallback line, can be saved',
      (WidgetTester tester) async {
    final childId = await db.into(db.children).insert(
          ChildrenCompanion.insert(
            name: 'Leo',
            ruleId: 'nonexistent_deleted_profile',
            schoolYearStart: '2026-09-01',
            schoolYearEnd: '2027-06-30',
            createdAt: 1000,
          ),
        );
    final child = await (db.select(db.children)..where((t) => t.id.equals(childId))).getSingle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          ruleProfilesProvider.overrideWith((ref) => sampleProfiles),
          clockProvider.overrideWithValue(DateTime(2026, 10, 1)),
        ],
        child: MaterialApp(
          home: AddChildScreen(initialChild: child),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Screen opens and shows fallback warning line
    expect(find.text('Your saved rule is not available. Choose or configure goals.'), findsOneWidget);

    // Can be saved immediately with fallback rule
    await tester.ensureVisible(find.text('Update child'));
    await tester.tap(find.text('Update child'));
    await tester.pumpAndSettle();

    // Child in DB now has valid fallback rule (test_standard_profile)
    final updatedChild = await (db.select(db.children)..where((t) => t.id.equals(childId))).getSingle();
    expect(updatedChild.ruleId, 'test_standard_profile');
  });

  testWidgets('Add child default dates follow an overridden clock',
      (WidgetTester tester) async {
    final overriddenClock = DateTime(2029, 3, 15);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          ruleProfilesProvider.overrideWith((ref) => sampleProfiles),
          clockProvider.overrideWithValue(overriddenClock),
        ],
        child: const MaterialApp(
          home: AddChildScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Since month is 3 (March 2029), academic year starts Sept 1, 2028 and ends June 30, 2029
    expect(find.text('2028-09-01'), findsOneWidget);
    expect(find.text('2029-06-30'), findsOneWidget);
  });
}
