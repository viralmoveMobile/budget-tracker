import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/goal_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/financial_goal.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class AddGoalSheet extends ConsumerStatefulWidget {
  const AddGoalSheet({super.key});

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  GoalType _type = GoalType.savings;
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final goal = FinancialGoal(
        id: const Uuid().v4(),
        name: _nameController.text,
        targetAmount: double.parse(_amountController.text),
        currentAmount: 0,
        deadline: _deadline,
        type: _type,
      );

      ref.read(goalsProvider.notifier).addGoal(goal);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                'Create Financial Goal',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapXl,
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name (e.g. New Car)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid number';
                  return null;
                },
              ),
              AppSpacing.gapXl,
              const Text(
                'Goal Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              AppSpacing.gapSm,
              SegmentedButton<GoalType>(
                segments: GoalType.values.map((t) {
                  return ButtonSegment(
                    value: t,
                    label: Text(t.label),
                    icon: Icon(t == GoalType.savings
                        ? Icons.savings
                        : Icons.trending_down),
                  );
                }).toList(),
                selected: {_type},
                onSelectionChanged: (val) {
                  setState(() => _type = val.first);
                },
              ),
              AppSpacing.gapXl,
              ListTile(
                title: const Text('Deadline'),
                subtitle: Text(
                    '${_deadline.day}/${_deadline.month}/${_deadline.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
              ),
              AppSpacing.gapXxl,
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r12),
                  ),
                ),
                child: const Text('Set Goal',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              AppSpacing.gapXl,
            ],
          ),
        ),
      ),
    );
  }
}
