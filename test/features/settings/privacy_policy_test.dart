import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/app/privacy_policy_text.dart';
import 'package:homeledger/core/constants.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/features/settings/privacy_policy_screen.dart';
import 'package:homeledger/features/settings/settings_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Privacy Policy Tests', () {
    test('Privacy policy sections contain all legally required offline disclosures', () {
      expect(kPrivacyContactEmail, 'REPLACE_BEFORE_RELEASE');
      expect(kPrivacyPolicyLastUpdated, isNotEmpty);
      expect(kPrivacyPolicySections, isNotEmpty);

      final fullText = kPrivacyPolicySections
          .map((s) => '${s.heading}\n${s.body}')
          .join('\n\n');

      // Check required facts
      expect(fullText, contains('stores everything on this phone only'));
      expect(fullText, contains('no account, no server, no analytics, and no ads'));
      expect(fullText, contains('Nothing is sent anywhere by the app'));
      expect(fullText, contains('camera is used only when you scan a work sample'));
      expect(fullText, contains('Pictures stay on this phone'));
      expect(fullText, contains('Android share sheet and only to the app you choose'));
      expect(fullText, contains('Android automatic backup is turned off'));
      expect(fullText, contains('app is for parents and carers'));
      expect(fullText, contains('It does not ask children for any information'));
      expect(fullText, contains('delete a child in Settings, or uninstall the app'));
      expect(fullText, contains('REPLACE_BEFORE_RELEASE'));
      expect(fullText, contains('This is a records tool and not legal advice'));
    });

    test('Zero forbidden claim words exist in privacy policy code or markdown document', () {
      final textFile = File('lib/app/privacy_policy_text.dart');
      final screenFile = File('lib/features/settings/privacy_policy_screen.dart');
      final mdFile = File('docs/PRIVACY_POLICY.md');

      expect(textFile.existsSync(), isTrue);
      expect(screenFile.existsSync(), isTrue);
      expect(mdFile.existsSync(), isTrue);

      final filesToCheck = [textFile, screenFile, mdFile];
      final violations = <String>[];

      for (final file in filesToCheck) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final lower = line.toLowerCase();
          for (final word in kForbiddenClaimWords) {
            // Check as a word/stem match
            if (lower.contains(word)) {
              violations.add('${file.path}:${i + 1} contains "$word": $line');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Forbidden claim words must not appear in privacy policy:\n${violations.join("\n")}',
      );
    });

    testWidgets('Settings screen row opens PrivacyPolicyScreen and renders headings', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => db),
            lastBackupDateStreamProvider.overrideWith((ref) => Stream.value(null)),
            childrenStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Privacy policy'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final privacyTile = find.widgetWithText(ListTile, 'Privacy policy');
      expect(privacyTile, findsOneWidget);
      expect(find.text('Coming soon'), findsNothing);

      await tester.tap(privacyTile);
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('Storage on this device only'), findsOneWidget);
      expect(find.text('Camera access'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('records tool'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('This is a records tool and not legal advice'), findsOneWidget);
      expect(find.textContaining('REPLACE_BEFORE_RELEASE'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
