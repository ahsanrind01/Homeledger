import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/export_date_notice.dart';
import '../../domain/feature_policy.dart';
import '../paywall/paywall_screen.dart';

/// Screen allowing the parent to configure and generate a portfolio PDF export.
class ExportOptionsScreen extends ConsumerStatefulWidget {
  final int? initialChildId;

  final bool asTab;

  const ExportOptionsScreen({
    super.key,
    this.initialChildId,
    this.asTab = false,
  });

  @override
  ConsumerState<ExportOptionsScreen> createState() => _ExportOptionsScreenState();
}

class _ExportOptionsScreenState extends ConsumerState<ExportOptionsScreen> {
  int? _selectedChildId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _includeWorkSamples = true;
  bool _isGenerating = false;
  String? _initializedForChildYear;

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.initialChildId;
  }

  @override
  void didUpdateWidget(ExportOptionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialChildId != null && widget.initialChildId != oldWidget.initialChildId) {
      _selectedChildId = widget.initialChildId;
    }
  }

  void _syncDefaultDatesForChild(Child child) {
    final key = '${child.id}_${child.schoolYearStart}_${child.schoolYearEnd}';
    if (_initializedForChildYear == key) return;
    _initializedForChildYear = key;

    try {
      _startDate = DateTime.parse(child.schoolYearStart);
      _endDate = DateTime.parse(child.schoolYearEnd);
    } catch (_) {
      final now = ref.read(clockProvider);
      _startDate = DateTime(now.year, 9, 1);
      _endDate = DateTime(now.year + 1, 6, 30);
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime clock = ref.read(clockProvider);
    final DateTime start = _startDate ?? clock;
    final DateTime end = _endDate ?? start.add(const Duration(days: 30));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: start, end: end),
      helpText: 'Select reporting period',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generatePdf() async {
    final exportAccess = ref.read(featureAccessProvider(Feature.exportPdf));
    if (exportAccess.isLocked) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PaywallScreen(),
        ),
      );
      return;
    }

    final childId = _selectedChildId;
    if (childId == null || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student and date range.')),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final exportService = await ref.read(exportServiceProvider.future);
      await exportService.exportAndSharePortfolio(
        childId: childId,
        dateRangeStart: formatIsoDate(_startDate!),
        dateRangeEnd: formatIsoDate(_endDate!),
        includeWorkSamples: _includeWorkSamples,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Portfolio generated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate PDF: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final childrenAsync = ref.watch(childrenStreamProvider);

    final bodyContent = childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (children) {
          if (children.isEmpty) {
            return const Center(
              child: Text('No student profiles found. Add a child first.'),
            );
          }

          // Default selected child
          if (_selectedChildId == null || !children.any((c) => c.id == _selectedChildId)) {
            final activeId = ref.watch(selectedChildIdProvider);
            if (activeId != null && children.any((c) => c.id == activeId)) {
              _selectedChildId = activeId;
            } else {
              _selectedChildId = children.first.id;
            }
          }

          final selectedChild = children.firstWhere(
            (c) => c.id == _selectedChildId,
            orElse: () => children.first,
          );

          // Synchronize default dates to child's school year
          _syncDefaultDatesForChild(selectedChild);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Instructions banner
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.picture_as_pdf_outlined,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Homeschool Portfolio Export',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Compiles attendance, subject hours, and work samples into a clean document ready to share or print.',
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
                ),
                const SizedBox(height: 16),

                // Student Selection
                if (children.length > 1) ...[
                  Text(
                    'Student',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedChildId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: children.map((c) {
                      return DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: _isGenerating
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() {
                                _selectedChildId = val;
                                _initializedForChildYear = null;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 20),
                ],

                // Date Range Selection
                Text(
                  'Reporting Period',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.date_range_outlined),
                    title: Text(
                      _startDate != null && _endDate != null
                          ? '${formatDisplayDate(_startDate!)} to ${formatDisplayDate(_endDate!)}'
                          : 'Select dates',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Default: Full school year (${selectedChild.schoolYearStart} to ${selectedChild.schoolYearEnd})',
                    ),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _isGenerating ? null : () => _selectDateRange(context),
                  ),
                ),
                if (_startDate != null && _endDate != null) ...[
                  Builder(
                    builder: (context) {
                      final notice = computeDateRangeSchoolYearNotice(
                        schoolYearStart: selectedChild.schoolYearStart,
                        schoolYearEnd: selectedChild.schoolYearEnd,
                        rangeStart: formatIsoDate(_startDate!),
                        rangeEnd: formatIsoDate(_endDate!),
                      );
                      if (notice == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
                        child: Text(
                          notice,
                          key: const ValueKey('export_range_notice_text'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 20),

                // Include Work Samples Option
                Text(
                  'Portfolio Sections',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.collections_outlined),
                    title: const Text('Include work samples'),
                    subtitle: const Text(
                      'Attach full-page student work sample images to the document',
                    ),
                    value: _includeWorkSamples,
                    onChanged: _isGenerating
                        ? null
                        : (val) {
                            setState(() {
                              _includeWorkSamples = val;
                            });
                          },
                  ),
                ),
                const SizedBox(height: 32),

                // Generate Button with Progress Indicator
                Builder(
                  builder: (context) {
                    final exportAccess = ref.watch(featureAccessProvider(Feature.exportPdf));
                    final isLocked = exportAccess.isLocked;

                    return FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Icon(isLocked ? Icons.lock_outline : Icons.share_outlined),
                      label: Text(
                        _isGenerating
                            ? 'Creating PDF...'
                            : (isLocked ? 'Create PDF (Plus)' : 'Create PDF'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isGenerating ? null : _generatePdf,
                    );
                  },
                ),
              ],
            ),
          );
        },
      );

    if (widget.asTab) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Export portfolio'),
      ),
      body: bodyContent,
    );
  }
}
