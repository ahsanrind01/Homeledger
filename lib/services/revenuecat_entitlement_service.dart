import 'dart:async';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/purchases_config.dart';
import '../data/db/app_database.dart';
import '../data/repositories/entitlement_repository.dart';
import '../domain/entitlement.dart';
import 'entitlement_service.dart';

/// Exception thrown when the user intentionally cancels Google Play purchase flow.
class PurchaseCancelledException implements Exception {
  final String message;
  const PurchaseCancelledException([this.message = 'Purchase was cancelled.']);

  @override
  String toString() => message;
}

/// Production implementation of [EntitlementService] powered by RevenueCat & Google Play Billing.
///
/// Features:
/// - Connects to Google Play Billing through RevenueCat.
/// - Automatically mirrors subscription status into the local SQLite [EntitlementRepository].
/// - Preserves offline access and offline grace period using local cached records.
/// - Emits real-time state updates when subscriptions renew, expire, or are restored.
class RevenueCatEntitlementService implements EntitlementService {
  final EntitlementRepository _repository;
  final DateTime Function() _clock;
  bool _isInitialized = false;

  RevenueCatEntitlementService(
    this._repository, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Initializes RevenueCat with API keys from [PurchasesConfig].
  /// Safe to call multiple times (only initializes once).
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!PurchasesConfig.isPurchasesConfigured) {
      // In unconfigured environments, initialization is skipped.
      return;
    }

    try {
      final configuration = PurchasesConfiguration(PurchasesConfig.apiKey);
      await Purchases.configure(configuration);

      // Listen for background subscription updates (e.g., auto-renewals, refunds, cancellations)
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _syncCustomerInfo(customerInfo);
      });

      // Sync customer info on startup if internet is available
      final customerInfo = await Purchases.getCustomerInfo();
      await _syncCustomerInfo(customerInfo);

      _isInitialized = true;
    } catch (_) {
      // If network is offline during startup, the local SQLite database cache
      // ensures the app remains fully functional for the user.
    }
  }

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

  /// Syncs RevenueCat [CustomerInfo] into SQLite database.
  Future<void> _syncCustomerInfo(CustomerInfo customerInfo) async {
    final entitlement = customerInfo
            .entitlements.all[PurchasesConfig.kEntitlementIdentifier] ??
        customerInfo.entitlements.active.values.firstOrNull;

    final isActive = entitlement != null && entitlement.isActive;
    final now = _clock();

    if (isActive) {
      DateTime? paidUntil;
      if (entitlement.expirationDate != null) {
        paidUntil = DateTime.tryParse(entitlement.expirationDate!);
      }
      paidUntil ??= now.add(const Duration(days: 365));

      await _repository.set(
        plan: 'paid',
        paidUntil: paidUntil.toIso8601String(),
        lastVerifiedAt: now.toIso8601String(),
      );
    } else {
      await _repository.set(
        plan: 'free',
        paidUntil: null,
        lastVerifiedAt: now.toIso8601String(),
      );
    }
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
    await initialize();

    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;

      Package? packageToPurchase = currentOffering?.annual;
      packageToPurchase ??= currentOffering?.availablePackages.firstOrNull;

      if (packageToPurchase == null) {
        throw Exception(
          'No subscription packages found. Please verify products are configured in Google Play Console and RevenueCat.',
        );
      }

      final purchaseResult =
          await Purchases.purchase(PurchaseParams.package(packageToPurchase));
      await _syncCustomerInfo(purchaseResult.customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseCancelledException();
      }
      throw Exception(e.message ?? 'Purchase failed');
    } catch (e) {
      if (e is PurchaseCancelledException) rethrow;
      throw Exception('Purchase error: $e');
    }
  }

  @override
  Future<void> restorePurchases() async {
    await initialize();

    try {
      final customerInfo = await Purchases.restorePurchases();
      await _syncCustomerInfo(customerInfo);

      final hasActive = customerInfo.entitlements.active.isNotEmpty;
      if (!hasActive) {
        throw Exception(
          'No active subscriptions found for this Google Play account.',
        );
      }
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Restore failed');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> getFormattedYearlyPrice() async {
    try {
      await initialize();
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.annual ??
          offerings.current?.availablePackages.firstOrNull;
      return package?.storeProduct.priceString;
    } catch (_) {
      return null;
    }
  }
}
