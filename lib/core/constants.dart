/// Pace calculation factor: a child is on pace if done >= 90% of expected.
const double kEnoughPaceFactor = 0.90;

/// Grace period in days for offline subscription verification after expiration.
const int kEntitlementGraceDays = 7;

/// Single constant for subscription price display text.
/// NOTE: In production with Google Play Console, this string must be loaded
/// dynamically from Google Play Billing product details to reflect local currencies.
const String kYearlySubscriptionPriceText = r'US$39.99 per year';

/// Regulatory forbidden claim words that must NEVER appear in user-facing UI or generated PDFs.
const List<String> kForbiddenClaimWords = [
  'official',
  'verified',
  'verify',
  'approved',
  'compliant',
  'compliance',
  'guaranteed',
  'certified',
  'accredited',
];

class AppConstants {
  const AppConstants._();

  /// Minimum recommended tap target size in dp for accessibility.
  static const double minTapTargetSize = 48.0;

  /// Time logged for one child on one day: block above 24 hours.
  static const double maxDailyHours = 24.0;

  /// Time logged for one child on one day: warn above 10 hours.
  static const double warnDailyHours = 10.0;

  /// Pace calculation: On pace if hours done >= 90% of expected hours.
  static const double onPaceThreshold = kEnoughPaceFactor;

  /// Named pace threshold factor.
  static const double enoughPaceFactor = kEnoughPaceFactor;
}
