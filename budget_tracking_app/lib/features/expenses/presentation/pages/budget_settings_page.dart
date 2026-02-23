import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_limit.dart';
import '../../data/models/expense_category.dart';
import '../providers/budget_provider.dart';
import 'package:uuid/uuid.dart';

class BudgetSettingsPage extends ConsumerWidget {
  const BudgetSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitsAsync = ref.watch(budgetLimitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Settings')),
      body: limitsAsync.when(
        data: (limits) {
          final now = DateTime.now();
          final totalLimit =
              limits.where((l) => l.category == null).firstOrNull;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildLimitTile(
                context,
                ref,
                'Total Monthly Budget',
                totalLimit,
                null,
                now,
              ),
              const Divider(height: 32),
              Text(
                'Category-wise Limits',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...ExpenseCategory.values.map((category) {
                final categoryLimit =
                    limits.where((l) => l.category == category).firstOrNull;
                return _buildLimitTile(
                  context,
                  ref,
                  category.label,
                  categoryLimit,
                  category,
                  now,
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildLimitTile(
    BuildContext context,
    WidgetRef ref,
    String title,
    BudgetLimit? limit,
    ExpenseCategory? category,
    DateTime now,
  ) {
    return ListTile(
      leading: Icon(category?.icon ?? Icons.account_balance_wallet,
          color: category?.color),
      title: Text(title),
      subtitle: Text(limit != null
          ? 'Limit: \$${limit.amount.toStringAsFixed(2)}'
          : 'No limit set'),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _showEditDialog(context, ref, limit, category, now),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    BudgetLimit? limit,
    ExpenseCategory? category,
    DateTime now,
  ) {
    final controller =
        TextEditingController(text: limit?.amount.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set ${category?.label ?? 'Total'} Budget'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(labelText: 'Amount', prefixText: '\$'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              final newLimit = BudgetLimit(
                id: limit?.id ?? const Uuid().v4(),
                amount: amount,
                category: category,
                month: now.month,
                year: now.year,
              );
              ref.read(budgetLimitsProvider.notifier).saveLimit(newLimit);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
