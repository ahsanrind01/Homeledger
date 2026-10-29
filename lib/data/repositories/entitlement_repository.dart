import 'package:drift/drift.dart';
import '../db/app_database.dart';

/// Repository for managing the single device entitlement / subscription state.
class EntitlementRepository {
  final AppDatabase _db;

  const EntitlementRepository(this._db);

  /// Fetches the current entitlement state, or null if none is initialized.
  Future<EntitlementData?> get() {
    return (_db.select(_db.entitlements)..limit(1)).getSingleOrNull();
  }

  /// Continuously watches the current entitlement state.
  Stream<EntitlementData?> watch() {
    return (_db.select(_db.entitlements)..limit(1)).watchSingleOrNull();
  }

  /// Sets or updates the entitlement record.
  /// If a record exists, updates it. If none exists, inserts the initial row.
  Future<void> set({
    String? paidUntil,
    String? lastVerifiedAt,
    required String plan,
  }) async {
    final existing = await get();
    if (existing == null) {
      await _db.into(_db.entitlements).insert(
            EntitlementsCompanion.insert(
              paidUntil: Value(paidUntil),
              lastVerifiedAt: Value(lastVerifiedAt),
              plan: Value(plan),
            ),
          );
    } else {
      await (_db.update(_db.entitlements)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        EntitlementsCompanion(
          paidUntil: Value(paidUntil),
          lastVerifiedAt: Value(lastVerifiedAt),
          plan: Value(plan),
        ),
      );
    }
  }

  /// Resets or initializes the entitlement to the default free plan.
  Future<void> resetToFree() {
    return set(
      paidUntil: null,
      lastVerifiedAt: null,
      plan: 'free',
    );
  }
}
