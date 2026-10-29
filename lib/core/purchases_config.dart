import 'dart:io';

/// Configuration constants for RevenueCat In-App Purchases and Subscriptions.
///
/// Setup instructions:
/// 1. Create a free account at https://www.revenuecat.com
/// 2. Create a project named "Homeledger"
/// 3. In RevenueCat dashboard, create an Android app and link your Google Play credentials.
/// 4. Copy the Public API key for Google Play and paste it into [revenueCatGoogleApiKey].
/// 5. In RevenueCat dashboard, create an Entitlement with identifier [kEntitlementIdentifier] (default: 'plus').
/// 6. Create an Offering (default: 'default') and attach a yearly package pointing to your Google Play subscription product.
class PurchasesConfig {
  PurchasesConfig._();

  /// RevenueCat Public API Key for Google Play.
  /// Replace with your actual key from RevenueCat dashboard (e.g. 'goog_xxxxxxxxxxxxxxxxxxxxxx').
  static const String revenueCatGoogleApiKey = 'YOUR_GOOGLE_PLAY_REVENUECAT_API_KEY';

  /// RevenueCat Public API Key for Apple App Store (if deploying to iOS in the future).
  static const String revenueCatAppleApiKey = 'YOUR_APPLE_REVENUECAT_API_KEY';

  /// The entitlement identifier configured in your RevenueCat dashboard.
  /// Must match the entitlement that unlocks Homeledger Plus features.
  static const String kEntitlementIdentifier = 'plus';

  /// Returns true if valid production API keys have been provided.
  static bool get isPurchasesConfigured {
    if (Platform.isAndroid) {
      return revenueCatGoogleApiKey.isNotEmpty &&
          revenueCatGoogleApiKey != 'YOUR_GOOGLE_PLAY_REVENUECAT_API_KEY';
    } else if (Platform.isIOS || Platform.isMacOS) {
      return revenueCatAppleApiKey.isNotEmpty &&
          revenueCatAppleApiKey != 'YOUR_APPLE_REVENUECAT_API_KEY';
    }
    return false;
  }

  /// Returns the appropriate API key for the current platform.
  static String get apiKey {
    if (Platform.isAndroid) {
      return revenueCatGoogleApiKey;
    } else if (Platform.isIOS || Platform.isMacOS) {
      return revenueCatAppleApiKey;
    }
    return '';
  }
}
