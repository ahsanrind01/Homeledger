import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/progress_calculator.dart';
import '../children/add_child_screen.dart';
import '../log/log_screen.dart';
import '../progress/progress_screen.dart';
import '../samples/sample_library_screen.dart';
import '../settings/settings_screen.dart';
import '../export/export_options_screen.dart';
import '../backup/backup_reminder_card.dart';
import '../paywall/paywall_screen.dart';
import '../../domain/feature_policy.dart';

/// The primary Home screen dashboard for daily logging, status, and shortcuts.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final childrenAsync = ref.watch(childrenStreamProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Open settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: childrenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading data: $err')),
          data: (children) {
            if (children.isEmpty) {
              return _buildEmptyState(context, theme);
            }

            final selectedChildId = ref.watch(selectedChildIdProvider);
            final activeChild = children.firstWhere(
              (c) => c.id == selectedChildId,
              orElse: () => children.first,
            );

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gentle 30-day backup reminder (if needed)
                  Consumer(
                    builder: (context, ref, _) {
                      final showReminder = ref.watch(shouldShowBackupReminderProvider).value ?? false;
                      if (!showReminder) return const SizedBox.shrink();
                      return BackupReminderCard(
                        onBackupNow: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // 1. Child selector (only visible when more than one child exists)
                  if (children.length > 1) ...[
                    _buildChildSelector(context, ref, children, activeChild, theme),
                    const SizedBox(height: 16),
                  ] else ...[
                    Text(
                      activeChild.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 2. Status Card (On pace / Behind / Not started / Finished)
                  _buildStatusCard(context, ref, activeChild, theme),

                  const SizedBox(height: 16),

                  // 3. Today & Week Totals Row
                  _buildTotalsRow(ref, activeChild.id, theme),

                  const SizedBox(height: 20),

                  // 4. Big "Log time" button
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      key: const ValueKey('home_log_time_button'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      label: Text(
                        'Log time',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LogScreen(childId: activeChild.id),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent activity feed
                  _buildRecentActivitySection(context, ref, activeChild.id, theme),

                  const SizedBox(height: 24),

                  // 5. Shortcuts: Progress, Samples (disabled), Export (disabled), Settings
                  Text(
                    'Shortcuts',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutsGrid(context, ref, activeChild.id, theme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No child added yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your student to start logging daily learning time.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add child'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddChildScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildSelector(
    BuildContext context,
    WidgetRef ref,
    List<Child> children,
    Child activeChild,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(
              Icons.person,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: activeChild.id,
                  isExpanded: true,
                  items: children.map((c) {
                    return DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(
                        c.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newId) {
                    if (newId != null) {
                      ref.read(selectedChildIdProvider.notifier).select(newId);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    WidgetRef ref,
    Child child,
    ThemeData theme,
  ) {
    final progressAsync = ref.watch(childProgressProvider(child.id));

    return progressAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $err'),
        ),
      ),
      data: (state) {
        if (state == null) {
          return const SizedBox.shrink();
        }

        // Rule is missing: show clear message with button to choose a rule. Never crash.
        if (state.isRuleMissing || state.progress == null) {
          return Card(
            key: const ValueKey('home_rule_missing_card'),
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rule missing',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No state rule profile could be found for ${child.name}. Please choose or create a rule to view progress.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('home_choose_rule_button'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AddChildScreen(initialChild: child),
                        ),
                      );
                    },
                    child: const Text('Choose a rule'),
                  ),
                ],
              ),
            ),
          );
        }

        final progress = state.progress!;
        final recentLogs = ref.watch(childRecentLogsStreamProvider(child.id)).value ?? const [];
        final hasAnyLogs = recentLogs.isNotEmpty || progress.minutesDone > 0 || progress.daysLogged > 0;

        final statusColor = switch (progress.status) {
          ProgressStatus.onPace => Colors.green.shade700,
          ProgressStatus.finished => Colors.teal.shade700,
          ProgressStatus.behind => theme.colorScheme.onSurfaceVariant,
          ProgressStatus.notStarted => theme.colorScheme.outline,
          ProgressStatus.invalidDates => theme.colorScheme.error,
        };
        final statusBg = switch (progress.status) {
          ProgressStatus.onPace => Colors.green.withValues(alpha: 0.12),
          ProgressStatus.finished => Colors.teal.withValues(alpha: 0.12),
          ProgressStatus.behind => theme.colorScheme.surfaceContainerHighest,
          ProgressStatus.notStarted => theme.colorScheme.surfaceContainerHighest,
          ProgressStatus.invalidDates => theme.colorScheme.errorContainer,
        };

        final percentStr = progress.percentOfRequirement != null
            ? '${progress.percentOfRequirement!.toStringAsFixed(0)}%'
            : progress.percentOfDaysRequirement != null
                ? '${progress.percentOfDaysRequirement!.toStringAsFixed(0)}%'
                : '0%';

        final percentVal = ((progress.percentOfRequirement ?? progress.percentOfDaysRequirement ?? 0.0) / 100.0).clamp(0.0, 1.0);

        final progressSummary = formatProgressSummary(
          minutesDone: progress.minutesDone,
          requiredMinutes: progress.requiredMinutes,
          daysLogged: progress.daysLogged,
          requiredDays: progress.requiredDays,
        );

        return Card(
          key: const ValueKey('home_status_card'),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'School Year Progress',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (progress.metricRows.length > 1) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                progress.status == ProgressStatus.behind
                                    ? 'Flexible pace'
                                    : progress.status.label,
                                key: const ValueKey('home_overall_status_chip'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else if (progress.metricRows.isEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                progress.status.label,
                                key: const ValueKey('home_overall_status_chip'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      percentStr,
                      key: const ValueKey('home_percentage_text'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percentVal,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress.status == ProgressStatus.finished
                          ? Colors.teal
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (progress.metricRows.isEmpty)
                  Text(
                    progressSummary,
                    key: const ValueKey('home_progress_summary_text'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  for (final row in progress.metricRows) ...[
                    ProgressMetricRowWidget(row: row),
                    if (row != progress.metricRows.last) const SizedBox(height: 8),
                  ],
                if (!hasAnyLogs) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Welcome to ${child.name}\'s school year! Log your first lesson below to start tracking your hours and days.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalsRow(WidgetRef ref, int childId, ThemeData theme) {
    final todayAsync = ref.watch(todayMinutesProvider(childId));
    final weekAsync = ref.watch(weekMinutesProvider(childId));

    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 0,
            color:
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  todayAsync.when(
                    loading: () => const Text('...'),
                    error: (_, _) => const Text('0 min'),
                    data: (mins) => Text(
                      formatMinutes(mins),
                      key: const ValueKey('home_today_total_text'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 0,
            color:
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This week',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  weekAsync.when(
                    loading: () => const Text('...'),
                    error: (_, _) => const Text('0 min'),
                    data: (mins) => Text(
                      formatMinutes(mins),
                      key: const ValueKey('home_week_total_text'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutsGrid(
    BuildContext context,
    WidgetRef ref,
    int childId,
    ThemeData theme,
  ) {
    final exportAccess = ref.watch(featureAccessProvider(Feature.exportPdf));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ShortcutButton(
                key: const ValueKey('shortcut_progress'),
                icon: Icons.bar_chart,
                label: 'Progress',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProgressScreen(childId: childId),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ShortcutButton(
                key: const ValueKey('shortcut_samples'),
                icon: Icons.photo_library_outlined,
                label: 'Samples',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SampleLibraryScreen(childId: childId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ShortcutButton(
                key: const ValueKey('shortcut_export'),
                icon: Icons.picture_as_pdf_outlined,
                label: 'Export',
                isLocked: exportAccess.isLocked,
                onPressed: () {
                  if (exportAccess.isLocked) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PaywallScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ExportOptionsScreen(
                          initialChildId: childId,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ShortcutButton(
                key: const ValueKey('shortcut_settings'),
                icon: Icons.settings_outlined,
                label: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(
    BuildContext context,
    WidgetRef ref,
    int childId,
    ThemeData theme,
  ) {
    final recentLogsAsync = ref.watch(childRecentLogsStreamProvider(childId));
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final clock = ref.watch(clockProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent activity',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProgressScreen(childId: childId),
                  ),
                );
              },
              child: const Text('View progress'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        recentLogsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Text('Error loading activity: $err'),
          data: (logs) {
            if (logs.isEmpty) {
              return Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No lessons logged yet',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lessons you record will appear here for quick daily review.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final subjectsMap = {
              for (final s in (subjectsAsync.value ?? <Subject>[])) s.id: s,
            };

            final displayLogs = logs.take(3).toList();

            return Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: displayLogs.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final entry = displayLogs[index];
                  final subject = subjectsMap[entry.subjectId];
                  final subjectName = subject?.name ?? 'Subject';
                  final relativeDay = _formatRelativeDay(entry.day, clock);

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      radius: 16,
                      child: Text(
                        subjectName.isNotEmpty ? subjectName[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subjectName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatMinutes(entry.minutes),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (entry.note != null && entry.note!.trim().isNotEmpty)
                          Expanded(
                            child: Text(
                              entry.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          Text(
                            subject?.isCore == true ? 'Core subject' : 'Elective',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          relativeDay,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      DateTime? parsedDay;
                      try {
                        parsedDay = DateTime.parse(entry.day);
                      } catch (_) {}
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LogScreen(
                            childId: childId,
                            initialDate: parsedDay,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatRelativeDay(String dayStr, DateTime today) {
    try {
      final dayDate = DateTime.parse(dayStr);
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final dayMidnight = DateTime(dayDate.year, dayDate.month, dayDate.day);
      final diff = todayMidnight.difference(dayMidnight).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return DateFormat('MMM d').format(dayDate);
    } catch (_) {
      return dayStr;
    }
  }
}

class _ShortcutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLocked;

  const _ShortcutButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    return Card(
      elevation: 0,
      color: isEnabled
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isEnabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A single row showing a progress requirement metric and its individual status chip.
class ProgressMetricRowWidget extends StatelessWidget {
  final ProgressMetricRow row;

  const ProgressMetricRowWidget({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (chipBg, chipFg) = switch (row.status) {
      ProgressStatus.onPace => (
        Colors.green.withValues(alpha: 0.12),
        Colors.green.shade800,
      ),
      ProgressStatus.finished => (
        Colors.teal.withValues(alpha: 0.12),
        Colors.teal.shade800,
      ),
      ProgressStatus.behind => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
      ProgressStatus.notStarted => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.outline,
      ),
      ProgressStatus.invalidDates => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
      ),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            row.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            row.status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: chipFg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

