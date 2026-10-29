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
import 'package:homeledger/features/home/home_screen.dart';
import 'package:homeledger/features/log/log_screen.dart';
import 'package:homeledger/features/paywall/paywall_screen.dart';
import 'package:homeledger/features/samples/sample_library_screen.dart';
import 'package:homeledger/features/settings/settings_screen.dart';
import 'package:homeledger/services/entitlement_service.dart';

const kTestRule = RuleProfile(
  id: 'test_rule',
  label: 'Test Rule',
  requiredHours: 100,
  coreSubjects: ['Math'],
  isCustom: false,
);

void main() {
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
  });

  Widget buildTestWrapper({
    required Widget child,
    double textScaleFactor = 1.0,
    ThemeMode themeMode = ThemeMode.light,
  }) {
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
        resolveRuleProvider('test_rule').overrideWith(
          (ref) => Future.value(const RuleResolutionFound(kTestRule)),
        ),
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        builder: (context, widget) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: widget!,
          );
        },
        home: child,
      ),
    );
  }

  group('Audit: 200% Text Scaling', () {
    testWidgets('PaywallScreen renders at 200% text scale without exceptions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestWrapper(
          child: const PaywallScreen(),
          textScaleFactor: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.text('Homeledger Plus'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('HomeScreen renders at 200% text scale without exceptions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Maya',
          ruleId: 'test_rule',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1700000000000,
        ),
      );

      await tester.pumpWidget(
        buildTestWrapper(
          child: const HomeScreen(),
          textScaleFactor: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('LogScreen renders at 200% text scale without exceptions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Maya',
          ruleId: 'test_rule',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1700000000000,
        ),
      );
      await subjectRepo.add(SubjectsCompanion.insert(name: 'Math'));

      await tester.pumpWidget(
        buildTestWrapper(
          child: LogScreen(childId: childId),
          textScaleFactor: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LogScreen), findsOneWidget);
      expect(find.text('Math'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });

  group('Audit: Dark Mode Rendering', () {
    testWidgets('HomeScreen renders cleanly in dark mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Leo',
          ruleId: 'test_rule',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1700000000000,
        ),
      );

      await tester.pumpWidget(
        buildTestWrapper(
          child: const HomeScreen(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Leo'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('PaywallScreen renders cleanly in dark mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestWrapper(
          child: const PaywallScreen(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });

  group('Audit: 0-Item Empty States', () {
    testWidgets('HomeScreen displays clear empty state when no children exist', (tester) async {
      await tester.pumpWidget(
        buildTestWrapper(
          child: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No child added yet'), findsOneWidget);
      expect(find.text('Add child'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('SampleLibraryScreen displays empty state when no samples exist', (tester) async {
      await tester.pumpWidget(
        buildTestWrapper(
          child: const SampleLibraryScreen(childId: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No work samples yet'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('SettingsScreen displays empty children state cleanly', (tester) async {
      await tester.pumpWidget(
        buildTestWrapper(
          child: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No children added yet.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
