import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/formatters.dart';
import '../../data/repositories/child_repository.dart';
import '../../data/repositories/log_repository.dart';
import '../../data/repositories/sample_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/subject_repository.dart';
import '../../data/rule_resolver.dart';
import '../../domain/core_subjects.dart';
import '../../domain/export_date_notice.dart';
import '../../domain/progress_calculator.dart';
import '../../domain/requirement_caption.dart';
import '../../domain/rule_resolution.dart';
import '../../services/sample_storage_service.dart';
import '../../services/temp_file_cleanup.dart';
import 'export_data_model.dart';
import 'pdf_portfolio_builder.dart';

/// Client abstraction for opening the system share sheet.
abstract class PdfShareClient {
  Future<void> sharePdf(String filePath, String subject);
}

class SharePlusPdfShareClient implements PdfShareClient {
  @override
  Future<void> sharePdf(String filePath, String subject) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/pdf')],
        subject: subject,
      ),
    );
  }
}

/// Sanitizes a file name for the generated portfolio PDF.
/// Replaces any unsafe or special characters with hyphens.
String sanitizePdfFileName({
  required String childName,
  required String startDate,
  required String endDate,
}) {
  final cleanName = childName
      .trim()
      .toLowerCase()
      .replaceAll("'", '')
      .replaceAll(RegExp(r"[^a-z0-9_-]+"), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  final cleanStart = startDate.replaceAll(RegExp(r'[^0-9-]'), '');
  final cleanEnd = endDate.replaceAll(RegExp(r'[^0-9-]'), '');
  final safeName = cleanName.isEmpty ? 'student' : cleanName;
  return 'homeledger-$safeName-$cleanStart-to-$cleanEnd.pdf';
}

/// Service that coordinates database reads, background isolate PDF creation,
/// and sharing via the system share sheet.
class ExportService {
  final ChildRepository childRepo;
  final RuleResolver ruleResolver;
  final SubjectRepository subjectRepo;
  final LogRepository logRepo;
  final SampleRepository sampleRepo;
  final SettingsRepository settingsRepo;
  final SampleStorageService sampleStorageService;
  final PdfShareClient shareClient;
  final DateTime Function() clock;
  final Future<Directory> Function() getTempDirectory;

  const ExportService({
    required this.childRepo,
    required this.ruleResolver,
    required this.subjectRepo,
    required this.logRepo,
    required this.sampleRepo,
    required this.settingsRepo,
    required this.sampleStorageService,
    required this.shareClient,
    required this.clock,
    this.getTempDirectory = getTemporaryDirectory,
  });

  /// Loads font byte data from application assets.
  Future<Uint8List> loadFontAsset(String path) async {
    final byteData = await rootBundle.load(path);
    return byteData.buffer.asUint8List();
  }

  /// Compiles all portfolio data from the database and repositories into
  /// a plain [PortfolioExportData] object ready to cross isolate boundaries.
  Future<PortfolioExportData> prepareExportData({
    required int childId,
    required String dateRangeStart,
    required String dateRangeEnd,
    required bool includeWorkSamples,
    Uint8List? customRegularFontBytes,
    Uint8List? customBoldFontBytes,
  }) async {
    final child = await childRepo.getById(childId);
    if (child == null) {
      throw ArgumentError('Child with ID $childId does not exist.');
    }

    final resolution = await ruleResolver.resolve(child.ruleId);
    final subjects = await subjectRepo.getAll();
    final subjectMap = {for (final s in subjects) s.id: s};

    // Aggregate numbers for the school year (matching Home progress totals)
    final totalMin = await logRepo.totalMinutes(
      childId,
      child.schoolYearStart,
      child.schoolYearEnd,
    );
    final minutesBySub = await logRepo.minutesBySubject(
      childId,
      child.schoolYearStart,
      child.schoolYearEnd,
    );
    final distinctDays = await logRepo.distinctDaysLogged(
      childId,
      child.schoolYearStart,
      child.schoolYearEnd,
    );

    final coreSubjectsList = coreSubjectsFor(subjects);
    final coreSubjectIds = {for (final s in coreSubjectsList) s.id};

    // Subject hours breakdown
    final subjectHours = <SubjectHoursSummary>[];
    for (final s in subjects) {
      final mins = minutesBySub[s.id] ?? 0;
      if (mins > 0) {
        subjectHours.add(
          SubjectHoursSummary(
            subjectName: s.name,
            isCore: coreSubjectIds.contains(s.id),
            totalMinutes: mins,
          ),
        );
      }
    }

    // Core minutes by subject name for progress evaluation (matches Home logic)
    final coreMinutesByName = <String, int>{};
    for (final entry in minutesBySub.entries) {
      final sub = subjectMap[entry.key];
      if (sub != null && coreSubjectIds.contains(sub.id)) {
        coreMinutesByName[sub.name] = entry.value;
      }
    }

    // Evaluate progress using pure ProgressCalculator (never recalculate inside PDF)
    final today = clock();
    DateTime startDt;
    DateTime endDt;
    try {
      startDt = DateTime.parse(child.schoolYearStart);
      endDt = DateTime.parse(child.schoolYearEnd);
    } catch (_) {
      startDt = today;
      endDt = today.add(const Duration(days: 180));
    }

    int? reqHours;
    int? reqDays;
    List<String> coreSubjects = [];
    String ruleLabel = child.ruleId;
    String? ruleSourceUrl;
    String? ruleLastChecked;

    if (resolution is RuleResolutionFound) {
      final profile = resolution.profile;
      reqHours = profile.requiredHours;
      reqDays = profile.requiredDays;
      coreSubjects = profile.coreSubjects;
      ruleLabel = profile.label;
      ruleSourceUrl = profile.sourceUrl;
      ruleLastChecked = profile.lastChecked;
    }

    final progressResult = ProgressCalculator.calculate(
      requiredMinutes: reqHours != null ? reqHours * 60 : null,
      requiredDays: reqDays,
      minutesDone: totalMin,
      daysLogged: distinctDays,
      coreMinutesBySubject: coreMinutesByName,
      coreSubjects: coreSubjects,
      schoolYearStart: startDt,
      schoolYearEnd: endDt,
      today: today,
    );

    final String statusLabel;
    switch (progressResult.status) {
      case ProgressStatus.onPace:
        statusLabel = 'On pace';
        break;
      case ProgressStatus.behind:
        statusLabel = 'Behind';
        break;
      case ProgressStatus.notStarted:
        statusLabel = 'Not started';
        break;
      case ProgressStatus.finished:
        statusLabel = 'Finished';
        break;
      case ProgressStatus.invalidDates:
        statusLabel = 'Behind';
        break;
    }

    // Raw log entries in date range
    final rawLogs = await logRepo.getForChildDateRange(childId, dateRangeStart, dateRangeEnd);
    final logSummaries = rawLogs.map((e) {
      final subName = subjectMap[e.subjectId]?.name ?? 'Subject #${e.subjectId}';
      return LogItemSummary(
        day: e.day,
        subjectName: subName,
        minutes: e.minutes,
        note: e.note,
      );
    }).toList();

    // Work samples in date range
    final sampleSummaries = <WorkSampleExportItem>[];
    if (includeWorkSamples) {
      final samples = await sampleRepo.listForChild(
        childId,
        SampleFilter(from: dateRangeStart, to: dateRangeEnd),
      );

      for (final s in samples) {
        final file = await sampleStorageService.resolveFile(s.filePath);
        final absPath = file.path;
        final exists = file.existsSync();
        final subName = s.subjectId != null ? subjectMap[s.subjectId]?.name : null;

        sampleSummaries.add(
          WorkSampleExportItem(
            title: s.title,
            subjectName: subName,
            day: s.day,
            absoluteFilePath: absPath,
            isMissing: !exists,
          ),
        );
      }
    }

    // Optional parent name from Settings
    final parentName = await settingsRepo.getParentName();

    // Check date range relative to school year
    final schoolYearNotice = computeDateRangeSchoolYearNotice(
      schoolYearStart: child.schoolYearStart,
      schoolYearEnd: child.schoolYearEnd,
      rangeStart: dateRangeStart,
      rangeEnd: dateRangeEnd,
    );

    // Honest requirement caption (disclosing placeholder vs custom vs state profile)
    final isCustom = (resolution is RuleResolutionFound)
        ? resolution.profile.isCustom
        : child.ruleId.startsWith('custom:');
    final requirementCaption = getRequirementCaption(
      ruleId: child.ruleId,
      isCustom: isCustom,
    );

    // Fonts
    final regularBytes = customRegularFontBytes ??
        await loadFontAsset('assets/fonts/NotoSans-Regular.ttf');
    final boldBytes = customBoldFontBytes ??
        await loadFontAsset('assets/fonts/NotoSans-Bold.ttf');

    return PortfolioExportData(
      childName: child.name,
      schoolYearStart: child.schoolYearStart,
      schoolYearEnd: child.schoolYearEnd,
      dateRangeStart: dateRangeStart,
      dateRangeEnd: dateRangeEnd,
      ruleLabel: ruleLabel,
      ruleSourceUrl: ruleSourceUrl,
      ruleLastChecked: ruleLastChecked,
      dateCreatedFormatted: formatDisplayDate(today),
      parentName: parentName,
      schoolYearNotice: schoolYearNotice,
      requirementCaption: requirementCaption,
      progress: PortfolioProgressData(
        requiredHours: reqHours,
        requiredDays: reqDays,
        minutesDone: totalMin,
        daysLogged: distinctDays,
        expectedMinutes: progressResult.expectedMinutes,
        expectedDays: progressResult.expectedDays,
        statusLabel: statusLabel,
        coreMinutesBySubject: coreMinutesByName,
        metricRows: progressResult.metricRows,
      ),
      subjectHours: subjectHours,
      totalMinutes: totalMin,
      logEntries: logSummaries,
      workSamples: sampleSummaries,
      includeWorkSamples: includeWorkSamples,
      fontRegularBytes: regularBytes,
      fontBoldBytes: boldBytes,
    );
  }

  /// Builds the PDF in a background isolate and returns raw PDF bytes.
  static Future<Uint8List> generatePdfBytes(PortfolioExportData data) {
    return Isolate.run(() => buildPortfolioPdf(data));
  }

  /// Generates the portfolio PDF, saves it to the temporary directory with
  /// sanitized file name, and opens the system share sheet.
  Future<File> exportAndSharePortfolio({
    required int childId,
    required String dateRangeStart,
    required String dateRangeEnd,
    required bool includeWorkSamples,
  }) async {
    final tempDir = await getTempDirectory();
    // Clean up old backup zips and portfolio PDFs older than 24h at the start of export
    await cleanupOldTempFiles(tempDir, now: clock());

    final exportData = await prepareExportData(
      childId: childId,
      dateRangeStart: dateRangeStart,
      dateRangeEnd: dateRangeEnd,
      includeWorkSamples: includeWorkSamples,
    );

    final pdfBytes = await generatePdfBytes(exportData);

    final fileName = sanitizePdfFileName(
      childName: exportData.childName,
      startDate: dateRangeStart,
      endDate: dateRangeEnd,
    );

    final filePath = p.join(tempDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes, flush: true);

    await shareClient.sharePdf(file.path, 'Homeschool Portfolio - ${exportData.childName}');
    return file;
  }
}
