import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/domain/entitlement.dart';

void main() {
  final now = DateTime(2026, 10, 20, 12, 0);

  group('Entitlement isPaid pure function', () {
    test('never paid (paidUntil is null) returns false', () {
      expect(isPaid(now, null, null), isFalse);
      expect(isPaid(now, null, now), isFalse);
    });

    test('future expiration (currently active) returns true', () {
      final futurePaidUntil = now.add(const Duration(days: 30));
      expect(isPaid(now, futurePaidUntil, now), isTrue);
      // Even if lastVerifiedAt is null, if paidUntil is in future, it is paid
      expect(isPaid(now, futurePaidUntil, null), isTrue);
    });

    test('expired inside 7-day grace period returns true', () {
      // Expired 3 days ago, verified 3 days ago (offline grace applies)
      final expired3DaysAgo = now.subtract(const Duration(days: 3));
      final verified3DaysAgo = now.subtract(const Duration(days: 3));

      expect(isPaid(now, expired3DaysAgo, verified3DaysAgo), isTrue);
    });

    test('expired exactly at 7-day grace boundary returns true', () {
      final expired7DaysAgo = now.subtract(const Duration(days: 7));
      final verified7DaysAgo = now.subtract(const Duration(days: 7));

      expect(isPaid(now, expired7DaysAgo, verified7DaysAgo), isTrue);
    });

    test('expired outside 7-day grace period returns false', () {
      // Expired 10 days ago, verified 10 days ago (grace period ended 3 days ago)
      final expired10DaysAgo = now.subtract(const Duration(days: 10));
      final verified10DaysAgo = now.subtract(const Duration(days: 10));

      expect(isPaid(now, expired10DaysAgo, verified10DaysAgo), isFalse);
    });

    test('expired but lastVerifiedAt is null returns false', () {
      final expiredYesterday = now.subtract(const Duration(days: 1));
      expect(isPaid(now, expiredYesterday, null), isFalse);
    });

    test('custom grace days parameter is respected', () {
      final expired5DaysAgo = now.subtract(const Duration(days: 5));
      final verified5DaysAgo = now.subtract(const Duration(days: 5));

      // With 3 grace days, 5 days ago is expired
      expect(isPaid(now, expired5DaysAgo, verified5DaysAgo, graceDays: 3), isFalse);

      // With 10 grace days, 5 days ago is still within grace
      expect(isPaid(now, expired5DaysAgo, verified5DaysAgo, graceDays: 10), isTrue);
    });
  });

  group('EntitlementState model', () {
    test('default free state is not paid', () {
      const state = EntitlementState.free();
      expect(state.plan, EntitlementPlan.free);
      expect(state.paidUntil, isNull);
      expect(state.lastVerifiedAt, isNull);
      expect(state.isPaidAt(now), isFalse);
    });

    test('paid plan with future date is paid', () {
      final state = EntitlementState(
        plan: EntitlementPlan.paid,
        paidUntil: now.add(const Duration(days: 365)),
        lastVerifiedAt: now,
      );
      expect(state.isPaidAt(now), isTrue);
    });

    test('free plan with future paidUntil is NOT paid because plan is free', () {
      final state = EntitlementState(
        plan: EntitlementPlan.free,
        paidUntil: now.add(const Duration(days: 365)),
        lastVerifiedAt: now,
      );
      expect(state.isPaidAt(now), isFalse);
    });
  });
}
