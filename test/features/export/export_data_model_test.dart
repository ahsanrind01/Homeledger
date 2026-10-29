import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/repositories/child_repository.dart';
import 'package:homeledger/data/repositories/custom_rule_repository.dart';
import 'package:homeledger/data/repositories/log_repository.dart';
import 'package:homeledger/data/repositories/sample_repository.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';
import 'package:homeledger/data/repositories/subject_repository.dart';
import 'package:homeledger/data/rule_resolver.dart';
import 'package:homeledger/domain/rule_profile.dart';
import 'package:homeledger/features/export/export_service.dart';
import 'package:homeledger/services/sample_storage_service.dart';

class FakePdfShareClient implements PdfShareClient {
  String? lastSharedFilePath;
  String? lastSubject;

  @override
  Future<void> sharePdf(String filePath, String subject) async {
    lastSharedFilePath = filePath;
    lastSubject = subject;
  }
}

void main() {
  late AppDatabase db;
  late ChildRepository childRepo;
  late SubjectRepository subjectRepo;
  late LogRepository logRepo;
  late SampleRepository sampleRepo;
  late SettingsRepository settingsRepo;
  late CustomRuleRepository customRuleRepo;
  late RuleResolver ruleResolver;
  late SampleStorageService sampleStorageService;
  late FakePdfShareClient shareClient;
  late ExportService exportService;

  late Directory tempDir;
  final fixedClock = DateTime(2027, 1, 15);

  final testFontBytes = Uint8List.fromList(List.filled(100, 0));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    childRepo = ChildRepository(db);
    subjectRepo = SubjectRepository(db);
    logRepo = LogRepository(db);
    sampleRepo = SampleRepository(db);
    settingsRepo = SettingsRepository(db);
    customRuleRepo = CustomRuleRepository(db);
    shareClient = FakePdfShareClient();

    tempDir = Directory.systemTemp.createTempSync('export_test_');

    sampleStorageService = SampleStorageService(
      sampleRepository: sampleRepo,
      getDocumentsDirectory: () async => tempDir,
      imageProcessor: (bytes) async => bytes,
    );

    final standardProfiles = [
      const RuleProfile(
        id: 'placeholder_example',
        label: 'Placeholder Example Rule',
        requiredHours: 100,
        requiredDays: 100,
        coreSubjects: ['Math', 'Reading'],
        sourceUrl: 'https://example.com/rules',
        lastChecked: '2026-10-01',
      ),
    ];

    ruleResolver = RuleResolver(
      customRuleRepository: customRuleRepo,
      assetProfiles: standardProfiles,
    );

    exportService = ExportService(
      childRepo: childRepo,
      ruleResolver: ruleResolver,
      subjectRepo: subjectRepo,
      logRepo: logRepo,
      sampleRepo: sampleRepo,
      settingsRepo: settingsRepo,
      sampleStorageService: sampleStorageService,
      shareClient: shareClient,
      clock: () => fixedClock,
    );

    await subjectRepo.seedDefaultSubjects();
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ExportService prepareExportData', () {
    test('Date range filter includes both boundary days (from and to)', () async {
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Emma',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1000,
        ),
      );

      final math = (await subjectRepo.getAll()).firstWhere((s) => s.name == 'Math');

      // Entry exactly on start boundary (2026-10-01)
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: math.id,
          day: '2026-10-01',
          minutes: 60,
          createdAt: 1001,
        ),
      );

      // Entry inside range (2026-10-15)
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: math.id,
          day: '2026-10-15',
          minutes: 90,
          createdAt: 1002,
        ),
      );

      // Entry exactly on end boundary (2026-10-31)
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: math.id,
          day: '2026-10-31',
          minutes: 30,
          createdAt: 1003,
        ),
      );

      // Entry outside range before (2026-09-30)
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: math.id,
          day: '2026-09-30',
          minutes: 45,
          createdAt: 1004,
        ),
      );

      // Entry outside range after (2026-11-01)
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: math.id,
          day: '2026-11-01',
          minutes: 45,
          createdAt: 1005,
        ),
      );

      final data = await exportService.prepareExportData(
        childId: childId,
        dateRangeStart: '2026-10-01',
        dateRangeEnd: '2026-10-31',
        includeWorkSamples: false,
        customRegularFontBytes: testFontBytes,
        customBoldFontBytes: testFontBytes,
      );

      // Fix B Task 1: School year totals reflect the entire school year:
      // 45 + 60 + 90 + 30 + 45 = 270 min (matching Home progress card)
      expect(data.totalMinutes, 270);
      expect(data.progress.minutesDone, 270);

      // Selected date range only filters the time log table:
      expect(data.logEntries.length, 3);
      final rangeTotalMinutes =
          data.logEntries.fold<int>(0, (sum, e) => sum + e.minutes);
      expect(rangeTotalMinutes, 180);
      expect(data.logEntries[0].day, '2026-10-01');
      expect(data.logEntries[0].minutes, 60);
      expect(data.logEntries[1].day, '2026-10-15');
      expect(data.logEntries[1].minutes, 90);
      expect(data.logEntries[2].day, '2026-10-31');
      expect(data.logEntries[2].minutes, 30);
    });

    test('Custom export date range does not shrink progress numbers from school-year totals', () async {
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Sophia',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 1050,
        ),
      );

      final math = (await subjectRepo.getAll()).firstWhere((s) => s.name == 'Math');

      // Log 120 minutes across September and October
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: math.id,
          day: '2026-09-10',
          minutes: 120,
          createdAt: 1051,
        ),
      );
      await logRepo.add(
        LogEntriesCompanion.insert(
          childId: childId,
          subjectId: math.id,
          day: '2026-10-10',
          minutes: 60,
          createdAt: 1052,
        ),
      );

      // Parent exports only October (2026-10-01 to 2026-10-31)
      final data = await exportService.prepareExportData(
        childId: childId,
        dateRangeStart: '2026-10-01',
        dateRangeEnd: '2026-10-31',
        includeWorkSamples: false,
        customRegularFontBytes: testFontBytes,
        customBoldFontBytes: testFontBytes,
      );

      // Progress figures must NOT shrink to October
      expect(data.progress.minutesDone, 180);
      expect(data.totalMinutes, 180);
      expect(data.progress.daysLogged, 2);

      // Time log table only has October
      expect(data.logEntries.length, 1);
      expect(data.logEntries.first.day, '2026-10-10');
      expect(data.logEntries.first.minutes, 60);
    });

    test('Empty child produces empty tables with 0 minutes', () async {
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Lucas',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 2000,
        ),
      );

      final data = await exportService.prepareExportData(
        childId: childId,
        dateRangeStart: '2026-09-01',
        dateRangeEnd: '2027-06-30',
        includeWorkSamples: true,
        customRegularFontBytes: testFontBytes,
        customBoldFontBytes: testFontBytes,
      );

      expect(data.childName, 'Lucas');
      expect(data.totalMinutes, 0);
      expect(data.subjectHours, isEmpty);
      expect(data.logEntries, isEmpty);
      expect(data.workSamples, isEmpty);
      expect(data.progress.minutesDone, 0);
      expect(data.progress.daysLogged, 0);
      expect(data.progress.statusLabel, isNotEmpty);
    });

    test('Optional parent name is included when set and null when not set', () async {
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Maya',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 3000,
        ),
      );

      // Initially null
      var data = await exportService.prepareExportData(
        childId: childId,
        dateRangeStart: '2026-09-01',
        dateRangeEnd: '2027-06-30',
        includeWorkSamples: false,
        customRegularFontBytes: testFontBytes,
        customBoldFontBytes: testFontBytes,
      );
      expect(data.parentName, isNull);

      // After setting parent name
      await settingsRepo.setParentName('Eleanor Vance');
      data = await exportService.prepareExportData(
        childId: childId,
        dateRangeStart: '2026-09-01',
        dateRangeEnd: '2027-06-30',
        includeWorkSamples: false,
        customRegularFontBytes: testFontBytes,
        customBoldFontBytes: testFontBytes,
      );
      expect(data.parentName, 'Eleanor Vance');
    });

    test('Work sample is correctly detected as present or missing', () async {
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Noah',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 4000,
        ),
      );

      // 1. Existing sample file
      final childSampleDir = Directory('${tempDir.path}/samples/$childId');
      childSampleDir.createSync(recursive: true);
      final realFile = File('${childSampleDir.path}/sample1.jpg');
      realFile.writeAsBytesSync([1, 2, 3]);

      await sampleRepo.add(
        WorkSamplesCompanion.insert(
          childId: childId,
          day: '2026-10-10',
          title: driftValue('Fractions Worksheet'),
          filePath: 'samples/$childId/sample1.jpg',
          createdAt: 4001,
        ),
      );

      // 2. Missing sample file (row points to non-existent file)
      await sampleRepo.add(
        WorkSamplesCompanion.insert(
          childId: childId,
          day: '2026-10-12',
          title: driftValue('Science Diagram'),
          filePath: 'samples/$childId/missing_diagram.jpg',
          createdAt: 4002,
        ),
      );

      final data = await exportService.prepareExportData(
        childId: childId,
        dateRangeStart: '2026-09-01',
        dateRangeEnd: '2027-06-30',
        includeWorkSamples: true,
        customRegularFontBytes: testFontBytes,
        customBoldFontBytes: testFontBytes,
      );

      expect(data.workSamples.length, 2);
      final presentSample = data.workSamples.firstWhere((s) => s.title == 'Fractions Worksheet');
      expect(presentSample.isMissing, isFalse);
      expect(presentSample.absoluteFilePath, realFile.path);

      final missingSample = data.workSamples.firstWhere((s) => s.title == 'Science Diagram');
      expect(missingSample.isMissing, isTrue);
    });

    test('Attaches schoolYearNotice when date range is partly outside school year', () async {
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Oliver',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 5000,
        ),
      );

      // Partly outside: range begins in August
      final data = await exportService.prepareExportData(
        childId: childId,
        dateRangeStart: '2026-08-01',
        dateRangeEnd: '2026-10-31',
        includeWorkSamples: false,
        customRegularFontBytes: testFontBytes,
        customBoldFontBytes: testFontBytes,
      );

      expect(
        data.schoolYearNotice,
        'Part of this range is outside the school year (2026-09-01 to 2027-06-30). Progress is shown for the school year.',
      );
    });

    test('Attaches schoolYearNotice when date range has no overlap with school year', () async {
      final childId = await childRepo.add(
        ChildrenCompanion.insert(
          name: 'Oliver',
          ruleId: 'placeholder_example',
          schoolYearStart: '2026-09-01',
          schoolYearEnd: '2027-06-30',
          createdAt: 5001,
        ),
      );

      // Fully outside: Summer break (July 2027)
      final data = await exportService.prepareExportData(
        childId: childId,
        dateRangeStart: '2027-07-01',
        dateRangeEnd: '2027-07-31',
        includeWorkSamples: false,
        customRegularFontBytes: testFontBytes,
        customBoldFontBytes: testFontBytes,
      );

      expect(
        data.schoolYearNotice,
        'This range is outside the school year. The time log is empty for this range.',
      );
    });
  });
}

Value<T> driftValue<T>(T val) => Value<T>(val);
