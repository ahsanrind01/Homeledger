import '../data/db/app_database.dart';
import '../data/repositories/entitlement_repository.dart';
import '../domain/entitlement.dart';

/// Contract for managing application subscription and entitlement verification.
///
/// NOTE: In production with Google Play Console, this interface will be implemented
/// by a Google Play Billing service (using in_app_purchase). During development
/// and testing, [FakeEntitlementService] is used exclusively.
abstract class EntitlementService {
  /// Fetches the current snapshot of device entitlement.
  Future<EntitlementState> current();

  /// Stream of entitlement state changes (updates on purchase, restore, or debug override).
  Stream<EntitlementState> get changes;

  /// Simulates / triggers a 1-year subscription purchase.
  Future<void> purchaseYearly();

  /// Simulates / triggers restoring existing purchases.
  Future<void> restorePurchases();

  /// Fetches the localized yearly price string from Google Play / Store products if available.
  Future<String?> getFormattedYearlyPrice() async => null;
}

/// Fake, offline-only entitlement service that persists state into SQLite
/// through [EntitlementRepository].
class FakeEntitlementService implements EntitlementService {
  final EntitlementRepository _repository;
  final DateTime Function() _clock;

  FakeEntitlementService(
    this._repository, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  EntitlementState _mapDataToState(EntitlementData? data) {
    if (data == null) {
      return const EntitlementState.free();
    }
    final plan =
        data.plan == 'paid' ? EntitlementPlan.paid : EntitlementPlan.free;

    DateTime? paidUntil;
    if (data.paidUntil != null && data.paidUntil!.isNotEmpty) {
      paidUntil = DateTime.tryParse(data.paidUntil!);
    }

    DateTime? lastVerifiedAt;
    if (data.lastVerifiedAt != null && data.lastVerifiedAt!.isNotEmpty) {
      lastVerifiedAt = DateTime.tryParse(data.lastVerifiedAt!);
    }

    return EntitlementState(
      plan: plan,
      paidUntil: paidUntil,
      lastVerifiedAt: lastVerifiedAt,
    );
  }

  @override
  Future<EntitlementState> current() async {
    final data = await _repository.get();
    return _mapDataToState(data);
  }

  @override
  Stream<EntitlementState> get changes {
    return _repository.watch().map(_mapDataToState);
  }

  @override
  Future<void> purchaseYearly() async {
    final now = _clock();
    final paidUntil = now.add(const Duration(days: 365));
    await _repository.set(
      plan: 'paid',
      paidUntil: paidUntil.toIso8601String(),
      lastVerifiedAt: now.toIso8601String(),
    );
  }

  @override
  Future<void> restorePurchases() async {
    final data = await _repository.get();
    final now = _clock();
    if (data != null && data.paidUntil != null) {
      await _repository.set(
        plan: data.plan,
        paidUntil: data.paidUntil,
        lastVerifiedAt: now.toIso8601String(),
      );
    }
  }

  @override
  Future<String?> getFormattedYearlyPrice() async => null;

  // ---------------------------------------------------------------------------
  // Debug / Test Helper Methods
  // ---------------------------------------------------------------------------

  /// Sets device plan to Free.
  Future<void> setFree() async {
    await _repository.resetToFree();
  }

  /// Sets device plan to Paid, valid for 365 days from now.
  Future<void> setPaidForOneYear() async {
    final now = _clock();
    final paidUntil = now.add(const Duration(days: 365));
    await _repository.set(
      plan: 'paid',
      paidUntil: paidUntil.toIso8601String(),
      lastVerifiedAt: now.toIso8601String(),
    );
  }

  /// Sets device plan to Paid, but expired [days] ago (both paidUntil and lastVerifiedAt).
  ///
  /// - `days = 3`: Expired 3 days ago -> within 7-day offline grace -> still effectively paid.
  /// - `days = 10`: Expired 10 days ago -> outside 7-day grace -> lapsed / locked.
  Future<void> setPaidExpiredDaysAgo(int days) async {
    final now = _clock();
    final past = now.subtract(Duration(days: days));
    await _repository.set(
      plan: 'paid',
      paidUntil: past.toIso8601String(),
      lastVerifiedAt: past.toIso8601String(),
    );
  }
}
