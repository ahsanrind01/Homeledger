import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/providers.dart';
import '../../services/sample_capture_service.dart';

/// Screen presented after image capture to review, tag, and persist a work sample.
class SampleCaptureScreen extends ConsumerStatefulWidget {
  final int childId;
  final CaptureResult captureResult;

  const SampleCaptureScreen({
    super.key,
    required this.childId,
    required this.captureResult,
  });

  @override
  ConsumerState<SampleCaptureScreen> createState() => _SampleCaptureScreenState();
}

class _SampleCaptureScreenState extends ConsumerState<SampleCaptureScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late DateTime _selectedDate;
  int? _selectedSubjectId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    final clock = ref.read(clockProvider);
    _selectedDate = DateTime(clock.year, clock.month, clock.day);

    // Show a short message explaining which capture method was used
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Captured via ${widget.captureResult.method.displayName}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final clock = ref.read(clockProvider);
    final today = DateTime(clock.year, clock.month, clock.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: today, // Future dates blocked
      helpText: 'Select sample date',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveSample() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final storageService = ref.read(sampleStorageServiceProvider);
      await storageService.saveSample(
        childId: widget.childId,
        rawBytes: widget.captureResult.bytes,
        day: formatIsoDate(_selectedDate),
        subjectId: _selectedSubjectId,
        title: _titleController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work sample saved successfully')),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save sample: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Save work sample'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Capture Method Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      switch (widget.captureResult.method) {
                        CaptureMethod.documentScanner => Icons.document_scanner,
                        CaptureMethod.camera => Icons.camera_alt,
                        CaptureMethod.gallery => Icons.photo_library,
                      },
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Captured via ${widget.captureResult.method.displayName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Image Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Image.memory(
                      widget.captureResult.bytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. Subject Selector (Optional)
              subjectsAsync.when(
                loading: () => const SizedBox(height: 56),
                error: (e, _) => Text('Error loading subjects: $e'),
                data: (subjects) {
                  return DropdownButtonFormField<int?>(
                    key: const ValueKey('sample_subject_dropdown'),
                    initialValue: _selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Subject (optional)',
                      prefixIcon: Icon(Icons.book_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('No subject / General'),
                      ),
                      ...subjects.map(
                        (s) => DropdownMenuItem<int?>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      ),
                    ],
                    onChanged: (id) {
                      setState(() {
                        _selectedSubjectId = id;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // 4. Date Picker (Default today, no future)
              InkWell(
                key: const ValueKey('sample_date_picker_button'),
                borderRadius: BorderRadius.circular(4),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatDisplayDate(_selectedDate)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 5. Title Field (Optional, max 60 chars)
              TextFormField(
                key: const ValueKey('sample_title_field'),
                controller: _titleController,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  hintText: 'e.g. Chapter 4 math worksheet',
                  prefixIcon: Icon(Icons.edit_note_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val != null && val.trim().length > 60) {
                    return 'Title cannot exceed 60 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 6. Save Button
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  key: const ValueKey('sample_save_button'),
                  onPressed: _isSaving ? null : _saveSample,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isSaving ? 'Processing & saving...' : 'Save sample'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
