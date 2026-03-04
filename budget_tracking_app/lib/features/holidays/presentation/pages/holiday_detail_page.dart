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
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';

class HolidayDetailPage extends ConsumerWidget {
  final Holiday holiday;

  const HolidayDetailPage({super.key, required this.holiday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(holidayExpensesProvider(holiday.id));
    final homeCurrencyAsync = ref.watch(primaryCurrencyProvider);

    return AppScaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppAppBar(
        title: Text(holiday.name,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
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
                  AppSpacing.gapXxl,
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
                  AppSpacing.gapLg,
                  if (expenses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.receipt_long_rounded,
                                  size: 48, color: AppTheme.primaryColor),
                            ),
                            AppSpacing.gapXl,
                            Text(
                              'No Expenses Yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                            AppSpacing.gapSm,
                            Text(
                              'Tap the + button below to add your first holiday expense.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.getTextColor(context,
                                    isSecondary: true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().scale(delay: 200.ms)
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
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double spent, double remaining,
      bool isOver, String homeCurrency) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
            color: AppTheme.getBorderColor(context, opacity: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMetric(
                    context,
                    'Budget',
                    '$homeCurrency ${holiday.totalBudget.toStringAsFixed(0)}',
                    AppTheme.getTextColor(context),
                    crossAxisAlignment: CrossAxisAlignment.start),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: _buildMetric(
                    context,
                    'Spent',
                    '$homeCurrency ${spent.toStringAsFixed(0)}',
                    isOver
                        ? AppTheme.dangerColor
                        : AppTheme.getTextColor(context),
                    crossAxisAlignment: CrossAxisAlignment.center),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: _buildMetric(
                    context,
                    'Remaining',
                    '$homeCurrency ${remaining.abs().toStringAsFixed(0)}',
                    remaining >= 0
                        ? AppTheme.primaryColor
                        : AppTheme.dangerColor,
                    label: remaining >= 0 ? 'Remaining' : 'Overspent',
                    crossAxisAlignment: CrossAxisAlignment.end),
              ),
            ],
          ),
          AppSpacing.gapXxl,
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.getBorderColor(context, opacity: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (spent /
                        (holiday.totalBudget > 0 ? holiday.totalBudget : 1))
                    .clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isOver ? AppTheme.dangerColor : AppTheme.primaryColor,
                        (isOver ? AppTheme.dangerColor : AppTheme.primaryColor)
                            .withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: (isOver
                                ? AppTheme.dangerColor
                                : AppTheme.primaryColor)
                            .withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildMetric(
      BuildContext context, String title, String value, Color color,
      {String? label,
      CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label ?? title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context, isSecondary: true))),
        AppSpacing.gapSm,
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5),
          ),
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
        AppSpacing.gapLg,
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: data.entries.map((entry) {
            if (entry.value == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: entry.key.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.r16),
                border: Border.all(color: entry.key.color.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(entry.key.icon, size: 18, color: entry.key.color),
                  AppSpacing.gapSm,
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
        backgroundColor: AppTheme.getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.r24)),
        title: Text('Delete Holiday?',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context))),
        content: Text(
            'This will remove all expenses as well. This action cannot be undone.',
            style: TextStyle(
                color: AppTheme.getTextColor(context, isSecondary: true))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: AppTheme.getTextColor(context)))),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.dangerColor.withOpacity(0.1),
              foregroundColor: AppTheme.dangerColor,
            ),
            onPressed: () {
              ref.read(holidayListProvider.notifier).deleteHoliday(holiday.id);
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Detail Page
            },
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(AppSpacing.r24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
            color: AppTheme.getBorderColor(context, opacity: 0.2), width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: AppSpacing.listItemPadding,
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: expense.category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.r16),
            ),
            child: Icon(expense.category.icon,
                color: expense.category.color, size: 24),
          ),
          title: Text(expense.description,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.getTextColor(context))),
          subtitle: Text(DateFormat('MMM d, y').format(expense.date),
              style: TextStyle(
                  color: AppTheme.getTextColor(context, isSecondary: true),
                  fontSize: 12)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$homeCurrency ${convertedAmount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: expense.category.color),
              ),
              if (expense.originalAmount != null)
                Text(
                  '${expense.originalAmount!.toStringAsFixed(2)} ${expense.currency}',
                  style: TextStyle(
                      color: AppTheme.getTextColor(context, opacity: 0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
            ],
          ),
          children: [
            if (expense.receiptPath != null)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.getBorderColor(context, opacity: 0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(expense.receiptPath!),
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(32),
                      color: AppTheme.getBorderColor(context, opacity: 0.1),
                      child: const Center(
                          child: Text('Receipt image missing',
                              style: TextStyle(color: Colors.grey))),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.dangerColor,
                      backgroundColor: AppTheme.dangerColor.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r12)),
                    ),
                    onPressed: () => _confirmExpenseDelete(context, ref),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }

  void _confirmExpenseDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.r24)),
        title: Text('Delete Expense?',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: AppTheme.getTextColor(context)))),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.dangerColor.withOpacity(0.1),
              foregroundColor: AppTheme.dangerColor,
            ),
            onPressed: () {
              ref
                  .read(holidayExpensesNotifierProvider)
                  .deleteExpense(expense.id, expense.holidayId);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
