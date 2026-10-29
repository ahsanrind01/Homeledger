import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/providers.dart';
import '../../domain/entitlement.dart';

/// Hidden, debug-only screen allowing engineers and testers to simulate
/// free, paid, grace period, and expired subscription states without real billing.
///
/// This screen is strictly gated by [kDebugMode] and will NEVER be accessible
/// in release builds.
class DebugEntitlementScreen extends ConsumerWidget {
  const DebugEntitlementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug tools unavailable in release builds.')),
      );
    }

    final theme = Theme.of(context);
    final entitlementService = ref.watch(fakeEntitlementServiceProvider);
    final entitlementAsync = ref.watch(entitlementStateStreamProvider);
    final now = ref.watch(clockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Subscription State'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Entitlement',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    entitlementAsync.when(
                      data: (state) {
                        final paid = isPaid(
                          now,
                          state.paidUntil,
                          state.lastVerifiedAt,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan: ${state.plan.name.toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Effective Status: ${paid ? "PAID (Active)" : "FREE / LAPSED"}',
                              style: TextStyle(
                                color: paid
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Paid until: ${state.paidUntil != null ? formatDisplayDate(state.paidUntil!) : "None"} '
                              '(${state.paidUntil?.toIso8601String() ?? "null"})',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last checked: ${state.lastVerifiedAt != null ? formatDisplayDate(state.lastVerifiedAt!) : "None"} '
                              '(${state.lastVerifiedAt?.toIso8601String() ?? "null"})',
                            ),
                          ],
                        );
                      },
                      loading: () => const Text('Loading entitlement...'),
                      error: (err, _) => Text('Error: $err'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Simulate State',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Button 1: Set free
            FilledButton.tonal(
              onPressed: () async {
                await entitlementService.setFree();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan reset to Free')),
                  );
                }
              },
              child: const Text('Set free'),
            ),
            const SizedBox(height: 8),

            // Button 2: Set paid for 1 year
            FilledButton(
              onPressed: () async {
                await entitlementService.setPaidForOneYear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Plan set to Paid (valid 1 year)')),
                  );
                }
              },
              child: const Text('Set paid for 1 year'),
            ),
            const SizedBox(height: 8),

            // Button 3: Set paid expired 3 days ago (within 7-day grace)
            OutlinedButton(
              onPressed: () async {
                await entitlementService.setPaidExpiredDaysAgo(3);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Plan set to Expired 3 days ago (Within 7-day grace period)'),
                    ),
                  );
                }
              },
              child: const Text('Set paid expired 3 days ago'),
            ),
            const SizedBox(height: 8),

            // Button 4: Set paid expired 10 days ago (outside 7-day grace -> lapsed)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () async {
                await entitlementService.setPaidExpiredDaysAgo(10);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Plan set to Expired 10 days ago (Lapsed: outside grace period)'),
                    ),
                  );
                }
              },
              child: const Text('Set paid expired 10 days ago'),
            ),
          ],
        ),
      ),
    );
  }
}
