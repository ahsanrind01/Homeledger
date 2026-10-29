import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/domain/feature_policy.dart';
import 'package:homeledger/features/export/export_options_screen.dart';
import 'package:homeledger/features/export/export_service.dart';

class MockSelectedChildIdNotifier extends SelectedChildIdNotifier {
  final int? initial;
  MockSelectedChildIdNotifier(this.initial);

  @override
  int? build() => initial;
}

class FakeExportService implements ExportService {
  final Completer<File> completer = Completer<File>();
  bool called = false;

  @override
  Future<File> exportAndSharePortfolio({
    required int childId,
    required String dateRangeStart,
    required String dateRangeEnd,
    required bool includeWorkSamples,
  }) {
    called = true;
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ExportOptionsScreen shows empty state when no children exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: ExportOptionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No student profiles found. Add a child first.'), findsOneWidget);
    expect(find.text('Create PDF'), findsNothing);
  });

  testWidgets('ExportOptionsScreen displays child, default dates, and toggle', (tester) async {
    final child = Child(
      id: 1,
      name: 'Maya Lin',
      ruleId: 'test_rule',
      schoolYearStart: '2026-08-15',
      schoolYearEnd: '2027-05-30',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenStreamProvider.overrideWith((ref) => Stream.value([child])),
          selectedChildIdProvider.overrideWith(() => MockSelectedChildIdNotifier(1)),
          featureAccessProvider(Feature.exportPdf).overrideWithValue(FeatureAccess.allowed),
        ],
        child: const MaterialApp(
          home: ExportOptionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Export portfolio'), findsOneWidget);
    expect(find.text('Include work samples'), findsOneWidget);
    expect(find.text('Create PDF'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);

    // Toggle switch
    final switchFinder = find.byType(Switch);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isFalse);
  });

  testWidgets('ExportOptionsScreen displays student dropdown when multiple children exist', (tester) async {
    final child1 = Child(
      id: 1,
      name: 'Maya Lin',
      ruleId: 'test_rule',
      schoolYearStart: '2026-08-15',
      schoolYearEnd: '2027-05-30',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final child2 = Child(
      id: 2,
      name: 'Leo Lin',
      ruleId: 'test_rule',
      schoolYearStart: '2026-09-01',
      schoolYearEnd: '2027-06-15',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenStreamProvider.overrideWith((ref) => Stream.value([child1, child2])),
          selectedChildIdProvider.overrideWith(() => MockSelectedChildIdNotifier(1)),
          featureAccessProvider(Feature.exportPdf).overrideWithValue(FeatureAccess.allowed),
        ],
        child: const MaterialApp(
          home: ExportOptionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
  });

  testWidgets('Tapping Create PDF triggers export and displays progress indicator', (tester) async {
    final child = Child(
      id: 1,
      name: 'Maya Lin',
      ruleId: 'test_rule',
      schoolYearStart: '2026-08-15',
      schoolYearEnd: '2027-05-30',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final fakeService = FakeExportService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenStreamProvider.overrideWith((ref) => Stream.value([child])),
          selectedChildIdProvider.overrideWith(() => MockSelectedChildIdNotifier(1)),
          exportServiceProvider.overrideWith((ref) async => fakeService),
          featureAccessProvider(Feature.exportPdf).overrideWithValue(FeatureAccess.allowed),
        ],
        child: const MaterialApp(
          home: ExportOptionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create PDF'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Tap Create PDF
    await tester.tap(find.text('Create PDF'));
    await tester.pump(); // Render in-progress state

    expect(fakeService.called, isTrue);
    expect(find.text('Creating PDF...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete the export
    fakeService.completer.complete(File('test.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('Create PDF'), findsOneWidget);
    expect(find.text('Portfolio generated successfully.'), findsOneWidget);
  });

  testWidgets('ExportOptionsScreen shows no notice for default full school year range', (tester) async {
    final child = Child(
      id: 1,
      name: 'Maya Lin',
      ruleId: 'test_rule',
      schoolYearStart: '2026-08-15',
      schoolYearEnd: '2027-05-30',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenStreamProvider.overrideWith((ref) => Stream.value([child])),
          selectedChildIdProvider.overrideWith(() => MockSelectedChildIdNotifier(1)),
          featureAccessProvider(Feature.exportPdf).overrideWithValue(FeatureAccess.allowed),
        ],
        child: const MaterialApp(
          home: ExportOptionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default dates match school year exactly -> no notice
    expect(find.byKey(const ValueKey('export_range_notice_text')), findsNothing);
  });
}
