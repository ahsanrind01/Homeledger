import '../core/constants.dart';

/// Subscription plans supported by Homeledger.
enum EntitlementPlan {
  free,
  paid,
}

/// Immutable domain model representing the current device entitlement state.
class EntitlementState {
  final EntitlementPlan plan;
  final DateTime? paidUntil;
  final DateTime? lastVerifiedAt;

  const EntitlementState({
    this.plan = EntitlementPlan.free,
    this.paidUntil,
    this.lastVerifiedAt,
  });

  /// Factory creating an uninitialized/default free entitlement state.
  const EntitlementState.free()
      : plan = EntitlementPlan.free,
        paidUntil = null,
        lastVerifiedAt = null;

  /// Pure helper checking whether this entitlement is paid at the given [now] timestamp.
  bool isPaidAt(DateTime now, {int graceDays = kEntitlementGraceDays}) {
    if (plan != EntitlementPlan.paid) {
      return false;
    }
    return isPaid(now, paidUntil, lastVerifiedAt, graceDays: graceDays);
  }

  EntitlementState copyWith({
    EntitlementPlan? plan,
    DateTime? paidUntil,
    DateTime? lastVerifiedAt,
  }) {
    return EntitlementState(
      plan: plan ?? this.plan,
      paidUntil: paidUntil ?? this.paidUntil,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntitlementState &&
          runtimeType == other.runtimeType &&
          plan == other.plan &&
          paidUntil == other.paidUntil &&
          lastVerifiedAt == other.lastVerifiedAt;

  @override
  int get hashCode =>
      plan.hashCode ^ paidUntil.hashCode ^ lastVerifiedAt.hashCode;

  @override
  String toString() =>
      'EntitlementState(plan: $plan, paidUntil: $paidUntil, lastVerifiedAt: $lastVerifiedAt)';
}

/// Pure entitlement verification function.
///
/// EXACT RULE:
/// 1. If [paidUntil] is null, the user has never had an active subscription or has
///    no paid expiration set -> returns `false`.
/// 2. If [now] is strictly before [paidUntil], the subscription is currently active
///    in the future -> returns `true`.
/// 3. If [paidUntil] has passed (i.e. [now] >= [paidUntil]):
///    The subscription is expired, but is still considered paid ONLY while [now] is
///    within [graceDays] of [lastVerifiedAt] (offline grace period for when the app
///    cannot reach Google Play to verify renewal).
///    - If [lastVerifiedAt] is null, no verification date exists -> returns `false`.
///    - If [now] is within [graceDays] of [lastVerifiedAt]
///      (!now.isAfter(lastVerifiedAt + graceDays)), offline grace applies -> returns `true`.
///    - If [now] has exceeded [lastVerifiedAt] + [graceDays], the subscription has
///      definitively lapsed -> returns `false`.
bool isPaid(
  DateTime now,
  DateTime? paidUntil,
  DateTime? lastVerifiedAt, {
  int graceDays = kEntitlementGraceDays,
}) {
  if (paidUntil == null) {
    return false;
  }

  // 1. Currently active in the future
  if (now.isBefore(paidUntil)) {
    return true;
  }

  // 2. Expired: check offline grace period
  if (lastVerifiedAt == null) {
    return false;
  }

  final graceEnd = lastVerifiedAt.add(Duration(days: graceDays));
  // Allowed if now has not passed the grace period end
  return !now.isAfter(graceEnd);
}
