import 'entitlement.dart';

/// Features within Homeledger that may be subject to plan gating.
enum Feature {
  /// Logging daily learning hours (Free).
  logging,

  /// Viewing progress against state requirement (Free).
  progress,

  /// Creating manual backup archives (Free).
  backup,

  /// Restoring data from backup archive (Free).
  restore,

  /// Viewing saved work sample library & images (Free).
  viewSamples,

  /// Exporting official PDF portfolio (Paid-only).
  exportPdf,

  /// Document scanner & camera work sample capture (Paid-only).
  scanSample,

  /// Adding more than one child / student profile (Paid-only).
  secondChild,
}

/// Access status result from [canUse].
enum FeatureAccess {
  allowed,
  locked;

  bool get isAllowed => this == FeatureAccess.allowed;
  bool get isLocked => this == FeatureAccess.locked;
}

/// Central feature access policy function.
///
/// RULES:
/// - Free plan always allows:
///   - [Feature.logging]
///   - [Feature.progress]
///   - [Feature.backup]
///   - [Feature.restore]
///   - [Feature.viewSamples]
///
/// - Paid plan is required for:
///   - [Feature.exportPdf]
///   - [Feature.scanSample]
///   - [Feature.secondChild]
///
/// Every lock check in the UI MUST go through [canUse].
/// No screen may check the plan or subscription directly by itself.
FeatureAccess canUse(
  Feature feature,
  EntitlementState entitlement,
  DateTime now,
) {
  // Free features are unconditionally allowed for all users at all times.
  switch (feature) {
    case Feature.logging:
    case Feature.progress:
    case Feature.backup:
    case Feature.restore:
    case Feature.viewSamples:
      return FeatureAccess.allowed;

    case Feature.exportPdf:
    case Feature.scanSample:
    case Feature.secondChild:
      final paid = isPaid(
        now,
        entitlement.paidUntil,
        entitlement.lastVerifiedAt,
      );
      return (entitlement.plan == EntitlementPlan.paid && paid)
          ? FeatureAccess.allowed
          : FeatureAccess.locked;
  }
}
