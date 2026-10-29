import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/app/theme.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/custom_rule_repository.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';
import 'package:homeledger/domain/feature_policy.dart';
import 'package:homeledger/domain/rule_profile.dart';
import 'package:homeledger/domain/rule_resolution.dart';
import 'package:homeledger/features/export/export_options_screen.dart';
import 'package:homeledger/features/home/home_screen.dart';
import 'package:homeledger/features/log/log_screen.dart';
import 'package:homeledger/features/progress/progress_screen.dart';
import 'package:homeledger/features/samples/sample_library_screen.dart';
import 'package:homeledger/features/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ChildRepository childRepo;
  late SubjectRepository subjectRepo;
  late LogRepository logRepo;
  late SettingsRepository settingsRepo;
  late CustomRuleRepository customRuleRepo;
  late SampleRepository sampleRepo;

  final fixedClock = DateTime(2026, 10, 20, 10, 0);
  final expectedThemeBackground = AppTheme.lightTheme.scaffoldBackgroundColor;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    childRepo = ChildRepository(db);
    subjectRepo = SubjectRepository(db);
    logRepo = LogRepository(db);
    settingsRepo = SettingsRepository(db);
    customRuleRepo = CustomRuleRepository(db);
    sampleRepo = SampleRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildAppWithTheme({
    required Widget child,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        childRepositoryProvider.overrideWithValue(childRepo),
        subjectRepositoryProvider.overrideWithValue(subjectRepo),
        logRepositoryProvider.overrideWithValue(logRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        customRuleRepositoryProvider.overrideWithValue(customRuleRepo),
        sampleRepositoryProvider.overrideWithValue(sampleRepo),
        clockProvider.overrideWithValue(fixedClock),
        featureAccessProvider(Feature.exportPdf).overrideWithValue(FeatureAccess.allowed),
        featureAccessProvider(Feature.scanSample).overrideWithValue(FeatureAccess.allowed),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  void verifyScaffoldBackground(WidgetTester tester) {
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final effectiveBg = scaffold.backgroundColor ??
        Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor;
    expect(effectiveBg, equals(expectedThemeBackground));
  }

  group('Scaffold Background Consistency Tests', () {
    testWidgets('HomeScreen Scaffold background equals theme scaffold background', (tester) async {
      await tester.pumpWidget(buildAppWithTheme(child: const HomeScreen()));
      await tester.pumpAndSettle();

      verifyScaffoldBackground(tester);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('LogScreen Scaffold background in loading, empty, and data states', (tester) async {
      // 1. Loading state (subjects stream waiting)
      await tester.pumpWidget(
        buildAppWithTheme(
          child: const LogScreen(childId: 1),
          overrides: [
            subjectsStreamProvider.overrideWith((ref) => const Stream.empty()),
          ],
        ),
      );
      await tester.pump();
      verifyScaffoldBackground(tester);

      // 2. Empty state (0 subjects)
      await tester.pumpWidget(
        buildAppWithTheme(
          child: const LogScreen(childId: 1),
          overrides: [
            subjectsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      verifyScaffoldBackground(tester);

      // 3. Data state (subjects present)
      const sub = Subject(id: 1, name: 'Math', isCore: true, sortOrder: 1);
      await tester.pumpWidget(
        buildAppWithTheme(
          child: const LogScreen(childId: 1),
          overrides: [
            subjectsStreamProvider.overrideWith((ref) => Stream.value([sub])),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      verifyScaffoldBackground(tester);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ProgressScreen Scaffold background equals theme scaffold background', (tester) async {
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Sam',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );

      final overrides = [
        resolveRuleProvider('placeholder_example').overrideWith(
          (ref) => Future.value(
            const RuleResolutionFound(
              RuleProfile(
                id: 'placeholder_example',
                label: 'Placeholder Example',
                requiredHours: 100,
              ),
            ),
          ),
        ),
      ];

      await tester.pumpWidget(
        buildAppWithTheme(
          child: ProgressScreen(childId: childId),
          overrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      verifyScaffoldBackground(tester);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('SampleLibraryScreen Scaffold background equals theme scaffold background', (tester) async {
      await tester.pumpWidget(
        buildAppWithTheme(
          child: const SampleLibraryScreen(childId: 1),
        ),
      );
      await tester.pumpAndSettle();

      verifyScaffoldBackground(tester);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('ExportOptionsScreen Scaffold background equals theme scaffold background', (tester) async {
      await tester.pumpWidget(
        buildAppWithTheme(
          child: const ExportOptionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      verifyScaffoldBackground(tester);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('SettingsScreen Scaffold background equals theme scaffold background', (tester) async {
      await tester.pumpWidget(
        buildAppWithTheme(
          child: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      verifyScaffoldBackground(tester);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
