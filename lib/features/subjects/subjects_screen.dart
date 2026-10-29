import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';

/// Screen for managing learning subjects (add, rename, toggle core, reorder, delete).
class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  Future<void> _showAddSubjectDialog(int nextSortOrder) async {
    final nameController = TextEditingController();
    bool isCore = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add subject'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    maxLength: 40,
                    decoration: InputDecoration(
                      labelText: 'Subject name',
                      hintText: 'e.g. Geography',
                      errorText: dialogError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Core subject'),
                    value: isCore,
                    onChanged: (val) {
                      setDialogState(() {
                        isCore = val ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final trimmedName = nameController.text.trim();
                    if (trimmedName.isEmpty) {
                      setDialogState(() {
                        dialogError = 'Name is required';
                      });
                      return;
                    }

                    try {
                      await ref.read(subjectRepositoryProvider).add(
                            SubjectsCompanion.insert(
                              name: trimmedName,
                              isCore: drift.Value(isCore),
                              sortOrder: drift.Value(nextSortOrder),
                            ),
                          );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      setDialogState(() {
                        dialogError = 'A subject with this name already exists';
                      });
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditSubjectDialog(Subject subject) async {
    final nameController = TextEditingController(text: subject.name);
    bool isCore = subject.isCore;
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit subject'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    maxLength: 40,
                    decoration: InputDecoration(
                      labelText: 'Subject name',
                      errorText: dialogError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Core subject'),
                    value: isCore,
                    onChanged: (val) {
                      setDialogState(() {
                        isCore = val ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final trimmedName = nameController.text.trim();
                    if (trimmedName.isEmpty) {
                      setDialogState(() {
                        dialogError = 'Name is required';
                      });
                      return;
                    }

                    try {
                      await ref.read(subjectRepositoryProvider).update(
                            subject.copyWith(
                              name: trimmedName,
                              isCore: isCore,
                            ),
                          );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      setDialogState(() {
                        dialogError = 'A subject with this name already exists';
                      });
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleDeleteSubject(Subject subject) async {
    final subjectRepo = ref.read(subjectRepositoryProvider);
    final sampleRepo = ref.read(sampleRepositoryProvider);
    final storageService = ref.read(sampleStorageServiceProvider);

    final entryCount = await subjectRepo.countLogEntriesForSubject(subject.id);
    final sampleCount = await sampleRepo.countForSubject(subject.id);

    if (!mounted) return;

    final String dialogContent;
    if (entryCount == 0 && sampleCount == 0) {
      dialogContent = 'Are you sure you want to delete this subject?';
    } else {
      final entriesText = '$entryCount time ${entryCount == 1 ? "entry" : "entries"}';
      final samplesText = '$sampleCount work ${sampleCount == 1 ? "sample" : "samples"}';
      dialogContent =
          'This will delete $entriesText and $samplesText for ${subject.name}. '
          'Work samples and their image files will be permanently deleted. This cannot be undone.';
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${subject.name}?'),
          content: Text(dialogContent),
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

    if (confirm == true) {
      final filePaths = await subjectRepo.deleteSubjectCascade(subject.id);
      for (final path in filePaths) {
        try {
          final file = await storageService.resolveFile(path);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (_) {}
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectRepo = ref.watch(subjectRepositoryProvider);
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add subject',
            onPressed: () async {
              final subjects = await subjectRepo.getAll();
              if (context.mounted) {
                _showAddSubjectDialog(subjects.length);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: subjectsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (subjects) {
            if (subjects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No subjects yet',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => _showAddSubjectDialog(0),
                      child: const Text('Add subject'),
                    ),
                  ],
                ),
              );
            }

            return ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: subjects.length,
              onReorderItem: (oldIndex, newIndex) async {
                final list = List<Subject>.from(subjects);
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                await subjectRepo.reorder(list);
              },
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return ListTile(
                  key: ValueKey(subject.id),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          subject.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (subject.isCore)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Core',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit subject',
                        onPressed: () => _showEditSubjectDialog(subject),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete subject',
                        onPressed: () => _handleDeleteSubject(subject),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

