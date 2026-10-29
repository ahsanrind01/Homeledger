import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/domain/entitlement.dart';
import 'package:homeledger/domain/feature_policy.dart';

void main() {
  final now = DateTime(2026, 10, 20, 12, 0);

  group('Feature Policy canUse matrix', () {
    test('FREE plan: logging, progress, backup, restore, viewSamples allowed; export, scan, secondChild locked', () {
      const freeState = EntitlementState.free();

      // Allowed free features
      expect(canUse(Feature.logging, freeState, now), FeatureAccess.allowed);
      expect(canUse(Feature.progress, freeState, now), FeatureAccess.allowed);
      expect(canUse(Feature.backup, freeState, now), FeatureAccess.allowed);
      expect(canUse(Feature.restore, freeState, now), FeatureAccess.allowed);
      expect(canUse(Feature.viewSamples, freeState, now), FeatureAccess.allowed);

      // Locked paid features
      expect(canUse(Feature.exportPdf, freeState, now), FeatureAccess.locked);
      expect(canUse(Feature.scanSample, freeState, now), FeatureAccess.locked);
      expect(canUse(Feature.secondChild, freeState, now), FeatureAccess.locked);
    });

    test('PAID plan: all 8 features are allowed', () {
      final paidState = EntitlementState(
        plan: EntitlementPlan.paid,
        paidUntil: now.add(const Duration(days: 365)),
        lastVerifiedAt: now,
      );

      for (final feature in Feature.values) {
        expect(
          canUse(feature, paidState, now),
          FeatureAccess.allowed,
          reason: 'Feature $feature should be allowed for paid plan',
        );
      }
    });

    test('PAID plan within grace period: all 8 features are allowed', () {
      // Expired 3 days ago, verified 3 days ago (grace period <= 7 days)
      final graceState = EntitlementState(
        plan: EntitlementPlan.paid,
        paidUntil: now.subtract(const Duration(days: 3)),
        lastVerifiedAt: now.subtract(const Duration(days: 3)),
      );

      for (final feature in Feature.values) {
        expect(
          canUse(feature, graceState, now),
          FeatureAccess.allowed,
          reason: 'Feature $feature should be allowed during grace period',
        );
      }
    });

    test('LAPSED plan (expired outside grace): free features remain allowed, paid features locked', () {
      // Expired 10 days ago, verified 10 days ago (> 7 days grace)
      final lapsedState = EntitlementState(
        plan: EntitlementPlan.paid,
        paidUntil: now.subtract(const Duration(days: 10)),
        lastVerifiedAt: now.subtract(const Duration(days: 10)),
      );

      // Free features MUST remain allowed
      expect(canUse(Feature.logging, lapsedState, now), FeatureAccess.allowed);
      expect(canUse(Feature.progress, lapsedState, now), FeatureAccess.allowed);
      expect(canUse(Feature.backup, lapsedState, now), FeatureAccess.allowed);
      expect(canUse(Feature.restore, lapsedState, now), FeatureAccess.allowed);
      expect(canUse(Feature.viewSamples, lapsedState, now), FeatureAccess.allowed);

      // Paid features are locked
      expect(canUse(Feature.exportPdf, lapsedState, now), FeatureAccess.locked);
      expect(canUse(Feature.scanSample, lapsedState, now), FeatureAccess.locked);
      expect(canUse(Feature.secondChild, lapsedState, now), FeatureAccess.locked);
    });
  });
}
