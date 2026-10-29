import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/app/app.dart';
import 'package:homeledger/core/strings.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';

void main() {
  testWidgets('App starts and shows disclaimer on first launch',
      (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const HomeledgerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify app name and full disclaimer text are shown
    expect(find.text(AppStrings.appName), findsAtLeastNWidgets(1));
    expect(find.text(AppStrings.fullDisclaimer), findsOneWidget);
    expect(find.text('I understand'), findsOneWidget);

    await db.close();
  });
}
