import 'dart:io';
import 'package:budget_tracking_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/holiday_provider.dart';
import '../../domain/models/holiday.dart';
import '../../domain/models/holiday_expense.dart';
import '../widgets/add_holiday_expense_sheet.dart';
import '../../../common/services/location_service.dart';

class HolidayDetailPage extends ConsumerWidget {
  final Holiday holiday;

  const HolidayDetailPage({super.key, required this.holiday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(holidayExpensesProvider(holiday.id));
    final homeCurrencyAsync = ref.watch(primaryCurrencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(holiday.name),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: homeCurrencyAsync.when(
        data: (homeCurrency) => expensesAsync.when(
          data: (expenses) {
            final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
            final remaining = holiday.totalBudget - totalSpent;
            final isOverspent = totalSpent > holiday.totalBudget;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(context, totalSpent, remaining, isOverspent,
                      homeCurrency),
                  SizedBox(height: 32),
                  _buildCategoryBreakdown(context, expenses, homeCurrency),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expenses',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddExpense(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (expenses.isEmpty)
                     Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text(
                          'No expenses recorded yet',
                          style: TextStyle(
                              color: AppTheme.getTextColor(context,
                                  isSecondary: true)),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return _ExpenseTile(
                          expense: expense,
                          homeCurrency: homeCurrency,
                          convertedAmount: expense.amount,
                        );
                      },
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'holiday_detail_fab',
        onPressed: () => _showAddExpense(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double spent, double remaining,
      bool isOver, String homeCurrency) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(
                  context,
                  'Budget',
                  '$homeCurrency ${holiday.totalBudget.toStringAsFixed(0)}',
                  Colors.blue),
              _buildMetric(
                  context,
                  'Spent',
                  '$homeCurrency ${spent.toStringAsFixed(0)}',
                  isOver ? Colors.red : Colors.green),
              _buildMetric(
                  context,
                  'Remaining',
                  '$homeCurrency ${remaining.abs().toStringAsFixed(0)}',
                  remaining >= 0 ? Colors.blue : Colors.red,
                  label: remaining >= 0 ? 'Remaining' : 'Overspent'),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (spent / holiday.totalBudget).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(
                  isOver ? Colors.red : Colors.blue),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildMetric(
      BuildContext context, String title, String value, Color color,
      {String? label}) {
    return Column(
      children: [
        Text(label ?? title,
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextColor(context, isSecondary: true))),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context,
      List<HolidayExpense> expenses, String homeCurrency) {
    final Map<HolidayExpenseCategory, double> data = {};
    for (var cat in HolidayExpenseCategory.values) {
      data[cat] = expenses
          .where((e) => e.category == cat)
          .fold(0.0, (sum, e) => sum + e.amount);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: data.entries.map((entry) {
            if (entry.value == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: entry.key.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: entry.key.color.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(entry.key.icon, size: 18, color: entry.key.color),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key.label}: $homeCurrency ${entry.value.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: entry.key.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => AddHolidayExpenseSheet(holidayId: holiday.id),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Holiday?'),
        content: const Text(
            'This will remove all expenses as well. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(holidayListProvider.notifier).deleteHoliday(holiday.id);
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Detail Page
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends ConsumerWidget {
  final HolidayExpense expense;
  final String homeCurrency;
  final double convertedAmount;

  const _ExpenseTile({
    required this.expense,
    required this.homeCurrency,
    required this.convertedAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: AppTheme.getBorderColor(context, opacity: 0.3)!),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: expense.category.color.withOpacity(0.1),
          child: Icon(expense.category.icon,
              color: expense.category.color, size: 20),
        ),
        title: Text(expense.description,
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('MMM d, y').format(expense.date)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${homeCurrency} ${convertedAmount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (expense.originalAmount != null)
              Text(
                '${expense.originalAmount!.toStringAsFixed(2)} ${expense.currency}',
                style: TextStyle(
                    color: AppTheme.getBorderColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w400),
              ),
          ],
        ),
        children: [
          if (expense.receiptPath != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Receipt',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(expense.receiptPath!),
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Text('Receipt image missing')),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _confirmExpenseDelete(context, ref),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmExpenseDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref
                  .read(holidayExpensesNotifierProvider)
                  .deleteExpense(expense.id, expense.holidayId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
