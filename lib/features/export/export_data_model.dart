import 'dart:typed_data';

import '../../domain/progress_calculator.dart';

/// Immutable data structures that feed the PDF generation engine.
/// All fields are plain Dart primitives so this object can be safely passed
/// across isolate boundaries to `buildPortfolioPdf`.

class SubjectHoursSummary {
  final String subjectName;
  final bool isCore;
  final int totalMinutes;

  const SubjectHoursSummary({
    required this.subjectName,
    required this.isCore,
    required this.totalMinutes,
  });
}

class LogItemSummary {
  final String day; // YYYY-MM-DD
  final String subjectName;
  final int minutes;
  final String? note;

  const LogItemSummary({
    required this.day,
    required this.subjectName,
    required this.minutes,
    this.note,
  });
}

class WorkSampleExportItem {
  final String? title;
  final String? subjectName;
  final String day;
  final String? absoluteFilePath;
  final bool isMissing;

  const WorkSampleExportItem({
    this.title,
    this.subjectName,
    required this.day,
    this.absoluteFilePath,
    required this.isMissing,
  });
}

class PortfolioProgressData {
  final int? requiredHours;
  final int? requiredDays;
  final int minutesDone;
  final int daysLogged;
  final int? expectedMinutes;
  final int? expectedDays;
  final String statusLabel; // 'On pace', 'Behind', 'Not started', or 'Finished'
  final Map<String, int> coreMinutesBySubject;
  final List<ProgressMetricRow> metricRows;

  const PortfolioProgressData({
    this.requiredHours,
    this.requiredDays,
    required this.minutesDone,
    required this.daysLogged,
    this.expectedMinutes,
    this.expectedDays,
    required this.statusLabel,
    required this.coreMinutesBySubject,
    this.metricRows = const [],
  });
}

class PortfolioExportData {
  final String childName;
  final String schoolYearStart;
  final String schoolYearEnd;
  final String dateRangeStart;
  final String dateRangeEnd;
  final String ruleLabel;
  final String? ruleSourceUrl;
  final String? ruleLastChecked;
  final String dateCreatedFormatted;
  final String? parentName;
  final String? schoolYearNotice;
  final String? requirementCaption;

  final PortfolioProgressData progress;
  final List<SubjectHoursSummary> subjectHours;
  final int totalMinutes;
  final List<LogItemSummary> logEntries;
  final List<WorkSampleExportItem> workSamples;
  final bool includeWorkSamples;

  final Uint8List fontRegularBytes;
  final Uint8List fontBoldBytes;

  const PortfolioExportData({
    required this.childName,
    required this.schoolYearStart,
    required this.schoolYearEnd,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.ruleLabel,
    this.ruleSourceUrl,
    this.ruleLastChecked,
    required this.dateCreatedFormatted,
    this.parentName,
    this.schoolYearNotice,
    this.requirementCaption,
    required this.progress,
    required this.subjectHours,
    required this.totalMinutes,
    required this.logEntries,
    required this.workSamples,
    required this.includeWorkSamples,
    required this.fontRegularBytes,
    required this.fontBoldBytes,
  });
}
