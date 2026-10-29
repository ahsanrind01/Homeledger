import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/feature_policy.dart';
import '../children/add_child_screen.dart';
import '../debug/debug_entitlement_screen.dart';
import '../export/export_options_screen.dart';
import '../paywall/paywall_screen.dart';
import '../subjects/subjects_screen.dart';
import 'privacy_policy_screen.dart';

/// Settings screen allowing management of children, subjects, backup/restore,
/// about info, and legal disclaimer.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  Future<void> _createBackup() async {
    setState(() {
      _isBackingUp = true;
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      await backupService.createBackup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created and ready to save or share.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Backup failed. Please try again or check available storage.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    final backupService = ref.read(backupServiceProvider);

    setState(() {
      _isRestoring = true;
    });

    try {
      final summary = await backupService.pickAndValidateBackup();
      if (summary == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _isRestoring = false;
      });

      final theme = Theme.of(context);
      final manifest = summary.manifest;
      DateTime? createdDate;
      try {
        createdDate = DateTime.parse(manifest.createdAt);
      } catch (_) {}
      final createdDisplay = createdDate != null
          ? formatDisplayDate(createdDate)
          : manifest.createdAt;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Restore from backup?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This replaces all data on this phone.',
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Backup date: $createdDisplay'),
                  const SizedBox(height: 6),
                  Text('Students: ${manifest.counts.children}'),
                  Text('Log entries: ${manifest.counts.entries}'),
                  Text('Work samples: ${manifest.counts.samples}'),
                  if (summary.missingSamplePaths.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Notice: ${summary.missingSamplePaths.length} sample file(s) could not be found in the backup archive. The records will still be restored.',
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Restore'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        if (mounted) {
          setState(() {
            _isRestoring = true;
          });
        }
        try {
          await backupService.performRestore(summary);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Restore completed successfully.')),
            );
          }
        } finally {
          ref.invalidate(appDatabaseProvider);
          ref.invalidate(childrenStreamProvider);
          ref.invalidate(selectedChildIdProvider);
          ref.invalidate(lastBackupDateStreamProvider);
          ref.invalidate(shouldShowBackupReminderProvider);
          ref.invalidate(subjectsStreamProvider);

          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final userMessage = e.toString().contains('FormatException')
            ? 'Invalid backup file. Please select a valid Homeledger backup.'
            : 'Restore failed. The file may be corrupted or incompatible.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  Future<void> _confirmAndDeleteChild(Child child) async {
    final logRepo = ref.read(logRepositoryProvider);
    final sampleRepo = ref.read(sampleRepositoryProvider);

    final entryCount = await logRepo.countForChild(child.id);
    final sampleCount = await sampleRepo.countForChild(child.id);

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${child.name}?'),
          content: Text(
            'This will delete $entryCount log ${entryCount == 1 ? "entry" : "entries"} and '
            '$sampleCount work ${sampleCount == 1 ? "sample" : "samples"} for ${child.name}. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(childDeletionServiceProvider).deleteChild(child.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${child.name} deleted')),
        );
      }
    }
  }

  Future<void> _editParentName(String? currentName) async {
    final controller = TextEditingController(text: currentName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Parent name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Optional. If set, this name appears on exported portfolio cover pages.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Parent / Educator name',
                  hintText: 'e.g. Jane Doe',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (currentName != null && currentName.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.of(context).pop(''),
                child: const Text('Clear'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName != null) {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.setParentName(newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final childRepo = ref.watch(childRepositoryProvider);
    final lastBackupAsync = ref.watch(lastBackupDateStreamProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Parent Name (Optional) Section
            StreamBuilder<String?>(
              stream: ref.watch(settingsRepositoryProvider).watchParentName(),
              builder: (context, snapshot) {
                final parentName = snapshot.data;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Parent name (optional)'),
                  subtitle: Text(
                    parentName != null && parentName.isNotEmpty
                        ? parentName
                        : 'Not set (tap to add for portfolio cover)',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editParentName(parentName),
                );
              },
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Children Section
            Builder(
              builder: (context) {
                final childrenAsync = ref.watch(childrenStreamProvider);
                final childrenCount = childrenAsync.value?.length ?? 0;
                final secondChildAccess =
                    ref.watch(featureAccessProvider(Feature.secondChild));
                final isSecondChildLocked =
                    childrenCount >= 1 && secondChildAccess.isLocked;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Children',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(isSecondChildLocked ? Icons.lock_outline : Icons.add),
                      label: Text(isSecondChildLocked ? 'Add child (Plus)' : 'Add child'),
                      onPressed: () {
                        if (isSecondChildLocked) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const PaywallScreen(),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AddChildScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),

            StreamBuilder<List<Child>>(
              stream: childRepo.watchAll(),
              builder: (context, snapshot) {
                final children = snapshot.data ?? [];
                if (children.isEmpty) {
                  return Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No children added yet.'),
                    ),
                  );
                }

                return Column(
                  children: children.map((child) {
                    // Format school year dates for display
                    final startParsed = DateTime.tryParse(child.schoolYearStart);
                    final endParsed = DateTime.tryParse(child.schoolYearEnd);
                    final startDisplay = startParsed != null
                        ? formatDisplayDate(startParsed)
                        : child.schoolYearStart;
                    final endDisplay = endParsed != null
                        ? formatDisplayDate(endParsed)
                        : child.schoolYearEnd;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          child.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'School year: $startDisplay – $endDisplay',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit child',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => AddChildScreen(
                                      initialChild: child,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete child',
                              onPressed: () => _confirmAndDeleteChild(child),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Subjects Navigation
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Subjects'),
              subtitle: const Text('Manage learning subjects and curriculum'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SubjectsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 4),

            // Export Portfolio Shortcut
            Builder(
              builder: (context) {
                final childrenAsync = ref.watch(childrenStreamProvider);
                final exportAccess = ref.watch(featureAccessProvider(Feature.exportPdf));
                final children = childrenAsync.value ?? [];
                final hasChildren = children.isNotEmpty;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('Export portfolio'),
                  subtitle: Text(
                    exportAccess.isLocked
                        ? 'PDF export (Plus)'
                        : 'Generate and share PDF report',
                  ),
                  trailing: Icon(
                    exportAccess.isLocked ? Icons.lock_outline : Icons.chevron_right,
                  ),
                  onTap: hasChildren
                      ? () {
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
                                  initialChildId: children.first.id,
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                );
              },
            ),

            const Divider(),
            const SizedBox(height: 8),

            // Backup & Restore Section (Free plan - never locked)
            Text(
              'Backup & restore',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Back up now tile
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Back up now'),
              subtitle: Text(
                lastBackupAsync.when(
                  data: (date) {
                    if (date == null || date.isEmpty) {
                      return 'Last backup: Never';
                    }
                    final parsed = DateTime.tryParse(date);
                    final formatted = parsed != null ? formatDisplayDate(parsed) : date;
                    return 'Last backup: $formatted';
                  },
                  loading: () => 'Last backup: Checking...',
                  error: (_, _) => 'Last backup: Never',
                ),
              ),
              trailing: _isBackingUp
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.share_outlined),
              onTap: (_isBackingUp || _isRestoring) ? null : _createBackup,
            ),

            // Restore from backup tile
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore_outlined),
              title: const Text('Restore from backup'),
              subtitle: const Text('This replaces all data on this phone.'),
              trailing: _isRestoring
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: (_isBackingUp || _isRestoring) ? null : _restoreBackup,
            ),

            const Divider(),
            const SizedBox(height: 8),

            // About Section — dynamic version from package_info_plus
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '...';
                final buildNumber = snapshot.data?.buildNumber ?? '';
                final versionText = buildNumber.isNotEmpty
                    ? 'Version $version ($buildNumber)'
                    : 'Version $version';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Homeledger'),
                  subtitle: Text(versionText),
                );
              },
            ),

            const Divider(),
            const SizedBox(height: 8),

            // Privacy Policy
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),

            const Divider(),
            const SizedBox(height: 8),

            // Send Feedback
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.rate_review_outlined),
              title: const Text('Send feedback'),
              subtitle: const Text('Help us improve Homeledger'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    final feedbackController = TextEditingController();
                    return AlertDialog(
                      title: const Text('Send feedback'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'We\'d love to hear from you! Tell us what you like, what could be better, or report a bug.',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: feedbackController,
                            maxLines: 4,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Your feedback...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Thank you for your feedback!')),
                            );
                          },
                          child: const Text('Send'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const Divider(),
            const SizedBox(height: 16),

            // Disclaimer Section
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legal disclaimer',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.fullDisclaimer,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (kDebugMode) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Developer: Subscription debug'),
                subtitle: const Text('Simulate free, paid, grace, and expired states'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DebugEntitlementScreen(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
