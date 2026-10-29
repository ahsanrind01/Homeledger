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
import '../../app/kids_visuals.dart';

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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusBanner(context, progress, theme),
                const SizedBox(height: 18),
                _buildSummaryGrid(progress, theme),
                if (requirementCaption != null) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      requirementCaption,
                      key: const ValueKey('progress_requirement_caption'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                _buildCoreSubjectsSection(progress, state.minutesBySubject, theme),
                const SizedBox(height: 22),
                _buildSubjectHoursChart(state.minutesBySubject, theme),
                const SizedBox(height: 28),
                // Legal disclaimer required at bottom of progress screen
                Center(
                  child: Text(
                    AppStrings.legalDisclaimer,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(height: 14),
              Text(
                'Rule profile missing',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildStatusBanner(
    BuildContext context,
    ProgressResult progress,
    ThemeData theme,
  ) {
    final (statusColor, statusBg) = switch (progress.status) {
      ProgressStatus.onPace => (const Color(0xFF0F766E), const Color(0xFFCCFBF1)),
      ProgressStatus.finished => (const Color(0xFF0D9488), const Color(0xFFCCFBF1)),
      ProgressStatus.behind => (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      ProgressStatus.notStarted => (theme.colorScheme.outline, theme.colorScheme.surfaceContainerHighest),
      ProgressStatus.invalidDates => (theme.colorScheme.error, theme.colorScheme.errorContainer),
    };

    final percentStr = progress.percentOfRequirement != null
        ? '${progress.percentOfRequirement!.toStringAsFixed(0)}%'
        : progress.percentOfDaysRequirement != null
            ? '${progress.percentOfDaysRequirement!.toStringAsFixed(0)}%'
            : '0%';

    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  progress.status.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                percentStr,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            formatProgressSummary(
              minutesDone: progress.minutesDone,
              requiredMinutes: progress.requiredMinutes,
              daysLogged: progress.daysLogged,
              requiredDays: progress.requiredDays,
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
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
        icon: Icons.flag_rounded,
        color: const Color(0xFF4F46E5),
        bgColor: const Color(0xFFEEF2FF),
      ));
      items.add(_SummaryItem(
        label: 'Done',
        value: formatMinutes(progress.minutesDone),
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF059669),
        bgColor: const Color(0xFFD1FAE5),
      ));
    } else if (progress.requiredDays != null) {
      items.add(_SummaryItem(
        label: 'Required',
        value: '${progress.requiredDays} days',
        icon: Icons.flag_rounded,
        color: const Color(0xFF4F46E5),
        bgColor: const Color(0xFFEEF2FF),
      ));
      items.add(_SummaryItem(
        label: 'Done',
        value: '${progress.daysLogged} days',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF059669),
        bgColor: const Color(0xFFD1FAE5),
      ));
    }

    // 2. Expected to date
    if (progress.expectedMinutes != null) {
      items.add(_SummaryItem(
        label: 'Expected to date',
        value: formatMinutes(progress.expectedMinutes!),
        icon: Icons.trending_up_rounded,
        color: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
      ));
    } else if (progress.expectedDays != null) {
      items.add(_SummaryItem(
        label: 'Expected to date',
        value: '${progress.expectedDays} days',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
      ));
    }

    // 3. Remaining
    if (progress.minutesRemaining != null) {
      items.add(_SummaryItem(
        label: 'Remaining',
        value: formatMinutes(progress.minutesRemaining!),
        icon: Icons.hourglass_bottom_rounded,
        color: const Color(0xFF0284C7),
        bgColor: const Color(0xFFE0F2FE),
      ));
    } else if (progress.daysRemaining != null) {
      items.add(_SummaryItem(
        label: 'Remaining',
        value: '${progress.daysRemaining} days',
        icon: Icons.hourglass_bottom_rounded,
        color: const Color(0xFF0284C7),
        bgColor: const Color(0xFFE0F2FE),
      ));
    }

    // 4. Days left in year
    items.add(_SummaryItem(
      label: 'Days left in year',
      value: '${progress.daysRemainingInYear} days',
      icon: Icons.calendar_today_rounded,
      color: const Color(0xFFE11D48),
      bgColor: const Color(0xFFFFE4E6),
    ));

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  size: 16,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Overview',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: item.bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon,
                      size: 14,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
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

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Core subjects',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: ${formatMinutes(progress.totalCoreMinutes)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...progress.coreSubjectMinutes.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formatMinutes(entry.value),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubjectHoursChart(
    Map<Subject, int> minutesBySubject,
    ThemeData theme,
  ) {
    final entries = minutesBySubject.entries.toList();
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hours by subject',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
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
      );
    }

    // Sort descending by minutes logged
    entries.sort((a, b) => b.value.compareTo(a.value));
    final maxMinutes = entries.first.value > 0 ? entries.first.value : 1;

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hours by subject',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 14),
          ...entries.map((entry) {
            final subject = entry.key;
            final minutes = entry.value;
            final fraction = (minutes / maxMinutes).clamp(0.0, 1.0);

            final visual = KidsVisuals.getSubjectVisual(subject.name, isCore: subject.isCore);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: visual.bgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(visual.icon, size: 14, color: visual.color),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            subject.isCore ? '${subject.name} (Core)' : subject.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatMinutes(minutes),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: visual.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 10,
                      width: double.infinity,
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: fraction,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [visual.color, visual.badgeColor],
                            ),
                          ),
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
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.icon = Icons.insights_rounded,
    this.color = const Color(0xFF4F46E5),
    this.bgColor = const Color(0xFFEEF2FF),
  });
}
