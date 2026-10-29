import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';

/// Full-screen viewer for a work sample with pinch-to-zoom and deletion.
class SampleViewerScreen extends ConsumerStatefulWidget {
  final int sampleId;

  const SampleViewerScreen({
    super.key,
    required this.sampleId,
  });

  @override
  ConsumerState<SampleViewerScreen> createState() => _SampleViewerScreenState();
}

class _SampleViewerScreenState extends ConsumerState<SampleViewerScreen> {
  WorkSample? _sample;
  Subject? _subject;
  File? _resolvedFile;
  bool _fileExists = false;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadSample();
  }

  Future<void> _loadSample() async {
    final sampleRepo = ref.read(sampleRepositoryProvider);
    final subjectRepo = ref.read(subjectRepositoryProvider);
    final storageService = ref.read(sampleStorageServiceProvider);

    final sample = await sampleRepo.getById(widget.sampleId);
    if (sample == null) {
      if (mounted) {
        setState(() {
          _sample = null;
          _isLoading = false;
        });
      }
      return;
    }

    Subject? subject;
    if (sample.subjectId != null) {
      subject = await subjectRepo.getById(sample.subjectId!);
    }

    final file = await storageService.resolveFile(sample.filePath);
    final exists = file.existsSync();

    if (mounted) {
      setState(() {
        _sample = sample;
        _subject = subject;
        _resolvedFile = file;
        _fileExists = exists;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete work sample?'),
        content: const Text(
          'Are you sure you want to delete this work sample? '
          'The record and file will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final storageService = ref.read(sampleStorageServiceProvider);
        await storageService.deleteSample(widget.sampleId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Work sample deleted')),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete sample: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_sample == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Work sample not found'),
        ),
      );
    }

    final sample = _sample!;
    DateTime? sampleDate;
    try {
      sampleDate = DateTime.parse(sample.day);
    } catch (_) {}

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        title: Text(
          sample.title ?? 'Work sample',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            key: const ValueKey('sample_viewer_delete_button'),
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Delete sample',
            onPressed: _isDeleting ? null : _confirmAndDelete,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Pinch to zoom Image Viewer or File Missing Placeholder
          Positioned.fill(
            child: _fileExists && _resolvedFile != null
                ? InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Center(
                      child: Image.file(
                        _resolvedFile!,
                        fit: BoxFit.contain,
                        cacheWidth: 2048,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 72,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 72,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'File missing from device',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The file for this work sample could not be found.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // 2. Bottom Metadata Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sample.title != null && sample.title!.isNotEmpty) ...[
                      Text(
                        sample.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        if (_subject != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _subject!.name,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (sampleDate != null)
                          Text(
                            formatDisplayDate(sampleDate),
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
