import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/app/app.dart';
import 'package:homeledger/core/strings.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/data/repositories/settings_repository.dart';

void main() {
  testWidgets('Disclaimer screen is shown on first launch and never again after acceptance',
      (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final settingsRepo = SettingsRepository(db);

    // 1. Initial launch - disclaimer not yet accepted
    expect(await settingsRepo.isDisclaimerAccepted(), isFalse);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const HomeledgerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify disclaimer text and button are visible
    expect(find.text(AppStrings.fullDisclaimer), findsOneWidget);
    expect(find.text('I understand'), findsOneWidget);

    // 2. Tap 'I understand'
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();

    // Verify choice was remembered in database
    expect(await settingsRepo.isDisclaimerAccepted(), isTrue);

    // With no children in database, app routes to Add child screen
    expect(find.text('Add child'), findsOneWidget);
    expect(find.text(AppStrings.fullDisclaimer), findsNothing);

    // 3. Restart the app (simulated by re-pumping with the same database)
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const HomeledgerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Disclaimer must NOT return
    expect(find.text(AppStrings.fullDisclaimer), findsNothing);
    expect(find.text('Add child'), findsOneWidget);

    await db.close();
  });
}
