import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/providers.dart';
import '../../services/revenuecat_entitlement_service.dart';

/// Screen presenting the paid plan benefits, subscription pricing, renewal terms,
/// and purchase / restore actions.
///
/// NOTE: In production with Google Play Console, purchase calls will delegate to
/// Google Play Billing. Here they invoke [FakeEntitlementService].
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;
  String? _localizedPrice;

  @override
  void initState() {
    super.initState();
    _loadLocalizedPrice();
  }

  Future<void> _loadLocalizedPrice() async {
    try {
      final price =
          await ref.read(entitlementServiceProvider).getFormattedYearlyPrice();
      if (price != null && mounted) {
        setState(() {
          _localizedPrice = '$price per year';
        });
      }
    } catch (_) {}
  }

  Future<void> _subscribe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entitlementService = ref.read(entitlementServiceProvider);
      await entitlementService.purchaseYearly();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription activated.')),
        );
        Navigator.of(context).pop(true);
      }
    } on PurchaseCancelledException {
      // User tapped back or dismissed the Google Play payment sheet; no error needed.
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restore() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entitlementService = ref.read(entitlementServiceProvider);
      await entitlementService.restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homeledger Plus'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero header
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    size: 36,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unlock full portfolio and family features',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Everything you need for comprehensive year-end records and multi-student homeschooling.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Benefits list
              const _BenefitRow(
                icon: Icons.picture_as_pdf_outlined,
                title: 'PDF portfolio export',
                subtitle:
                    'Generate print-ready portfolios with attendance logs, subject hour summaries, and work samples.',
              ),
              const SizedBox(height: 16),
              const _BenefitRow(
                icon: Icons.document_scanner_outlined,
                title: 'Work sample scanning',
                subtitle:
                    'Capture, optimize, and store high-resolution student work samples directly on your device.',
              ),
              const SizedBox(height: 16),
              const _BenefitRow(
                icon: Icons.group_outlined,
                title: 'More than one child',
                subtitle:
                    'Track individual learning hours, independent state rules, and school year calendars for each student.',
              ),
              const SizedBox(height: 24),

              // Data retention guarantee card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your records always stay yours. If you stop subscribing, nothing is deleted.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Pricing container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                ),
                child: Column(
                  children: [
                    Text(
                      'Yearly Plan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _localizedPrice ?? kYearlySubscriptionPriceText,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Renews automatically every year until cancelled. Cancel any time in Google Play.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subscribe button
              FilledButton(
                key: const ValueKey('paywall_subscribe_button'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _subscribe,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text(
                        'Subscribe',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 8),

              // Restore purchases button
              TextButton(
                key: const ValueKey('paywall_restore_button'),
                onPressed: _isLoading ? null : _restore,
                child: const Text('Restore purchases'),
              ),
              const SizedBox(height: 12),

              // Placeholder Terms & Privacy link row (no network access)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Terms of Service: Coming soon')),
                      );
                    },
                    child: Text(
                      'Terms of Service',
                      style: theme.textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    '•',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Privacy Policy: Coming soon')),
                      );
                    },
                    child: Text(
                      'Privacy Policy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
