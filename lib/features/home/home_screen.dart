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
import '../../app/kids_visuals.dart';

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
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.appName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                tooltip: 'Open settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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

                  // 1. Child selector / Active Child Header
                  if (children.length > 1) ...[
                    _buildChildSelector(context, ref, children, activeChild, theme),
                    const SizedBox(height: 18),
                  ] else ...[
                    _buildSingleChildHeader(context, activeChild, theme),
                    const SizedBox(height: 18),
                  ],

                  // 2. Status Card (On pace / Behind / Not started / Finished)
                  _buildStatusCard(context, ref, activeChild, theme),

                  const SizedBox(height: 16),

                  // 3. Today & Week Totals Row
                  _buildTotalsRow(ref, activeChild.id, theme),

                  const SizedBox(height: 20),

                  // 4. Primary "Log time" action button
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      key: const ValueKey('home_log_time_button'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 54),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                      label: Text(
                        'Log time',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
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

                  const SizedBox(height: 26),

                  // Recent activity feed
                  _buildRecentActivitySection(context, ref, activeChild.id, theme),

                  const SizedBox(height: 26),

                  // 5. Shortcuts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shortcuts',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutsGrid(context, ref, activeChild.id, theme),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSingleChildHeader(BuildContext context, Child child, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          KidsChildAvatar(
            childId: child.id,
            name: child.name,
            radius: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Homeschool Student',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/learning_adventure.jpg',
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      size: 44,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No child added yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your student to start logging daily learning time.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
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
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      child: Row(
        children: [
          KidsChildAvatar(
            childId: activeChild.id,
            name: activeChild.name,
            radius: 17,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: activeChild.id,
                isExpanded: true,
                icon: Icon(
                  Icons.unfold_more_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                items: children.map((c) {
                  return DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(
                      c.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
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
      loading: () => Container(
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Error: $err'),
      ),
      data: (state) {
        if (state == null) {
          return const SizedBox.shrink();
        }

        // Rule is missing: show clear message with button to choose a rule.
        if (state.isRuleMissing || state.progress == null) {
          return Container(
            key: const ValueKey('home_rule_missing_card'),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
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
                        fontWeight: FontWeight.w700,
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
                const SizedBox(height: 14),
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
          );
        }

        final progress = state.progress!;
        final recentLogs = ref.watch(childRecentLogsStreamProvider(child.id)).value ?? const [];
        final hasAnyLogs = recentLogs.isNotEmpty || progress.minutesDone > 0 || progress.daysLogged > 0;

        final int totalDays = progress.totalSchoolDays > 0 ? progress.totalSchoolDays : 300;
        final int elapsedDays = progress.elapsedSchoolDays.clamp(0, totalDays);
        final double benchmarkRatio = totalDays > 0 ? (elapsedDays / totalDays).clamp(0.0, 1.0) : 0.0;
        final int benchmarkPct = (benchmarkRatio * 100).round();

        final (statusColor, statusBg, statusIcon, statusEncouragement) = switch (progress.status) {
          ProgressStatus.onPace => (
            const Color(0xFF0F766E),
            const Color(0xFFCCFBF1),
            Icons.spa_rounded,
            '🌱 Cruising smoothly on pace!',
          ),
          ProgressStatus.finished => (
            const Color(0xFF0D9488),
            const Color(0xFFCCFBF1),
            Icons.emoji_events_rounded,
            '🏆 Goal accomplished! Outstanding!',
          ),
          ProgressStatus.behind => (
            const Color(0xFFD97706),
            const Color(0xFFFEF3C7),
            Icons.trending_up_rounded,
            '🌱 Flexible pace • Steady progress!',
          ),
          ProgressStatus.notStarted => (
            theme.colorScheme.onSurfaceVariant,
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            Icons.explore_rounded,
            '🚀 Ready for today\'s adventure!',
          ),
          ProgressStatus.invalidDates => (
            theme.colorScheme.error,
            theme.colorScheme.errorContainer,
            Icons.calendar_month_rounded,
            'Check school calendar dates',
          ),
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

        return Container(
          key: const ValueKey('home_status_card'),
          padding: const EdgeInsets.all(22.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (progress.metricRows.length > 1) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              progress.status == ProgressStatus.behind
                                  ? 'Flexible pace'
                                  : progress.status.label,
                              key: const ValueKey('home_overall_status_chip'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ] else if (progress.metricRows.isEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              progress.status.label,
                              key: const ValueKey('home_overall_status_chip'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
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
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentVal,
                  minHeight: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress.status == ProgressStatus.finished
                        ? const Color(0xFF0D9488)
                        : theme.colorScheme.primary,
                  ),
                ),
              ),

              // Diagrammatic Journey Pace Roadmap
              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(statusIcon, size: 16, color: statusColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  statusEncouragement,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (benchmarkPct > 0 && progress.status != ProgressStatus.finished)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Target: $benchmarkPct%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Visual milestone track
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 7,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Container(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            ),
                            if (benchmarkRatio > 0)
                              FractionallySizedBox(
                                widthFactor: benchmarkRatio,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDE68A).withValues(alpha: 0.45),
                                    border: const Border(
                                      right: BorderSide(color: Color(0xFFD97706), width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            FractionallySizedBox(
                              widthFactor: percentVal,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: progress.status == ProgressStatus.finished
                                        ? [const Color(0xFF0D9488), const Color(0xFF10B981)]
                                        : [theme.colorScheme.primary, const Color(0xFF2DD4BF)],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '🏁 Start',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (benchmarkRatio > 0.15 && benchmarkRatio < 0.85)
                          Flexible(
                            child: Text(
                              '📍 Calendar pace',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            '🏆 Goal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              if (progress.metricRows.isEmpty)
                Text(
                  progressSummary,
                  key: const ValueKey('home_progress_summary_text'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                )
              else
                for (final row in progress.metricRows) ...[
                  ProgressMetricRowWidget(row: row),
                  if (row != progress.metricRows.last) const SizedBox(height: 8),
                ],
              if (!hasAnyLogs) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFDE68A),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/celebration_star.jpg',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFD97706),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${child.name}!',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Welcome to ${child.name}\'s school year! Log your first lesson below to start tracking your hours and days.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFFB45309),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFFBEB),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFDE68A),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.wb_sunny_rounded,
                        size: 18,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TODAY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF92400E),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                todayAsync.when(
                  loading: () => const Text('...'),
                  error: (_, _) => const Text('0 min'),
                  data: (mins) => Text(
                    formatMinutes(mins),
                    key: const ValueKey('home_today_total_text'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: const Color(0xFF78350F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEEF2FF),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFC7D2FE),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        size: 18,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'THIS WEEK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF3730A3),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                weekAsync.when(
                  loading: () => const Text('...'),
                  error: (_, _) => const Text('0 min'),
                  data: (mins) => Text(
                    formatMinutes(mins),
                    key: const ValueKey('home_week_total_text'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: const Color(0xFF312E81),
                    ),
                  ),
                ),
              ],
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
                icon: Icons.auto_graph_rounded,
                iconColor: const Color(0xFF0F766E),
                iconBg: const Color(0xFFCCFBF1),
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
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFDBEAFE),
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
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
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
                icon: Icons.tune_rounded,
                iconColor: const Color(0xFF475569),
                iconBg: const Color(0xFFF1F5F9),
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
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
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
              return Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_toggle_off_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No lessons logged yet',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
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
              );
            }

            final subjectsMap = {
              for (final s in (subjectsAsync.value ?? <Subject>[])) s.id: s,
            };

            final displayLogs = logs.take(3).toList();

            return Card(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: displayLogs.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.colorScheme.outlineVariant,
                ),
                itemBuilder: (context, index) {
                  final entry = displayLogs[index];
                  final subject = subjectsMap[entry.subjectId];
                  final subjectName = subject?.name ?? 'Subject';
                  final visual = KidsVisuals.getSubjectVisual(
                    subjectName,
                    isCore: subject?.isCore ?? false,
                  );
                  final relativeDay = _formatRelativeDay(entry.day, clock);

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: visual.bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: visual.badgeColor, width: 1.2),
                      ),
                      child: Icon(
                        visual.icon,
                        color: visual.color,
                        size: 19,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subjectName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: visual.bgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: visual.badgeColor.withValues(alpha: 0.6),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            formatMinutes(entry.minutes),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: visual.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
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
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback? onPressed;
  final bool isLocked;

  const _ShortcutButton({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    this.onPressed,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? theme.colorScheme.surface
            : theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEnabled ? iconBg : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isEnabled ? iconColor : theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: isEnabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.lock_rounded,
                    size: 15,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),
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
        const Color(0xFFCCFBF1),
        const Color(0xFF0F766E),
      ),
      ProgressStatus.finished => (
        const Color(0xFFCCFBF1),
        const Color(0xFF0D9488),
      ),
      ProgressStatus.behind => (
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        theme.colorScheme.onSurfaceVariant,
      ),
      ProgressStatus.notStarted => (
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
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
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            row.status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: chipFg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
