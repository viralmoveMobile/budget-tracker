import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/wage_models.dart';
import '../providers/wage_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class AddWorkEntrySheet extends ConsumerStatefulWidget {
  final String jobId;
  final DateTime date;
  final WorkEntry? entry;

  const AddWorkEntrySheet({
    super.key,
    required this.jobId,
    required this.date,
    this.entry,
  });

  @override
  ConsumerState<AddWorkEntrySheet> createState() => _AddWorkEntrySheetState();
}

class _AddWorkEntrySheetState extends ConsumerState<AddWorkEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hoursController;
  late TextEditingController _otHoursController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _hoursController =
        TextEditingController(text: widget.entry?.hours.toString() ?? '');
    _otHoursController = TextEditingController(
        text: widget.entry?.overtimeHours.toString() ?? '');
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _otHoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final entry = WorkEntry(
        id: widget.entry?.id ?? const Uuid().v4(),
        jobId: widget.jobId,
        date: widget.date,
        hours: double.tryParse(_hoursController.text) ?? 0.0,
        overtimeHours: double.tryParse(_otHoursController.text) ?? 0.0,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (widget.entry == null) {
        ref.read(workEntriesProvider(widget.jobId).notifier).addEntry(entry);
      } else {
        ref.read(workEntriesProvider(widget.jobId).notifier).updateEntry(entry);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DateFormat('EEEE, MMM dd').format(widget.date),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXl,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hoursController,
                    decoration: const InputDecoration(
                      labelText: 'Standard Hours',
                      prefixIcon: Icon(Icons.timer_rounded),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
                AppSpacing.gapLg,
                Expanded(
                  child: TextFormField(
                    controller: _otHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Overtime',
                      prefixIcon: Icon(Icons.more_time_rounded),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            AppSpacing.gapLg,
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.note_alt_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            AppSpacing.gapXl,
            Row(
              children: [
                if (widget.entry != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton.filledTonal(
                      onPressed: () {
                        ref
                            .read(workEntriesProvider(widget.jobId).notifier)
                            .deleteEntry(widget.entry!.id);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.wagesColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r12)),
                    ),
                    child: const Text('Save Entry',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
            AppSpacing.gapXl,
          ],
        ),
      ),
    );
  }
}
