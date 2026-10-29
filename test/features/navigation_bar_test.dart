import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/custom_rule_repository.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';
import 'package:homeledger/features/home/home_screen.dart';

void main() {
  late AppDatabase db;
  late ChildRepository childRepo;
  late SubjectRepository subjectRepo;
  late LogRepository logRepo;
  late SampleRepository sampleRepo;
  late SettingsRepository settingsRepo;
  late CustomRuleRepository customRuleRepo;

  final fixedClock = DateTime(2026, 9, 15, 10, 0);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    childRepo = ChildRepository(db);
    subjectRepo = SubjectRepository(db);
    logRepo = LogRepository(db);
    sampleRepo = SampleRepository(db);
    settingsRepo = SettingsRepository(db);
    customRuleRepo = CustomRuleRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp({required Widget child}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        childRepositoryProvider.overrideWithValue(childRepo),
        subjectRepositoryProvider.overrideWithValue(subjectRepo),
        logRepositoryProvider.overrideWithValue(logRepo),
        sampleRepositoryProvider.overrideWithValue(sampleRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        customRuleRepositoryProvider.overrideWithValue(customRuleRepo),
        clockProvider.overrideWithValue(fixedClock),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('Bottom navigation bar switches between Home, Progress, Portfolio, and Reports tabs', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Insert a child
    final childId = await childRepo.add(
      ChildrenCompanion.insert(
        name: 'Emma',
        ruleId: 'mo_default',
        schoolYearStart: '2026-08-01',
        schoolYearEnd: '2027-05-31',
        createdAt: 1000,
      ),
    );
    expect(childId, isPositive);

    await tester.pumpWidget(
      buildTestApp(child: const HomeScreen()),
    );
    await tester.pumpAndSettle();

    // Verify NavigationBar exists
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Home')), findsOneWidget);
    expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Progress')), findsOneWidget);
    expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Portfolio')), findsOneWidget);
    expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Reports')), findsOneWidget);

    // Initial tab is Home (0)
    final element = tester.element(find.byType(HomeScreen));
    final container = ProviderScope.containerOf(element);
    expect(container.read(homeTabProvider), equals(0));

    // Tap on Progress destination in NavigationBar
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.bar_chart_outlined),
    ));
    await tester.pumpAndSettle();
    expect(container.read(homeTabProvider), equals(1));

    // Tap on Portfolio destination in NavigationBar
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.folder_outlined),
    ));
    await tester.pumpAndSettle();
    expect(container.read(homeTabProvider), equals(2));

    // Tap on Reports destination in NavigationBar
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.description_outlined),
    ));
    await tester.pumpAndSettle();
    expect(container.read(homeTabProvider), equals(3));

    // Tap back to Home destination in NavigationBar
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.home_outlined),
    ));
    await tester.pumpAndSettle();
    expect(container.read(homeTabProvider), equals(0));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
