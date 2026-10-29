import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/rule_profile.dart';
import '../../domain/feature_policy.dart';
import '../home/home_screen.dart';
import '../paywall/paywall_screen.dart';

/// Screen for adding or editing a child profile.
class AddChildScreen extends ConsumerStatefulWidget {
  final Child? initialChild;
  final bool isFirstChild;

  const AddChildScreen({
    super.key,
    this.initialChild,
    this.isFirstChild = false,
  });

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;

  String? _selectedRuleId;
  bool _savedRuleMissing = false;
  List<CustomRule> _customRules = [];

  String? _nameError;
  String? _dateError;
  String? _ruleError;

  bool _isSaving = false;
  bool _customRulesLoaded = false;

  static const String _storageNote =
      'Your records are saved on this phone only. If you delete the app or '
      'lose the phone, they cannot be recovered unless you made a backup '
      '(Settings > Back up now).';

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    final clock = ref.read(clockProvider);
    final child = widget.initialChild;
    if (child != null) {
      _nameController.text = child.name;
      _selectedRuleId = child.ruleId;
      try {
        _startDate = DateTime.parse(child.schoolYearStart);
        _endDate = DateTime.parse(child.schoolYearEnd);
      } catch (_) {
        final currentYear = clock.month < 7 ? clock.year - 1 : clock.year;
        _startDate = DateTime(currentYear, 9, 1);
        _endDate = DateTime(currentYear + 1, 6, 30);
      }
    } else {
      // Default dates: September 1 of current academic year to June 30 of next
      final currentYear = clock.month < 7 ? clock.year - 1 : clock.year;
      _startDate = DateTime(currentYear, 9, 1);
      _endDate = DateTime(currentYear + 1, 6, 30);
    }


    _loadCustomRules();
  }

  Future<void> _loadCustomRules() async {
    List<CustomRule> rules = [];
    try {
      rules = await ref.read(customRuleRepositoryProvider).getAll();
      if (rules.isEmpty) {
        await ref.read(customRuleRepositoryProvider).add(
              CustomRulesCompanion.insert(
                label: 'Homeschool Goal',
                requiredHours: const drift.Value(900),
                requiredDays: const drift.Value(180),
              ),
            );
        rules = await ref.read(customRuleRepositoryProvider).getAll();
      }
    } catch (_) {
      // Keep the list empty; fallback to manual configuration if database error.
    }
    if (mounted) {
      setState(() {
        _customRules = rules;
        _customRulesLoaded = true;
        if (widget.initialChild == null && _selectedRuleId == null && rules.isNotEmpty) {
          _selectedRuleId = 'custom:${rules.last.id}';
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validate() {
    final trimmedName = _nameController.text.trim();
    String? nameErr;
    if (trimmedName.isEmpty) {
      nameErr = 'Name is required';
    } else if (trimmedName.length > 40) {
      nameErr = 'Name cannot exceed 40 characters';
    }

    final startUtc = DateTime.utc(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    );
    final endUtc = DateTime.utc(
      _endDate.year,
      _endDate.month,
      _endDate.day,
    );

    String? dateErr;
    if (!endUtc.isAfter(startUtc)) {
      dateErr = 'End date must be after start date';
    } else {
      final totalDays = endUtc.difference(startUtc).inDays + 1;
      if (totalDays > 400) {
        dateErr = 'School year cannot exceed 400 days';
      }
    }

    String? ruleErr;
    if (_selectedRuleId == null || _selectedRuleId!.isEmpty) {
      ruleErr = 'Please set up your tracking goals';
    }

    setState(() {
      _nameError = nameErr;
      _dateError = dateErr;
      _ruleError = ruleErr;
    });
  }

  bool get _isValid =>
      _nameError == null &&
      _dateError == null &&
      _ruleError == null &&
      _nameController.text.trim().isNotEmpty &&
      _selectedRuleId != null;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select school year start',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
      _validate();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select school year end',
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      _validate();
    }
  }

  /// Number of calendar days in the chosen school year, or null when the
  /// dates are not valid yet.
  int? get _schoolYearLengthInDays {
    final startUtc =
        DateTime.utc(_startDate.year, _startDate.month, _startDate.day);
    final endUtc = DateTime.utc(_endDate.year, _endDate.month, _endDate.day);
    if (!endUtc.isAfter(startUtc)) return null;
    return endUtc.difference(startUtc).inDays + 1;
  }

  Future<void> _showMakeCustomRuleDialog() async {
    final labelController = TextEditingController();
    final hoursController = TextEditingController();
    final daysController = TextEditingController();
    String? dialogError;
    bool dialogSaving = false;

    final result = await showDialog<int?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Make my own rule'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: labelController,
                      maxLength: 30,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Rule label',
                        hintText: 'e.g. My Goal',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Required hours (optional)',
                        hintText: 'e.g. 1000',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: daysController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Required days (optional)',
                        hintText: 'e.g. 180',
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: dialogSaving
                      ? null
                      : () async {
                          final label = labelController.text.trim();
                          if (label.isEmpty) {
                            setDialogState(() {
                              dialogError = 'Label is required';
                            });
                            return;
                          }

                          // Only digits can be typed, so parsing cannot fail
                          // on a non-empty field. Empty or zero means "not set".
                          final hours =
                              int.tryParse(hoursController.text.trim()) ?? 0;
                          final days =
                              int.tryParse(daysController.text.trim()) ?? 0;
                          final hasHours = hours > 0;
                          final hasDays = days > 0;

                          if (!hasHours && !hasDays) {
                            setDialogState(() {
                              dialogError = 'Provide hours, days, or both';
                            });
                            return;
                          }

                          if (hasHours && hours > 3000) {
                            setDialogState(() {
                              dialogError =
                                  'Hours must be between 1 and 3000';
                            });
                            return;
                          }

                          if (hasDays) {
                            final yearLength = _schoolYearLengthInDays;
                            final maxDays = (yearLength != null &&
                                    yearLength < 366)
                                ? yearLength
                                : 366;
                            if (days > maxDays) {
                              setDialogState(() {
                                dialogError = maxDays == 366
                                    ? 'Days must be between 1 and 366'
                                    : 'Days cannot be more than the school '
                                        'year length ($maxDays days)';
                              });
                              return;
                            }
                          }

                          setDialogState(() {
                            dialogError = null;
                            dialogSaving = true;
                          });

                          try {
                            final id =
                                await ref.read(customRuleRepositoryProvider).add(
                                      CustomRulesCompanion.insert(
                                        label: label,
                                        requiredHours: hasHours
                                            ? drift.Value(hours)
                                            : const drift.Value(null),
                                        requiredDays: hasDays
                                            ? drift.Value(days)
                                            : const drift.Value(null),
                                      ),
                                    );
                            if (context.mounted) {
                              Navigator.of(context).pop(id);
                            }
                          } catch (_) {
                            if (context.mounted) {
                              setDialogState(() {
                                dialogSaving = false;
                                dialogError =
                                    'Failed to save rule. Please try again.';
                              });
                            }
                          }
                        },
                  child: const Text('Save rule'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (result != null) {
      await _loadCustomRules();
      if (!mounted) return;
      setState(() {
        _selectedRuleId = 'custom:$result';
      });
      _validate();
    }
  }

  Future<void> _saveChild() async {
    _validate();
    if (!_isValid) return;

    setState(() {
      _isSaving = true;
    });

    final trimmedName = _nameController.text.trim();
    final startStr = _dateFormat.format(_startDate);
    final endStr = _dateFormat.format(_endDate);

    // Enforce free plan limit (single child)
    if (widget.initialChild == null) {
      final childRepo = ref.read(childRepositoryProvider);
      final existingChildren = await childRepo.getAll();
      if (existingChildren.isNotEmpty) {
        final secondChildAccess = ref.read(featureAccessProvider(Feature.secondChild));
        if (secondChildAccess.isLocked) {
          setState(() {
            _isSaving = false;
          });
          if (mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PaywallScreen(),
              ),
            );
          }
          return;
        }
      }
    }

    try {
      final childRepo = ref.read(childRepositoryProvider);
      if (widget.initialChild == null) {
        await childRepo.add(
          ChildrenCompanion.insert(
            name: trimmedName,
            ruleId: _selectedRuleId!,
            schoolYearStart: startStr,
            schoolYearEnd: endStr,
            createdAt: ref.read(clockProvider).millisecondsSinceEpoch,
          ),
        );
      } else {
        await childRepo.update(
          widget.initialChild!.copyWith(
            name: trimmedName,
            ruleId: _selectedRuleId!,
            schoolYearStart: startStr,
            schoolYearEnd: endStr,
          ),
        );
      }

      if (mounted) {
        if (widget.isFirstChild) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          );
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save child. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetProfilesAsync = ref.watch(ruleProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialChild == null ? 'Add child' : 'Edit child'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Child name field
                TextField(
                  controller: _nameController,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "Child's name",
                    hintText: 'e.g. Emma',
                    errorText: _nameError,
                  ),
                  onChanged: (_) => _validate(),
                ),
                const SizedBox(height: 16),

                // Rule profile selection
                Text(
                  'Homeschool tracking goals',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                assetProfilesAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Text(
                    'Failed to load rules: $err',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  data: (assetProfiles) {
                    // A saved custom rule can only be recognised after the
                    // custom rules have loaded. Judging it earlier would
                    // wrongly reset the child to the example profile.
                    if (!_customRulesLoaded &&
                        (_selectedRuleId?.startsWith('custom:') ?? false)) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final availableAssetProfiles = assetProfiles.where((p) {
                      if (p.id == 'placeholder_example') {
                        return widget.initialChild?.ruleId == 'placeholder_example';
                      }
                      return true;
                    }).toList();

                    final availableRuleIds = {
                      ...availableAssetProfiles.map((p) => p.id),
                      ..._customRules.map((c) => 'custom:${c.id}'),
                    };

                    // If stored value is missing from the items, fall back to available profile
                    if (_selectedRuleId != null && !availableRuleIds.contains(_selectedRuleId)) {
                      _savedRuleMissing = true;
                      if (_customRules.isNotEmpty) {
                        _selectedRuleId = 'custom:${_customRules.last.id}';
                      } else if (availableAssetProfiles.isNotEmpty) {
                        _selectedRuleId = availableAssetProfiles.first.id;
                      } else {
                        _selectedRuleId = null;
                      }
                    } else if (_selectedRuleId == null) {
                      if (_customRules.isNotEmpty) {
                        _selectedRuleId = 'custom:${_customRules.last.id}';
                      } else if (availableAssetProfiles.isNotEmpty) {
                        _selectedRuleId = availableAssetProfiles.first.id;
                      }
                    }

                    // Look for current chosen profile metadata
                    RuleProfile? chosenAssetProfile;
                    CustomRule? chosenCustomRule;

                    if (_selectedRuleId != null) {
                      for (final p in availableAssetProfiles) {
                        if (p.id == _selectedRuleId) {
                          chosenAssetProfile = p;
                          break;
                        }
                      }
                      if (chosenAssetProfile == null &&
                          _selectedRuleId!.startsWith('custom:')) {
                        final customId = int.tryParse(
                          _selectedRuleId!.replaceFirst('custom:', ''),
                        );
                        for (final c in _customRules) {
                          if (c.id == customId) {
                            chosenCustomRule = c;
                            break;
                          }
                        }
                      }
                    }

                    if (_selectedRuleId == null || (chosenAssetProfile == null && chosenCustomRule == null)) {
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _ruleError != null
                                ? theme.colorScheme.error
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        color: theme.colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.track_changes,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Set up tracking goals',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Homeledger is parent-configured. Set your target hours, days, or both for this school year.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton.icon(
                                    onPressed: _showMakeCustomRuleDialog,
                                    icon: const Icon(Icons.tune),
                                    label: const Text('Set up tracking goals'),
                                  ),
                                  OutlinedButton(
                                    onPressed: _showMakeCustomRuleDialog,
                                    child: const Text('Make my own rule'),
                                  ),
                                ],
                              ),
                              if (_ruleError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _ruleError!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      color: theme.colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_savedRuleMissing)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Your saved rule is not available. Choose or configure goals.',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (availableRuleIds.length > 1) ...[
                              InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Selected goals',
                                  errorText: _ruleError,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedRuleId,
                                    isExpanded: true,
                                    isDense: true,
                                    items: [
                                      ...availableAssetProfiles.map(
                                        (p) => DropdownMenuItem<String>(
                                          value: p.id,
                                          child: Text(p.id == 'placeholder_example'
                                              ? '${p.label} (Legacy demo)'
                                              : p.label),
                                        ),
                                      ),
                                      ..._customRules.map(
                                        (c) => DropdownMenuItem<String>(
                                          value: 'custom:${c.id}',
                                          child: Text('${c.label} (Custom)'),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedRuleId = val;
                                        _savedRuleMissing = false;
                                      });
                                      _validate();
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (chosenCustomRule != null) ...[
                              if (availableRuleIds.length <= 1) ...[
                                Row(
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${chosenCustomRule.label} (Custom)',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                              Text(
                                'Custom goal: '
                                '${chosenCustomRule.requiredHours != null ? "${chosenCustomRule.requiredHours} hours" : ""}'
                                '${chosenCustomRule.requiredHours != null && chosenCustomRule.requiredDays != null ? ", " : ""}'
                                '${chosenCustomRule.requiredDays != null ? "${chosenCustomRule.requiredDays} days" : ""}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ] else if (chosenAssetProfile != null) ...[
                              Text(
                                chosenAssetProfile.id == 'placeholder_example'
                                    ? '${chosenAssetProfile.label} (Legacy demo)'
                                    : chosenAssetProfile.label,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: _showMakeCustomRuleDialog,
                                  child: const Text('Make my own rule'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // School year date pickers
                Text(
                  'School year dates',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartDate,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start date',
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(_dateFormat.format(_startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndDate,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End date',
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(_dateFormat.format(_endDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_dateError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _dateError!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Where the data lives (shown when adding a child)
                if (widget.initialChild == null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _storageNote,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Save button
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveChild,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.initialChild == null
                            ? 'Save child'
                            : 'Update child'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
