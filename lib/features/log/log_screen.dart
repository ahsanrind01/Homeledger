import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/log_validator.dart';
import '../subjects/subjects_screen.dart';

/// Screen to log daily learning time for a specific child and date.
class LogScreen extends ConsumerStatefulWidget {
  final int childId;
  final DateTime? initialDate;
  final int? initialSubjectId;

  const LogScreen({
    super.key,
    required this.childId,
    this.initialDate,
    this.initialSubjectId,
  });

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  late DateTime _selectedDate;
  int? _selectedSubjectId;

  final TextEditingController _customMinutesController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _customMinutesFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Default date to today via clockProvider
    final clock = ref.read(clockProvider);
    _selectedDate = widget.initialDate ?? clock;
    _loadLastUsedSubject();
  }

  @override
  void dispose() {
    _customMinutesController.dispose();
    _noteController.dispose();
    _customMinutesFocus.dispose();
    super.dispose();
  }

  Future<void> _loadLastUsedSubject() async {
    if (widget.initialSubjectId != null) {
      if (mounted) {
        setState(() {
          _selectedSubjectId = widget.initialSubjectId;
        });
      }
      return;
    }
    final lastId = await ref
        .read(settingsRepositoryProvider)
        .getLastUsedSubjectId(widget.childId);
    if (mounted && lastId != null) {
      setState(() {
        _selectedSubjectId = lastId;
      });
    }
  }

  Future<void> _pickDate(DateTime today) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? today : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: today, // Future dates blocked
      helpText: 'Select log date',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showAddCustomSubjectDialog(
    BuildContext context,
    List<Subject> existingSubjects,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final chosenName = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Add Custom Subject'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter a subject or activity name (e.g. Spanish, Nature Study, Robotics, Coding):',
                  style: Theme.of(dialogCtx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    hintText: 'e.g. Piano, Foreign Language',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject name';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(dialogCtx).pop(controller.text.trim());
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogCtx).pop(controller.text.trim());
                }
              },
              child: const Text('Add & Select'),
            ),
          ],
        );
      },
    );

    if (chosenName == null || chosenName.isEmpty) return;

    final existing = existingSubjects.firstWhere(
      (s) => s.name.trim().toLowerCase() == chosenName.toLowerCase(),
      orElse: () => const Subject(id: -1, name: '', isCore: false, sortOrder: 0),
    );

    int targetId;
    if (existing.id != -1) {
      targetId = existing.id;
    } else {
      final subjectRepo = ref.read(subjectRepositoryProvider);
      targetId = await subjectRepo.add(
        SubjectsCompanion.insert(
          name: chosenName,
          isCore: const drift.Value(false),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _selectedSubjectId = targetId;
      });
      ref.read(settingsRepositoryProvider).setLastUsedSubjectId(widget.childId, targetId);
    }
  }

  Future<void> _submitEntry({
    required int minutes,
    required int currentDayMinutes,
    required List<Subject> subjects,
  }) async {
    if (_selectedSubjectId == null) {
      _showFloatingFeedback(
        message: 'Please select a subject first.',
        icon: Icons.info_outline_rounded,
        iconColor: const Color(0xFFF59E0B),
      );
      return;
    }

    final clock = ref.read(clockProvider);
    final noteText = _noteController.text.trim();

    final validation = LogValidator.validate(
      minutesToAdd: minutes,
      currentDayMinutes: currentDayMinutes,
      date: _selectedDate,
      today: clock,
      note: noteText.isEmpty ? null : noteText,
    );

    if (validation.isBlocked) {
      _showFloatingFeedback(
        message: validation.message ?? 'Cannot log entry.',
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFEF4444),
      );
      return;
    }

    if (validation.isWarn) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Long daily time'),
          content: Text(
            validation.message ??
                'Total daily learning time will exceed 10 hours. Do you want to log this anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Log anyway'),
            ),
          ],
        ),
      );
      if (shouldProceed != true) return;
    }

    final logRepo = ref.read(logRepositoryProvider);
    final selectedSubject =
        subjects.firstWhere((s) => s.id == _selectedSubjectId);

    await logRepo.add(
      LogEntriesCompanion.insert(
        childId: widget.childId,
        subjectId: _selectedSubjectId!,
        day: formatIsoDate(_selectedDate),
        minutes: minutes,
        note: noteText.isEmpty
            ? const drift.Value.absent()
            : drift.Value(noteText),
        createdAt: clock.millisecondsSinceEpoch,
      ),
    );

    // Clear text controllers
    _customMinutesController.clear();
    _noteController.clear();
    _customMinutesFocus.unfocus();

    HapticFeedback.lightImpact();

    _showFloatingFeedback(
      message: 'Added $minutes min of ${selectedSubject.name}.',
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF10B981),
    );
  }

  void _showFloatingFeedback({
    required String message,
    IconData icon = Icons.check_circle_rounded,
    Color? iconColor,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(milliseconds: 2200),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF10B981)).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? const Color(0xFF10B981),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editEntry({
    required LogEntry entry,
    required List<Subject> subjects,
    required int dayTotalExcludingEntry,
  }) async {
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (ctx) => _EditEntryDialog(
        entry: entry,
        subjects: subjects,
        selectedDate: _selectedDate,
        dayTotalExcludingEntry: dayTotalExcludingEntry,
      ),
    );

    if (result != null && mounted) {
      await ref.read(logRepositoryProvider).update(
            entry.copyWith(
              subjectId: result.subjectId,
              minutes: result.minutes,
              note: drift.Value(result.note),
            ),
          );

      if (mounted) {
        _showFloatingFeedback(
          message: 'Entry updated.',
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF10B981),
        );
      }
    }
  }

  Future<void> _deleteEntry(LogEntry entry, String subjectName) async {
    final logRepo = ref.read(logRepositoryProvider);

    await logRepo.delete(entry.id);

    HapticFeedback.lightImpact();

    _showFloatingFeedback(
      message: 'Removed ${entry.minutes} min of $subjectName.',
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFF94A3B8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clock = ref.watch(clockProvider);
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final dayStr = formatIsoDate(_selectedDate);
    final dayEntriesStream =
        ref.watch(logRepositoryProvider).watchForDay(widget.childId, dayStr);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Log time'),
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading subjects: $err')),
        data: (subjects) {
          if (subjects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You have no subjects yet. Add one to start logging.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints:
                          const BoxConstraints(minHeight: 48, minWidth: 48),
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SubjectsScreen(),
                            ),
                          );
                        },
                        child: const Text('Add subject'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Ensure selected subject is valid
          if (_selectedSubjectId == null ||
              !subjects.any((s) => s.id == _selectedSubjectId)) {
            _selectedSubjectId = subjects.first.id;
          }

          final subjectMap = {for (final s in subjects) s.id: s};

          return StreamBuilder<List<LogEntry>>(
            stream: dayEntriesStream,
            builder: (context, snapshot) {
              final entries = snapshot.data ?? [];
              final currentDayMinutes =
                  entries.fold<int>(0, (sum, e) => sum + e.minutes);

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- Date Row ---
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DATE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dayStr == formatIsoDate(clock)
                                    ? '$dayStr (Today)'
                                    : dayStr,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                          label: const Text('Change date'),
                          onPressed: () => _pickDate(clock),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // --- Subject Selection Chips ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subject',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: const Text('Manage subjects'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SubjectsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      const popularSubjects = [
                        'Math',
                        'Reading',
                        'Writing',
                        'Science',
                        'History',
                        'Art',
                        'Music',
                        'PE',
                      ];

                      final existingByName = {
                        for (final s in subjects) s.name.trim().toLowerCase(): s,
                      };

                      final unaddedPopular = popularSubjects
                          .where((p) => !existingByName.containsKey(p.toLowerCase()))
                          .toList();

                      return Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          ...subjects.map((subject) {
                            final isSelected = subject.id == _selectedSubjectId;
                            return ChoiceChip(
                              key: ValueKey('subject_chip_${subject.id}'),
                              label: Text(
                                subject.isCore ? '${subject.name} (Core)' : subject.name,
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedSubjectId = subject.id;
                                  });
                                  ref
                                      .read(settingsRepositoryProvider)
                                      .setLastUsedSubjectId(widget.childId, subject.id);
                                }
                              },
                            );
                          }),
                          ...unaddedPopular.map((popName) {
                            return ActionChip(
                              avatar: const Icon(Icons.add, size: 16),
                              label: Text(popName),
                              onPressed: () async {
                                final subjectRepo = ref.read(subjectRepositoryProvider);
                                final newId = await subjectRepo.add(
                                  SubjectsCompanion.insert(
                                    name: popName,
                                    isCore: const drift.Value(false),
                                  ),
                                );
                                if (mounted) {
                                  setState(() {
                                    _selectedSubjectId = newId;
                                  });
                                  ref
                                      .read(settingsRepositoryProvider)
                                      .setLastUsedSubjectId(widget.childId, newId);
                                }
                              },
                            );
                          }),
                          ActionChip(
                            avatar: Icon(Icons.edit_note, size: 18, color: theme.colorScheme.primary),
                            label: Text(
                              '+ Custom subject',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                            onPressed: () => _showAddCustomSubjectDialog(context, subjects),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- Duration (Quick Select & Custom Minutes) ---
                  Text(
                    'Duration',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [15, 30, 45, 60, 90].map((mins) {
                      final currentMins = int.tryParse(_customMinutesController.text.trim());
                      final isSelected = currentMins == mins;
                      return ChoiceChip(
                        key: ValueKey('quick_add_$mins'),
                        label: Text('+$mins min'),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _customMinutesController.text = '$mins';
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    key: const ValueKey('custom_minutes_input'),
                    controller: _customMinutesController,
                    focusNode: _customMinutesFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      hintText: 'e.g. 45 or 60',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    key: const ValueKey('note_input'),
                    controller: _noteController,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional, max 200 characters)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      key: const ValueKey('custom_add_button'),
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Add lesson',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        final mins = int.tryParse(
                              _customMinutesController.text.trim(),
                            ) ??
                            0;
                        _submitEntry(
                          minutes: mins,
                          currentDayMinutes: currentDayMinutes,
                          subjects: subjects,
                        );
                      },
                    ),
                  ),

                  const Divider(height: 36),

                  // --- Entries for this Day ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Entries for $dayStr',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total: ${formatMinutes(currentDayMinutes)}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No entries logged for this date.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...entries.map((entry) {
                      final subject = subjectMap[entry.subjectId];
                      final subjectName = subject?.name ?? 'Unknown Subject';

                      return Container(
                        key: ValueKey('entry_card_${entry.id}'),
                        margin: const EdgeInsets.only(bottom: 10.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6.0,
                          ),
                          leading: CircleAvatar(
                            radius: 17,
                            backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                            foregroundColor: theme.colorScheme.primary,
                            child: Text(
                              subjectName.isNotEmpty ? subjectName[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                subjectName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              if (subject?.isCore == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Core',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  formatMinutes(entry.minutes),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: entry.note != null && entry.note!.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    entry.note!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 19),
                                tooltip: 'Edit entry',
                                onPressed: () => _editEntry(
                                  entry: entry,
                                  subjects: subjects,
                                  dayTotalExcludingEntry:
                                      currentDayMinutes - entry.minutes,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 19),
                                tooltip: 'Delete entry',
                                onPressed: () =>
                                    _deleteEntry(entry, subjectName),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _EditResult {
  final int subjectId;
  final int minutes;
  final String? note;

  const _EditResult({
    required this.subjectId,
    required this.minutes,
    this.note,
  });
}

class _EditEntryDialog extends ConsumerStatefulWidget {
  final LogEntry entry;
  final List<Subject> subjects;
  final DateTime selectedDate;
  final int dayTotalExcludingEntry;

  const _EditEntryDialog({
    required this.entry,
    required this.subjects,
    required this.selectedDate,
    required this.dayTotalExcludingEntry,
  });

  @override
  ConsumerState<_EditEntryDialog> createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends ConsumerState<_EditEntryDialog> {
  late final TextEditingController _minutesController;
  late final TextEditingController _noteController;
  late int _subjectId;

  @override
  void initState() {
    super.initState();
    _minutesController =
        TextEditingController(text: widget.entry.minutes.toString());
    _noteController = TextEditingController(text: widget.entry.note ?? '');
    _subjectId = widget.entry.subjectId;
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit log entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Subject:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _subjectId,
              isExpanded: true,
              items: widget.subjects.map((s) {
                return DropdownMenuItem<int>(
                  value: s.id,
                  child: Text(s.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _subjectId = val);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Minutes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final mins = int.tryParse(_minutesController.text.trim()) ?? 0;
            final note = _noteController.text.trim();
            final clock = ref.read(clockProvider);

            final validation = LogValidator.validate(
              minutesToAdd: mins,
              currentDayMinutes: widget.dayTotalExcludingEntry,
              date: widget.selectedDate,
              today: clock,
              note: note.isEmpty ? null : note,
            );

            if (validation.isBlocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(validation.message ?? 'Invalid entry.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
              return;
            }

            Navigator.of(context).pop(
              _EditResult(
                subjectId: _subjectId,
                minutes: mins,
                note: note.isEmpty ? null : note,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
