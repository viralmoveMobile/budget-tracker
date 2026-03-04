import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/wage_models.dart';
import '../providers/wage_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class AddJobSheet extends ConsumerStatefulWidget {
  final WageJob? job;
  const AddJobSheet({super.key, this.job});

  @override
  ConsumerState<AddJobSheet> createState() => _AddJobSheetState();
}

class _AddJobSheetState extends ConsumerState<AddJobSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _employerController;
  late TextEditingController _baseAmountController;
  late TextEditingController _otRateController;
  late TextEditingController _taxController;
  late WageMode _mode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.job?.name ?? '');
    _employerController =
        TextEditingController(text: widget.job?.employer ?? '');
    _baseAmountController =
        TextEditingController(text: widget.job?.baseAmount.toString() ?? '');
    _otRateController =
        TextEditingController(text: widget.job?.overtimeRate.toString() ?? '');
    _taxController =
        TextEditingController(text: widget.job?.taxPercentage.toString() ?? '');
    _mode = widget.job?.mode ?? WageMode.hourly;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employerController.dispose();
    _baseAmountController.dispose();
    _otRateController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final job = WageJob(
        id: widget.job?.id ?? const Uuid().v4(),
        name: _nameController.text,
        employer:
            _employerController.text.isEmpty ? null : _employerController.text,
        mode: _mode,
        baseAmount: double.tryParse(_baseAmountController.text) ?? 0.0,
        overtimeRate: double.tryParse(_otRateController.text) ?? 0.0,
        taxPercentage: double.tryParse(_taxController.text) ?? 0.0,
      );

      if (widget.job == null) {
        ref.read(wageJobsProvider.notifier).addJob(job);
      } else {
        ref.read(wageJobsProvider.notifier).updateJob(job);
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.job == null ? 'New Wage Account / Job' : 'Edit Job',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapXl,
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Job Name / Label',
                  prefixIcon: Icon(Icons.work_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _employerController,
                decoration: const InputDecoration(
                  labelText: 'Employer (Optional)',
                  prefixIcon: Icon(Icons.business_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.gapLg,
              SegmentedButton<WageMode>(
                segments: const [
                  ButtonSegment(
                      value: WageMode.hourly,
                      label: Text('Hourly'),
                      icon: Icon(Icons.hourglass_bottom_rounded)),
                  ButtonSegment(
                      value: WageMode.monthly,
                      label: Text('Monthly'),
                      icon: Icon(Icons.calendar_month_rounded)),
                ],
                selected: {_mode},
                onSelectionChanged: (val) => setState(() => _mode = val.first),
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _baseAmountController,
                decoration: InputDecoration(
                  labelText: _mode == WageMode.hourly
                      ? 'Hourly Rate'
                      : 'Monthly Salary',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _otRateController,
                decoration: const InputDecoration(
                  labelText: 'Overtime Rate (Per Hour)',
                  prefixIcon: Icon(Icons.trending_up_rounded),
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _taxController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Tax %',
                  prefixIcon: Icon(Icons.percent_rounded),
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              AppSpacing.gapXl,
              Row(
                children: [
                  if (widget.job != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton.filledTonal(
                        onPressed: () {
                          ref
                              .read(wageJobsProvider.notifier)
                              .deleteJob(widget.job!.id);
                          Navigator.pop(context);
                        },
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.r12)),
                      ),
                      child: Text(
                          widget.job == null ? 'Create Job' : 'Save Changes',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapXl,
            ],
          ),
        ),
      ),
    );
  }
}
