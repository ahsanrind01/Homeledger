import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/core/constants.dart';
import 'package:homeledger/data/db/app_database.dart';
import 'package:homeledger/data/providers.dart';
import 'package:homeledger/data/repositories/entitlement_repository.dart';
import 'package:homeledger/domain/entitlement.dart';
import 'package:homeledger/features/paywall/paywall_screen.dart';
import 'package:homeledger/services/entitlement_service.dart';

void main() {
  late AppDatabase db;
  late EntitlementRepository entitlementRepo;
  late FakeEntitlementService fakeService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    entitlementRepo = EntitlementRepository(db);
    fakeService = FakeEntitlementService(
      entitlementRepo,
      clock: () => DateTime(2026, 10, 20, 12, 0),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildSubjectUnderTest() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        entitlementRepositoryProvider.overrideWithValue(entitlementRepo),
        fakeEntitlementServiceProvider.overrideWithValue(fakeService),
        entitlementServiceProvider.overrideWithValue(fakeService),
      ],
      child: const MaterialApp(
        home: PaywallScreen(),
      ),
    );
  }

  testWidgets('PaywallScreen displays all mandated benefits, pricing, and disclosure texts', (tester) async {
    await tester.pumpWidget(buildSubjectUnderTest());
    await tester.pumpAndSettle();

    // 1. Benefits
    expect(find.text('PDF portfolio export'), findsOneWidget);
    expect(find.text('Work sample scanning'), findsOneWidget);
    expect(find.text('More than one child'), findsOneWidget);

    // 2. Price loaded from single constant
    expect(find.text(kYearlySubscriptionPriceText), findsOneWidget);

    // 3. Exact disclosure text
    expect(
      find.text('Renews automatically every year until cancelled. Cancel any time in Google Play.'),
      findsOneWidget,
    );

    // 4. Data retention guarantee text
    expect(
      find.text('Your records always stay yours. If you stop subscribing, nothing is deleted.'),
      findsOneWidget,
    );

    // 5. Actions & link row placeholders
    expect(find.byKey(const ValueKey('paywall_subscribe_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('paywall_restore_button')), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('Tapping Subscribe triggers purchase and pops screen with success', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          entitlementRepositoryProvider.overrideWithValue(entitlementRepo),
          fakeEntitlementServiceProvider.overrideWithValue(fakeService),
          entitlementServiceProvider.overrideWithValue(fakeService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PaywallScreen(),
                    ),
                  );
                },
                child: const Text('Open Paywall'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open paywall
    await tester.tap(find.text('Open Paywall'));
    await tester.pumpAndSettle();

    expect(find.byType(PaywallScreen), findsOneWidget);

    // Initial plan is free
    final initial = await fakeService.current();
    expect(initial.plan, EntitlementPlan.free);

    // Tap Subscribe
    final subscribeButton = find.byKey(const ValueKey('paywall_subscribe_button'));
    await tester.ensureVisible(subscribeButton);
    await tester.tap(subscribeButton);
    await tester.pumpAndSettle();

    // Paywall should pop and plan should be paid
    expect(find.byType(PaywallScreen), findsNothing);
    final updated = await fakeService.current();
    expect(updated.plan, EntitlementPlan.paid);
    expect(updated.paidUntil, isNotNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('Terms of Service and Privacy Policy placeholders show snackbars without network', (tester) async {
    await tester.pumpWidget(buildSubjectUnderTest());
    await tester.pumpAndSettle();

    // Tap Terms of Service
    final tos = find.text('Terms of Service');
    await tester.ensureVisible(tos);
    await tester.tap(tos);
    await tester.pump();
    expect(find.text('Terms of Service: Coming soon'), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(PaywallScreen))).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // Tap Privacy Policy
    final privacy = find.text('Privacy Policy');
    await tester.ensureVisible(privacy);
    await tester.tap(privacy);
    await tester.pump();
    expect(find.text('Privacy Policy: Coming soon'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
