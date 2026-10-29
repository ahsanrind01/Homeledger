import 'dart:io';
import 'dart:typed_data';

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
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';
import 'package:homeledger/data/rule_resolver.dart';
import 'package:homeledger/domain/requirement_caption.dart';
import 'package:homeledger/domain/rule_profile.dart';
import 'package:homeledger/domain/rule_resolution.dart';
import 'package:homeledger/features/export/export_service.dart';
import 'package:homeledger/features/export/pdf_portfolio_builder.dart';
import 'package:homeledger/features/progress/progress_screen.dart';
import 'package:homeledger/services/sample_storage_service.dart';

class MockPdfShareClient implements PdfShareClient {
  @override
  Future<void> sharePdf(String filePath, String subject) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getRequirementCaption pure unit tests', () {
    test('Placeholder profile returns exact honest disclaimer caption', () {
      final caption = getRequirementCaption(ruleId: 'placeholder_example');
      expect(
        caption,
        "Example target only. It is not your state's rule. Set your own in Edit child.",
      );
    });

    test('Custom profile returns exact honest custom target caption', () {
      final caption1 = getRequirementCaption(ruleId: 'custom:1');
      expect(caption1, "Your own target. Check your state's rules.");

      final caption2 = getRequirementCaption(ruleId: 'custom:42', isCustom: true);
      expect(caption2, "Your own target. Check your state's rules.");

      final caption3 = getRequirementCaption(ruleId: 'custom_rule', isCustom: true);
      expect(caption3, "Your own target. Check your state's rules.");
    });

    test('Real state profile returns null (no extra caption)', () {
      final caption1 = getRequirementCaption(ruleId: 'mo_standard');
      expect(caption1, isNull);

      final caption2 = getRequirementCaption(ruleId: 'fl_standard');
      expect(caption2, isNull);
    });
  });

  group('ProgressScreen & Export honest requirement caption tests', () {
    late AppDatabase db;
    late ChildRepository childRepo;
    late SubjectRepository subjectRepo;
    late LogRepository logRepo;
    late SettingsRepository settingsRepo;
    late CustomRuleRepository customRuleRepo;
    late SampleRepository sampleRepo;
    late SampleStorageService sampleStorageService;
    late Directory tempDocsDir;
    late Uint8List fontRegular;
    late Uint8List fontBold;

    final fixedClock = DateTime(2026, 10, 15, 10, 0);

    setUpAll(() {
      fontRegular = File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync();
      fontBold = File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync();
    });

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      childRepo = ChildRepository(db);
      subjectRepo = SubjectRepository(db);
      logRepo = LogRepository(db);
      settingsRepo = SettingsRepository(db);
      customRuleRepo = CustomRuleRepository(db);
      sampleRepo = SampleRepository(db);

      tempDocsDir = Directory.systemTemp.createTempSync('homeledger_caption_test_');
      sampleStorageService = SampleStorageService(
        sampleRepository: sampleRepo,
        getDocumentsDirectory: () async => tempDocsDir,
        imageProcessor: (b) async => b,
      );
    });

    tearDown(() async {
      await db.close();
      if (tempDocsDir.existsSync()) {
        tempDocsDir.deleteSync(recursive: true);
      }
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
          sampleRepositoryProvider.overrideWithValue(sampleRepo),
          sampleStorageServiceProvider.overrideWithValue(sampleStorageService),
          clockProvider.overrideWithValue(fixedClock),
          ...additionalOverrides,
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('ProgressScreen shows placeholder caption for placeholder_example', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
                label: 'Example profile (not a real state)',
                requiredHours: 100,
              ),
            ),
          ),
        ),
      ];

      await tester.pumpWidget(
        buildTestApp(
          child: ProgressScreen(childId: childId),
          additionalOverrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("Example target only. It is not your state's rule. Set your own in Edit child."),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('ProgressScreen shows custom target caption for custom:1', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Sam',
          ruleId: 'custom:1',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );

      final overrides = [
        resolveRuleProvider('custom:1').overrideWith(
          (ref) => Future.value(
            const RuleResolutionFound(
              RuleProfile(
                id: 'custom:1',
                label: 'Custom target',
                requiredHours: 850,
                isCustom: true,
              ),
            ),
          ),
        ),
      ];

      await tester.pumpWidget(
        buildTestApp(
          child: ProgressScreen(childId: childId),
          additionalOverrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("Your own target. Check your state's rules."),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('ProgressScreen shows NO requirement caption for state profile', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Sam',
          ruleId: 'mo_standard',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );

      final overrides = [
        resolveRuleProvider('mo_standard').overrideWith(
          (ref) => Future.value(
            const RuleResolutionFound(
              RuleProfile(
                id: 'mo_standard',
                label: 'Missouri standard',
                requiredHours: 1000,
                isCustom: false,
              ),
            ),
          ),
        ),
      ];

      await tester.pumpWidget(
        buildTestApp(
          child: ProgressScreen(childId: childId),
          additionalOverrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('progress_requirement_caption')), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    test('ExportService & PDF generation include requirementCaption for placeholder, custom and state rules', () async {
      final exportService = ExportService(
        childRepo: childRepo,
        logRepo: logRepo,
        subjectRepo: subjectRepo,
        settingsRepo: settingsRepo,
        sampleRepo: sampleRepo,
        ruleResolver: RuleResolver(
          customRuleRepository: customRuleRepo,
          assetProfiles: [
            const RuleProfile(
              id: 'placeholder_example',
              label: 'Placeholder Example',
              requiredHours: 100,
            ),
            const RuleProfile(
              id: 'mo_standard',
              label: 'Missouri',
              requiredHours: 1000,
            ),
          ],
        ),
        sampleStorageService: sampleStorageService,
        shareClient: MockPdfShareClient(),
        clock: () => fixedClock,
      );

      // 1. Placeholder Child
      final c1Id = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Child One',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );
      final export1 = await exportService.prepareExportData(
        childId: c1Id,
        dateRangeStart: '2026-08-01',
        dateRangeEnd: '2027-06-30',
        includeWorkSamples: false,
        customRegularFontBytes: fontRegular,
        customBoldFontBytes: fontBold,
      );
      expect(
        export1.requirementCaption,
        "Example target only. It is not your state's rule. Set your own in Edit child.",
      );
      final pdf1 = await buildPortfolioPdf(export1);
      expect(pdf1, isNotEmpty);

      // 2. Custom Target Child
      final customId = await customRuleRepo.add(
        const CustomRulesCompanion(
          label: drift.Value('Custom Goal'),
          requiredHours: drift.Value(500),
        ),
      );
      final c2Id = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Child Two',
          ruleId: 'custom:$customId',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );
      final export2 = await exportService.prepareExportData(
        childId: c2Id,
        dateRangeStart: '2026-08-01',
        dateRangeEnd: '2027-06-30',
        includeWorkSamples: false,
        customRegularFontBytes: fontRegular,
        customBoldFontBytes: fontBold,
      );
      expect(
        export2.requirementCaption,
        "Your own target. Check your state's rules.",
      );
      final pdf2 = await buildPortfolioPdf(export2);
      expect(pdf2, isNotEmpty);

      // 3. State Rule Child
      final c3Id = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Child Three',
          ruleId: 'mo_standard',
          schoolYearStart: '2026-08-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );
      final export3 = await exportService.prepareExportData(
        childId: c3Id,
        dateRangeStart: '2026-08-01',
        dateRangeEnd: '2027-06-30',
        includeWorkSamples: false,
        customRegularFontBytes: fontRegular,
        customBoldFontBytes: fontBold,
      );
      expect(export3.requirementCaption, isNull);
      final pdf3 = await buildPortfolioPdf(export3);
      expect(pdf3, isNotEmpty);
    });
  });
}
