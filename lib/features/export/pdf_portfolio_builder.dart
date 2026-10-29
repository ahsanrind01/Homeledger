import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/core_subjects.dart';
import '../../domain/progress_calculator.dart';
import 'export_data_model.dart';

const String kPdfFooterText =
    'Created with Homeledger. Records tool, not legal advice. Based only on entries made by the parent.';

/// Pure PDF generator. Designed to run in a background isolate via `Isolate.run`.
/// Does not access SQLite or Flutter UI widgets directly.
Future<Uint8List> buildPortfolioPdf(PortfolioExportData data) async {
  final fontRegular = pw.Font.ttf(data.fontRegularBytes.buffer.asByteData());
  final fontBold = pw.Font.ttf(data.fontBoldBytes.buffer.asByteData());

  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    ),
  );

  pw.Widget buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              kPdfFooterText,
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  String formatMinutes(int minutes) {
    if (minutes <= 0) return '0 min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '$h h $m min';
    if (h > 0) return '$h h';
    return '$m min';
  }

  // ==========================================
  // PAGE 1: COVER PAGE
  // ==========================================
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      footer: buildFooter,
      build: (context) {
        return [
          pw.SizedBox(height: 30),
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.blueGrey800, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Homeschool Portfolio',
                  style: const pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Homeschool Record',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Prepared by parent using Homeledger',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 36),

          // Student Information Block
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Student',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  data.childName,
                  style: const pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                if (data.parentName != null && data.parentName!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Parent / Educator',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    data.parentName!,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Portfolio Details Table
          pw.Table(
            columnWidths: const {
              0: pw.FixedColumnWidth(140),
              1: pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      'School Year:',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      '${data.schoolYearStart} to ${data.schoolYearEnd}',
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      'Reporting Period:',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      '${data.dateRangeStart} to ${data.dateRangeEnd}',
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      'Requirement Goal:',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(data.ruleLabel),
                  ),
                ],
              ),
              if (data.ruleSourceUrl != null && data.ruleSourceUrl!.isNotEmpty)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text(
                        'Source Reference:',
                        style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text(
                        data.ruleLastChecked != null
                            ? '${data.ruleSourceUrl} (Last checked: ${data.ruleLastChecked})'
                            : data.ruleSourceUrl!,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      'Date Generated:',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(data.dateCreatedFormatted),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 50),

          // Cover Page Disclaimer Note
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'Notice: This portfolio compiles learning time and work samples recorded by the parent. '
              'It is a records tool, not legal advice.',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
            ),
          ),
        ];
      },
    ),
  );

  // ==========================================
  // SECTION 2: PROGRESS SUMMARY & SUBJECT HOURS
  // ==========================================
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      footer: buildFooter,
      build: (context) {
        return [
          pw.Text(
            'Progress for school year ${data.schoolYearStart} to ${data.schoolYearEnd}',
            style: const pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          if (data.schoolYearNotice != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              data.schoolYearNotice!,
              style: const pw.TextStyle(
                fontSize: 9.5,
                color: PdfColors.blueGrey800,
              ),
            ),
          ],
          pw.SizedBox(height: 12),

          // Progress status rows: each required metric on its own row with its own status chip
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              children: [
                if (data.progress.metricRows.isEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Text(
                      'No requirement metrics specified',
                      style: const pw.TextStyle(color: PdfColors.grey600),
                    ),
                  )
                else
                  for (int i = 0; i < data.progress.metricRows.length; i++) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: pw.BoxDecoration(
                        border: i < data.progress.metricRows.length - 1
                            ? const pw.Border(
                                bottom: pw.BorderSide(color: PdfColors.grey200),
                              )
                            : null,
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            data.progress.metricRows[i].label,
                            style: const pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey900,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: switch (data.progress.metricRows[i].status) {
                                ProgressStatus.onPace => PdfColors.green50,
                                ProgressStatus.finished => PdfColors.teal50,
                                ProgressStatus.behind => PdfColors.amber50,
                                ProgressStatus.notStarted => PdfColors.grey100,
                                ProgressStatus.invalidDates => PdfColors.red50,
                              },
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                              border: pw.Border.all(
                                color: switch (data.progress.metricRows[i].status) {
                                  ProgressStatus.onPace => PdfColors.green800,
                                  ProgressStatus.finished => PdfColors.teal800,
                                  ProgressStatus.behind => PdfColors.orange900,
                                  ProgressStatus.notStarted => PdfColors.grey700,
                                  ProgressStatus.invalidDates => PdfColors.red800,
                                },
                              ),
                            ),
                            child: pw.Text(
                              data.progress.metricRows[i].status.label,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: switch (data.progress.metricRows[i].status) {
                                  ProgressStatus.onPace => PdfColors.green800,
                                  ProgressStatus.finished => PdfColors.teal800,
                                  ProgressStatus.behind => PdfColors.orange900,
                                  ProgressStatus.notStarted => PdfColors.grey700,
                                  ProgressStatus.invalidDates => PdfColors.red800,
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
          ),
          if (data.requirementCaption != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              data.requirementCaption!,
              style: const pw.TextStyle(
                fontSize: 9.5,
                color: PdfColors.blueGrey800,
              ),
            ),
          ],

          pw.SizedBox(height: 24),

          // Hours by Subject Table
          pw.Text(
            'Hours by Subject',
            style: const pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 8),

          if (data.subjectHours.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text('No entries yet', style: const pw.TextStyle(color: PdfColors.grey700)),
            )
          else ...[
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Subject', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Core Subject', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Time Logged', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...data.subjectHours.map((sub) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(sub.subjectName),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(formatCoreStatus(sub.isCore)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(formatMinutes(sub.totalMinutes)),
                      ),
                    ],
                  );
                }),
                // Total row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('-'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        formatMinutes(data.totalMinutes),
                        style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ];
      },
    ),
  );

  // ==========================================
  // SECTION 3: DAILY LEARNING LOG
  // ==========================================
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      footer: buildFooter,
      maxPages: 1000,
      header: (context) {
        if (context.pageNumber > 2) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 6),
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Time log for ${data.dateRangeStart} to ${data.dateRangeEnd} - ${data.childName}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                pw.Text(
                  '${data.dateRangeStart} to ${data.dateRangeEnd}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        }
        return pw.SizedBox();
      },
      build: (context) {
        return [
          pw.Text(
            'Time log for ${data.dateRangeStart} to ${data.dateRangeEnd}',
            style: const pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Chronological list of parent-recorded educational activities',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),

          if (data.logEntries.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Text('No entries yet', style: const pw.TextStyle(color: PdfColors.grey700)),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              columnWidths: const {
                0: pw.FixedColumnWidth(65),
                1: pw.FixedColumnWidth(95),
                2: pw.FixedColumnWidth(60),
                3: pw.FlexColumnWidth(),
              },
              headers: const ['Date', 'Subject', 'Time', 'Notes'],
              data: data.logEntries.map((e) {
                return [
                  e.day,
                  e.subjectName,
                  formatMinutes(e.minutes),
                  e.note ?? '',
                ];
              }).toList(),
            ),
        ];
      },
    ),
  );

  // ==========================================
  // SECTION 4: WORK SAMPLES SECTION
  // ==========================================
  if (data.includeWorkSamples) {
    if (data.workSamples.isEmpty) {
      // Empty work samples notice
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          footer: buildFooter,
          build: (context) {
            return [
              pw.Text(
                'Work Samples',
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'No work samples recorded for this reporting period.',
                style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
              ),
            ];
          },
        ),
      );
    } else {
      // Render each sample on its own page
      for (final sample in data.workSamples) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.all(40),
            footer: buildFooter,
            build: (context) {
              pw.Widget imageWidget;
              if (sample.isMissing || sample.absoluteFilePath == null) {
                imageWidget = pw.Container(
                  height: 380,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 1),
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    '[Work sample file missing from device: ${sample.title ?? "sample"}]',
                    style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                  ),
                );
              } else {
                try {
                  final file = File(sample.absoluteFilePath!);
                  if (file.existsSync()) {
                    // Read file bytes one at a time for memory safety
                    final bytes = file.readAsBytesSync();
                    final memImage = pw.MemoryImage(bytes);
                    imageWidget = pw.Container(
                      height: 480,
                      alignment: pw.Alignment.center,
                      child: pw.Image(
                        memImage,
                        fit: pw.BoxFit.contain,
                      ),
                    );
                  } else {
                    imageWidget = pw.Container(
                      height: 380,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 1),
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        '[Work sample file missing from device]',
                        style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                      ),
                    );
                  }
                } catch (_) {
                  imageWidget = pw.Container(
                    height: 380,
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '[Work sample file could not be read]',
                      style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                    ),
                  );
                }
              }

              return [
                pw.Text(
                  'Work Sample',
                  style: const pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          sample.title != null && sample.title!.trim().isNotEmpty
                              ? sample.title!
                              : '(Untitled sample)',
                          style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      pw.Text(
                        '${sample.subjectName ?? "General"} | ${sample.day}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Center(child: imageWidget),
                pw.SizedBox(height: 8),
              ];
            },
          ),
        );
      }
    }
  }

  return pdf.save();
}

/// Extracts all text strings passed to PDF widgets during document generation.
/// Used for automated audits to verify 0 forbidden claim words appear in the output.
List<String> extractPortfolioPdfStrings(PortfolioExportData data) {
  final strings = <String>[
    kPdfFooterText,
    'Homeschool Portfolio',
    'Homeschool Record',
    'Prepared by parent using Homeledger',
    'Student',
    data.childName,
    if (data.parentName != null && data.parentName!.trim().isNotEmpty) ...[
      'Parent / Educator',
      data.parentName!,
    ],
    'School Year:',
    '${data.schoolYearStart} to ${data.schoolYearEnd}',
    'Reporting Period:',
    '${data.dateRangeStart} to ${data.dateRangeEnd}',
    'Requirement Goal:',
    data.ruleLabel,
    if (data.ruleSourceUrl != null && data.ruleSourceUrl!.isNotEmpty) ...[
      'Source Reference:',
      data.ruleLastChecked != null
          ? '${data.ruleSourceUrl} (Last checked: ${data.ruleLastChecked})'
          : data.ruleSourceUrl!,
    ],
    'Date Generated:',
    data.dateCreatedFormatted,
    'Notice: This portfolio compiles learning time and work samples recorded by the parent. '
        'It is a records tool, not legal advice.',
    'Progress for school year ${data.schoolYearStart} to ${data.schoolYearEnd}',
    if (data.schoolYearNotice != null) data.schoolYearNotice!,
    for (final row in data.progress.metricRows) ...[
      row.label,
      row.status.label,
    ],
    'Hours by Subject',
    if (data.subjectHours.isEmpty)
      'No entries yet'
    else ...[
      'Subject',
      'Core Subject',
      'Time Logged',
      for (final sub in data.subjectHours) ...[
        sub.subjectName,
        formatCoreStatus(sub.isCore),
      ],
      'Total',
    ],
    'Time log for ${data.dateRangeStart} to ${data.dateRangeEnd}',
    'Chronological list of parent-recorded educational activities',
    if (data.logEntries.isEmpty)
      'No entries yet'
    else ...[
      'Date',
      'Subject',
      'Time',
      'Notes',
      for (final e in data.logEntries) ...[
        e.day,
        e.subjectName,
        if (e.note != null && e.note!.isNotEmpty) e.note!,
      ],
    ],
    if (data.includeWorkSamples) ...[
      'Work Samples',
      if (data.workSamples.isEmpty)
        'No work samples recorded for this reporting period.'
      else
        for (final sample in data.workSamples) ...[
          'Work Sample',
          sample.title ?? '(Untitled sample)',
          '${sample.subjectName ?? "General"} | ${sample.day}',
        ],
    ],
  ];
  return strings;
}
