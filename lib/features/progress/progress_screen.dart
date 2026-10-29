import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/progress_calculator.dart';
import '../../domain/requirement_caption.dart';
import '../../domain/rule_resolution.dart';
import '../children/add_child_screen.dart';

/// Screen displaying complete academic progress for a child.
/// Disclaimers: Records tool, not legal advice.
class ProgressScreen extends ConsumerWidget {
  final int childId;

  const ProgressScreen({
    super.key,
    required this.childId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(childProgressProvider(childId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Progress'),
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading progress: $err')),
        data: (state) {
          if (state == null) {
            return const Center(child: Text('Child not found.'));
          }

          if (state.isRuleMissing) {
            return _buildMissingRuleView(context, state.child, theme);
          }

          final progress = state.progress;
          if (progress == null) {
            return _buildMissingRuleView(context, state.child, theme);
          }

          final isCustom = (state.ruleResolution is RuleResolutionFound)
              ? (state.ruleResolution as RuleResolutionFound).profile.isCustom
              : state.child.ruleId.startsWith('custom:');
          final requirementCaption = getRequirementCaption(
            ruleId: state.child.ruleId,
            isCustom: isCustom,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusBanner(context, progress, theme),
                const SizedBox(height: 16),
                _buildSummaryGrid(progress, theme),
                if (requirementCaption != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      requirementCaption,
                      key: const ValueKey('progress_requirement_caption'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _buildCoreSubjectsSection(progress, state.minutesBySubject, theme),
                const SizedBox(height: 20),
                _buildSubjectHoursChart(state.minutesBySubject, theme),
                const SizedBox(height: 24),
                // Legal disclaimer required at bottom of progress screen
                Center(
                  child: Text(
                    AppStrings.legalDisclaimer,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMissingRuleView(
    BuildContext context,
    Child child,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  'Rule profile missing',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The rule previously assigned to ${child.name} could not be resolved or found. Please choose or create a rule profile.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.rule),
                  label: const Text('Choose a rule'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AddChildScreen(initialChild: child),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(
    BuildContext context,
    ProgressResult progress,
    ThemeData theme,
  ) {
    final statusColor = switch (progress.status) {
      ProgressStatus.onPace => Colors.green,
      ProgressStatus.finished => Colors.teal,
      ProgressStatus.behind => Colors.amber.shade800,
      ProgressStatus.notStarted => theme.colorScheme.outline,
      ProgressStatus.invalidDates => theme.colorScheme.error,
    };

    final percentStr = progress.percentOfRequirement != null
        ? '${progress.percentOfRequirement!.toStringAsFixed(0)}%'
        : progress.percentOfDaysRequirement != null
            ? '${progress.percentOfDaysRequirement!.toStringAsFixed(0)}%'
            : '0%';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    progress.status.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  percentStr,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              formatProgressSummary(
                minutesDone: progress.minutesDone,
                requiredMinutes: progress.requiredMinutes,
                daysLogged: progress.daysLogged,
                requiredDays: progress.requiredDays,
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(ProgressResult progress, ThemeData theme) {
    final items = <_SummaryItem>[];

    // 1. Required vs Done
    if (progress.requiredMinutes != null) {
      items.add(_SummaryItem(
        label: 'Required',
        value: formatMinutes(progress.requiredMinutes!),
      ));
      items.add(_SummaryItem(
        label: 'Done',
        value: formatMinutes(progress.minutesDone),
      ));
    } else if (progress.requiredDays != null) {
      items.add(_SummaryItem(
        label: 'Required',
        value: '${progress.requiredDays} days',
      ));
      items.add(_SummaryItem(
        label: 'Done',
        value: '${progress.daysLogged} days',
      ));
    }

    // 2. Expected to date
    if (progress.expectedMinutes != null) {
      items.add(_SummaryItem(
        label: 'Expected to date',
        value: formatMinutes(progress.expectedMinutes!),
      ));
    } else if (progress.expectedDays != null) {
      items.add(_SummaryItem(
        label: 'Expected to date',
        value: '${progress.expectedDays} days',
      ));
    }

    // 3. Remaining
    if (progress.minutesRemaining != null) {
      items.add(_SummaryItem(
        label: 'Remaining',
        value: formatMinutes(progress.minutesRemaining!),
      ));
    } else if (progress.daysRemaining != null) {
      items.add(_SummaryItem(
        label: 'Remaining',
        value: '${progress.daysRemaining} days',
      ));
    }

    // 4. Days left in year
    items.add(_SummaryItem(
      label: 'Days left in year',
      value: '${progress.daysRemainingInYear} days',
    ));

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      item.value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreSubjectsSection(
    ProgressResult progress,
    Map<Subject, int> minutesBySubject,
    ThemeData theme,
  ) {
    if (progress.coreSubjectMinutes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Core subjects',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total: ${formatMinutes(progress.totalCoreMinutes)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...progress.coreSubjectMinutes.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      formatMinutes(entry.value),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectHoursChart(
    Map<Subject, int> minutesBySubject,
    ThemeData theme,
  ) {
    final entries = minutesBySubject.entries.toList();
    if (entries.isEmpty) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hours by subject',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No time logged yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort descending by minutes logged
    entries.sort((a, b) => b.value.compareTo(a.value));
    final maxMinutes = entries.first.value > 0 ? entries.first.value : 1;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hours by subject',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...entries.map((entry) {
              final subject = entry.key;
              final minutes = entry.value;
              final fraction = (minutes / maxMinutes).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subject.isCore ? '${subject.name} (Core)' : subject.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          formatMinutes(minutes),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Plain widget horizontal bar chart
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 12,
                        width: double.infinity,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: fraction,
                          child: Container(
                            color: subject.isCore
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;

  const _SummaryItem({
    required this.label,
    required this.value,
  });
}
