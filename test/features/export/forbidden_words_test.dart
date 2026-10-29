import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/core/constants.dart';
import 'package:homeledger/features/export/export_data_model.dart';
import 'package:homeledger/features/export/pdf_portfolio_builder.dart';

void main() {
  group('Forbidden Claim Words in Export & PDF', () {
    test('kForbiddenClaimWords contains required claim words', () {
      expect(
        kForbiddenClaimWords,
        containsAll([
          'official',
          'verified',
          'verify',
          'approved',
          'compliant',
          'compliance',
          'guaranteed',
          'certified',
          'accredited',
        ]),
      );
    });

    test('lib/features/export/ contains zero forbidden regulatory claim words', () {
      final exportDir = Directory('lib/features/export');
      expect(exportDir.existsSync(), isTrue, reason: 'lib/features/export directory must exist');

      final dartFiles = exportDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trim();
          if (trimmed.startsWith('//') || trimmed.startsWith('///') || trimmed.startsWith('*')) {
            continue;
          }
          final lower = line.toLowerCase();
          for (final word in kForbiddenClaimWords) {
            if (lower.contains(word)) {
              violations.add('${file.path}:${i + 1} contains "$word": $line');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Forbidden words must never appear in export code or strings:\n${violations.join("\n")}',
      );
    });

    test('PDF builder text strings contain none of the forbidden claim words', () async {
      final sampleData = PortfolioExportData(
        childName: 'Emma Watson',
        parentName: 'Sarah Watson',
        ruleLabel: 'Standard Requirements Profile',
        ruleSourceUrl: 'https://doe.example.gov/rules',
        ruleLastChecked: '2026-09-01',
        schoolYearStart: '2026-09-01',
        schoolYearEnd: '2027-06-30',
        dateRangeStart: '2026-09-01',
        dateRangeEnd: '2027-06-30',
        dateCreatedFormatted: 'October 21, 2026',
        totalMinutes: 600,
        subjectHours: const [
          SubjectHoursSummary(
            subjectName: 'Math',
            isCore: true,
            totalMinutes: 300,
          ),
          SubjectHoursSummary(
            subjectName: 'Art',
            isCore: false,
            totalMinutes: 300,
          ),
        ],
        progress: const PortfolioProgressData(
          requiredHours: 100,
          requiredDays: 100,
          minutesDone: 600,
          daysLogged: 10,
          expectedMinutes: 500,
          expectedDays: 8,
          statusLabel: 'On pace',
          coreMinutesBySubject: {'Math': 300},
        ),
        logEntries: const [
          LogItemSummary(
            day: '2026-09-05',
            subjectName: 'Math',
            minutes: 60,
            note: 'Geometry lesson',
          ),
        ],
        workSamples: const [
          WorkSampleExportItem(
            day: '2026-09-10',
            title: 'Fractions worksheet',
            subjectName: 'Math',
            isMissing: false,
            absoluteFilePath: null,
          ),
        ],
        includeWorkSamples: true,
        fontRegularBytes: Uint8List(0),
        fontBoldBytes: Uint8List(0),
      );

      final extractedStrings = extractPortfolioPdfStrings(sampleData);
      expect(extractedStrings, isNotEmpty);

      final violations = <String>[];
      for (final str in extractedStrings) {
        final lower = str.toLowerCase();
        for (final word in kForbiddenClaimWords) {
          if (lower.contains(word)) {
            violations.add('String "$str" contains forbidden word "$word"');
          }
        }
      }

      expect(violations, isEmpty, reason: 'PDF strings contained forbidden words: $violations');

      // Check title replacement
      expect(extractedStrings, contains('Homeschool Record'));
      expect(extractedStrings, contains('Prepared by parent using Homeledger'));
      expect(extractedStrings, isNot(contains('Official Record')));

      // Check existing disclaimer text unchanged
      expect(
        kPdfFooterText,
        'Created with Homeledger. Records tool, not legal advice. Based only on entries made by the parent.',
      );
      expect(extractedStrings, contains(kPdfFooterText));
    });
  });
}
