import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/providers.dart';

/// Gentle dismissible reminder banner shown on the home dashboard when
/// it has been more than 30 days since the last backup.
class BackupReminderCard extends ConsumerWidget {
  final VoidCallback onBackupNow;

  const BackupReminderCard({
    super.key,
    required this.onBackupNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.backup_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Backup recommended',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'It has been over 30 days without a backup. Homeledger stores data only on this phone. Create a backup to keep your records safe.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    final now = ref.read(clockProvider);
                    final settingsRepo = ref.read(settingsRepositoryProvider);
                    await settingsRepo.dismissBackupReminder(formatIsoDate(now));
                    ref.invalidate(shouldShowBackupReminderProvider);
                  },
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: onBackupNow,
                  child: const Text('Back up now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
