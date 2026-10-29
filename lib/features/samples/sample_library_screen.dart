import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/repositories/sample_repository.dart';
import 'sample_capture_screen.dart';
import 'sample_viewer_screen.dart';
import '../../domain/feature_policy.dart';
import '../paywall/paywall_screen.dart';

/// Screen displaying the grid of work sample thumbnails for a child,
/// with subject and date range filtering, and capture trigger.
class SampleLibraryScreen extends ConsumerStatefulWidget {
  final int childId;

  const SampleLibraryScreen({
    super.key,
    required this.childId,
  });

  @override
  ConsumerState<SampleLibraryScreen> createState() => _SampleLibraryScreenState();
}

class _SampleLibraryScreenState extends ConsumerState<SampleLibraryScreen> {
  int? _selectedSubjectId;
  DateTimeRange? _selectedDateRange;

  Future<void> _startCapture() async {
    final scanAccess = ref.read(featureAccessProvider(Feature.scanSample));
    if (scanAccess.isLocked) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PaywallScreen(),
        ),
      );
      return;
    }

    final captureService = ref.read(sampleCaptureServiceProvider);
    try {
      final result = await captureService.capture();
      if (result != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SampleCaptureScreen(
              childId: widget.childId,
              captureResult: result,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not capture work sample: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pickDateRange() async {
    final clock = ref.read(clockProvider);
    final today = DateTime(clock.year, clock.month, clock.day);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: today.subtract(const Duration(days: 30)),
            end: today,
          ),
      helpText: 'Filter by date range',
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedSubjectId = null;
      _selectedDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sampleRepo = ref.watch(sampleRepositoryProvider);
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final scanAccess = ref.watch(featureAccessProvider(Feature.scanSample));
    final isLocked = scanAccess.isLocked;

    final filter = SampleFilter(
      subjectId: _selectedSubjectId,
      from: _selectedDateRange != null ? formatIsoDate(_selectedDateRange!.start) : null,
      to: _selectedDateRange != null ? formatIsoDate(_selectedDateRange!.end) : null,
    );

    final hasActiveFilter = _selectedSubjectId != null || _selectedDateRange != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Work samples'),
        actions: [
          IconButton(
            key: const ValueKey('library_scan_action_button'),
            icon: isLocked
                ? const Icon(Icons.lock_outline)
                : const Icon(Icons.document_scanner_outlined),
            tooltip: isLocked ? 'Scan work (Plus)' : 'Scan work',
            onPressed: _startCapture,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('library_scan_fab'),
        onPressed: _startCapture,
        icon: isLocked
            ? const Icon(Icons.lock_outline)
            : const Icon(Icons.document_scanner),
        label: isLocked
            ? const Text('Scan work (Plus)')
            : const Text('Scan work'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject filter chips
                  subjectsAsync.when(
                    loading: () => const SizedBox(height: 38),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (subjects) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            ChoiceChip(
                              key: const ValueKey('filter_subject_all'),
                              label: const Text('All subjects'),
                              selected: _selectedSubjectId == null,
                              onSelected: (_) {
                                setState(() {
                                  _selectedSubjectId = null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ...subjects.map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  key: ValueKey('filter_subject_${s.id}'),
                                  label: Text(s.name),
                                  selected: _selectedSubjectId == s.id,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedSubjectId = selected ? s.id : null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),

                  // Date range chip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        ActionChip(
                          key: const ValueKey('filter_date_range_chip'),
                          avatar: const Icon(Icons.date_range, size: 16),
                          label: Text(
                            _selectedDateRange != null
                                ? '${formatDisplayDate(_selectedDateRange!.start)} - ${formatDisplayDate(_selectedDateRange!.end)}'
                                : 'All dates',
                          ),
                          onPressed: _pickDateRange,
                        ),
                        if (hasActiveFilter) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            key: const ValueKey('filter_clear_button'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Clear'),
                            onPressed: _clearFilters,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Samples Grid
            Expanded(
              child: StreamBuilder<List<WorkSample>>(
                stream: sampleRepo.watchForChildFiltered(widget.childId, filter),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading samples: ${snapshot.error}'),
                    );
                  }

                  final samples = snapshot.data ?? [];

                  if (samples.isEmpty) {
                    if (hasActiveFilter) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_off_outlined,
                                size: 56,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No samples match the selected filter',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: _clearFilters,
                                child: const Text('Clear filter'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 64,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No work samples yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan learning materials, worksheets, and art to build your portfolio.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              key: const ValueKey('library_empty_scan_button'),
                              onPressed: _startCapture,
                              icon: isLocked
                                  ? const Icon(Icons.lock_outline)
                                  : const Icon(Icons.document_scanner),
                              label: isLocked
                                  ? const Text('Scan work (Plus)')
                                  : const Text('Scan work'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    key: const ValueKey('sample_library_grid'),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: samples.length,
                    itemBuilder: (context, index) {
                      final sample = samples[index];
                      return _SampleThumbnailCard(
                        sample: sample,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SampleViewerScreen(
                                sampleId: sample.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleThumbnailCard extends ConsumerStatefulWidget {
  final WorkSample sample;
  final VoidCallback onTap;

  const _SampleThumbnailCard({
    required this.sample,
    required this.onTap,
  });

  @override
  ConsumerState<_SampleThumbnailCard> createState() => _SampleThumbnailCardState();
}

class _SampleThumbnailCardState extends ConsumerState<_SampleThumbnailCard> {
  File? _resolvedFile;
  bool _fileExists = false;
  Subject? _subject;

  @override
  void initState() {
    super.initState();
    _checkFileAndSubject();
  }

  @override
  void didUpdateWidget(covariant _SampleThumbnailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sample.filePath != widget.sample.filePath ||
        oldWidget.sample.subjectId != widget.sample.subjectId) {
      _checkFileAndSubject();
    }
  }

  Future<void> _checkFileAndSubject() async {
    final storageService = ref.read(sampleStorageServiceProvider);
    final subjectRepo = ref.read(subjectRepositoryProvider);

    final file = await storageService.resolveFile(widget.sample.filePath);
    final exists = file.existsSync();

    Subject? subject;
    if (widget.sample.subjectId != null) {
      subject = await subjectRepo.getById(widget.sample.subjectId!);
    }

    if (mounted) {
      setState(() {
        _resolvedFile = file;
        _fileExists = exists;
        _subject = subject;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sample = widget.sample;

    DateTime? sampleDate;
    try {
      sampleDate = DateTime.parse(sample.day);
    } catch (_) {}

    return Card(
      key: ValueKey('sample_card_${sample.id}'),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail Image or Missing Placeholder
            Expanded(
              child: _fileExists && _resolvedFile != null
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final pixelRatio = MediaQuery.of(context).devicePixelRatio;
                        final cacheWidth =
                            (constraints.maxWidth * pixelRatio).round();
                        return Image.file(
                          _resolvedFile!,
                          fit: BoxFit.cover,
                          cacheWidth: cacheWidth > 0 ? cacheWidth : null,
                          errorBuilder: (_, _, _) =>
                              _buildMissingPlaceholder(theme),
                        );
                      },
                    )
                  : _buildMissingPlaceholder(theme),
            ),


            // Card Footer
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sample.title ?? (_subject?.name ?? 'Sample'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (sampleDate != null)
                        Text(
                          formatDisplayDate(sampleDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      if (_subject != null)
                        Flexible(
                          child: Text(
                            _subject!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 36,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 4),
          Text(
            'File missing',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
