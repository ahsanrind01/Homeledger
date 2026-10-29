import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/features/export/export_data_model.dart';
import 'package:homeledger/features/export/export_service.dart';
import 'package:homeledger/features/export/pdf_portfolio_builder.dart';
import 'package:image/image.dart' as img;

void main() {
  late Uint8List fontRegular;
  late Uint8List fontBold;
  late Directory tempDir;

  setUpAll(() {
    fontRegular = File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync();
    fontBold = File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync();
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('homeledger_pdf_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  PortfolioExportData createBaseData({
    String childName = 'Jane Doe',
    String? parentName,
    List<SubjectHoursSummary> subjectHours = const [],
    int totalMinutes = 0,
    PortfolioProgressData? progress,
    List<LogItemSummary> logEntries = const [],
    List<WorkSampleExportItem> workSamples = const [],
    bool includeWorkSamples = true,
  }) {
    return PortfolioExportData(
      childName: childName,
      parentName: parentName,
      ruleLabel: 'Standard 900 Hours',
      ruleSourceUrl: 'https://doe.example.gov/rules',
      ruleLastChecked: '2026-09-01',
      schoolYearStart: '2026-08-01',
      schoolYearEnd: '2027-06-30',
      dateRangeStart: '2026-08-01',
      dateRangeEnd: '2027-06-30',
      dateCreatedFormatted: 'October 20, 2026',
      totalMinutes: totalMinutes,
      subjectHours: subjectHours,
      progress: progress ??
          const PortfolioProgressData(
            requiredHours: 900,
            requiredDays: null,
            minutesDone: 0,
            daysLogged: 0,
            expectedMinutes: 0,
            expectedDays: null,
            statusLabel: 'Not started',
            coreMinutesBySubject: {},
          ),
      logEntries: logEntries,
      workSamples: workSamples,
      includeWorkSamples: includeWorkSamples,
      fontRegularBytes: fontRegular,
      fontBoldBytes: fontBold,
    );
  }

  test('Footer text constant is exact legal disclaimer requirement', () {
    expect(
      kPdfFooterText,
      'Created with Homeledger. Records tool, not legal advice. Based only on entries made by the parent.',
    );
  });

  test('PDF generates for an empty child with no entries or samples', () async {
    final data = createBaseData(
      childName: 'Zoë Noël',
      parentName: 'Renée Noël',
      logEntries: const [],
      subjectHours: const [],
      totalMinutes: 0,
      workSamples: const [],
    );

    final pdfBytes = await buildPortfolioPdf(data);
    expect(pdfBytes, isNotEmpty);
    // Standard PDF header check (%PDF-)
    expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
  });

  test('Accented names render cleanly with bundled Noto Sans', () async {
    final data = createBaseData(
      childName: 'Zoë García-Müller',
      parentName: 'José María Müller',
    );

    final pdfBytes = await buildPortfolioPdf(data);
    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
  });

  test('PDF generates for a child with entries, subject summary, and progress', () async {
    final data = createBaseData(
      childName: 'Alex Smith',
      parentName: 'Morgan Smith',
      totalMinutes: 300,
      subjectHours: const [
        SubjectHoursSummary(
          subjectName: 'Math',
          isCore: true,
          totalMinutes: 180,
        ),
        SubjectHoursSummary(
          subjectName: 'Art',
          isCore: false,
          totalMinutes: 120,
        ),
      ],
      progress: const PortfolioProgressData(
        requiredHours: 900,
        requiredDays: null,
        minutesDone: 300,
        daysLogged: 2,
        expectedMinutes: 200,
        expectedDays: null,
        statusLabel: 'On pace',
        coreMinutesBySubject: {'Math': 180},
      ),
      logEntries: const [
        LogItemSummary(
          day: '2026-09-01',
          subjectName: 'Math',
          minutes: 120,
          note: 'Fractions and decimals',
        ),
        LogItemSummary(
          day: '2026-09-02',
          subjectName: 'Math',
          minutes: 60,
          note: null,
        ),
        LogItemSummary(
          day: '2026-09-02',
          subjectName: 'Art',
          minutes: 120,
          note: 'Watercolor painting',
        ),
      ],
    );

    final pdfBytes = await buildPortfolioPdf(data);
    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
  });

  test('PDF generates for child with valid samples and handles missing image files safely', () async {
    // Create a real small JPEG image file
    final realImageFile = File('${tempDir.path}/sample_real.jpg');
    final rawImage = img.Image(width: 100, height: 100);
    img.fill(rawImage, color: img.ColorRgb8(50, 100, 150));
    final jpgBytes = img.encodeJpg(rawImage);
    realImageFile.writeAsBytesSync(jpgBytes);

    final missingImagePath = '${tempDir.path}/missing_sample.jpg';

    final data = createBaseData(
      childName: 'Jane Sample',
      workSamples: [
        WorkSampleExportItem(
          title: 'Math Worksheet',
          subjectName: 'Math',
          day: '2026-09-15',
          absoluteFilePath: realImageFile.path,
          isMissing: false,
        ),
        WorkSampleExportItem(
          title: 'Science Project Poster',
          subjectName: 'Science',
          day: '2026-09-18',
          absoluteFilePath: missingImagePath,
          isMissing: true,
        ),
      ],
    );

    final pdfBytes = await buildPortfolioPdf(data);
    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
  });

  test('Memory safety: builds PDF with 50 work samples in background isolate without OOM', () async {
    // Generate 50 sample images
    final sampleItems = <WorkSampleExportItem>[];
    final rawImage = img.Image(width: 80, height: 80);
    img.fill(rawImage, color: img.ColorRgb8(100, 150, 200));
    final jpgBytes = img.encodeJpg(rawImage);

    for (int i = 1; i <= 50; i++) {
      final file = File('${tempDir.path}/sample_$i.jpg');
      file.writeAsBytesSync(jpgBytes);
      sampleItems.add(
        WorkSampleExportItem(
          title: 'Sample $i Title',
          subjectName: i % 2 == 0 ? 'Math' : 'Science',
          day: '2026-09-${(i % 28 + 1).toString().padLeft(2, '0')}',
          absoluteFilePath: file.path,
          isMissing: false,
        ),
      );
    }

    final data = createBaseData(
      childName: 'Fifty Samples Child',
      workSamples: sampleItems,
    );

    // Run generation through background isolate via ExportService
    final pdfBytes = await ExportService.generatePdfBytes(data);
    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.length, greaterThan(10000));
    expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
  });

  test('Handles large log sets (1,000 entries) across multiple pages without failure', () async {
    final entries = List<LogItemSummary>.generate(
      1000,
      (i) => LogItemSummary(
        day: '2026-09-${(i % 28 + 1).toString().padLeft(2, '0')}',
        subjectName: 'Subject ${i % 5}',
        minutes: 30 + (i % 60),
        note: 'Daily practice and exercises for lesson #$i',
      ),
    );

    final data = createBaseData(
      childName: 'Large Logs Child',
      logEntries: entries,
    );

    final pdfBytes = await ExportService.generatePdfBytes(data);
    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
  });
}
