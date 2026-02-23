import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../expenses/data/models/expense.dart';
import '../../../cash_book/domain/models/cash_book_entry.dart';
import '../../../expenses/data/models/budget_limit.dart';
import '../providers/expense_sync_provider.dart';
import '../providers/cash_book_sync_provider.dart';
import '../providers/budget_sync_provider.dart';

import 'package:budget_tracking_app/features/my_account/presentation/providers/profile_provider.dart';

class MemberDetailPage extends ConsumerStatefulWidget {
  final String memberName;
  final String memberEmail;
  final String memberId;

  const MemberDetailPage({
    super.key,
    required this.memberName,
    required this.memberEmail,
    required this.memberId,
  });

  @override
  ConsumerState<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends ConsumerState<MemberDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.memberName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.memberEmail,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Colors.white,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Expenses'),
            Tab(icon: Icon(Icons.book_rounded), text: 'Cash Book'),
            Tab(icon: Icon(Icons.savings_rounded), text: 'Budgets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpensesTab(),
          _buildCashBookTab(),
          _buildBudgetsTab(),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    final expensesAsync =
        ref.watch(sharedExpensesByUserProvider(widget.memberId));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return _buildEmptyState(
            'No Expenses Shared',
            Icons.receipt_long_rounded,
            AppTheme.expensesColor,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return _buildExpenseCard(expense);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildErrorState('Error loading expenses: $err'),
    );
  }

  Widget _buildCashBookTab() {
    final entriesAsync =
        ref.watch(sharedCashBookEntriesByUserProvider(widget.memberId));

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyState(
            'No Cash Book Entries Shared',
            Icons.book_rounded,
            AppTheme.accountsColor,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildCashBookCard(entry);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildErrorState('Error loading cash book: $err'),
    );
  }

  Widget _buildBudgetsTab() {
    final budgetsAsync =
        ref.watch(sharedBudgetsByUserProvider(widget.memberId));

    return budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) {
          return _buildEmptyState(
            'No Budgets Shared',
            Icons.savings_rounded,
            AppTheme.primaryColor,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            return _buildBudgetCard(budget);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildErrorState('Error loading budgets: $err'),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: expense.category.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: expense.category.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(expense.category.icon, color: expense.category.color),
        ),
        title: Text(
          expense.category.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(expense.date),
              style: TextStyle(
                  color: AppTheme.getTextColor(context, isSecondary: true),
                  fontSize: 12),
            ),
            if (expense.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(
                expense.notes!,
                style: TextStyle(
                    color: AppTheme.getTextColor(context,
                        isSecondary: true, opacity: 0.9),
                    fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Text(
          '${expense.isIncome ? '+' : '-'}${NumberFormat.simpleCurrency(name: expense.currency).format(expense.amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: expense.isIncome ? Colors.green : Colors.red[700],
          ),
        ),
      ),
    );
  }

  Widget _buildCashBookCard(CashBookEntry entry) {
    final currency = ref.watch(profileProvider).currency;
    final isInflow = entry.type == CashBookEntryType.inflow;
    final color = isInflow ? Colors.green : Colors.red[700]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isInflow
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: color,
          ),
        ),
        title: Text(
          entry.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(entry.date),
              style: TextStyle(
                  color: AppTheme.getTextColor(context, isSecondary: true),
                  fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              entry.category,
              style: TextStyle(
                color: AppTheme.getTextColor(context,
                    isSecondary: true, opacity: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${isInflow ? '+' : '-'}${NumberFormat.simpleCurrency(name: currency).format(entry.amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BudgetLimit budget) {
    final currency = ref.watch(profileProvider).currency;
    final categoryName = budget.category?.label ?? 'Overall Budget';
    final categoryColor = budget.category?.color ?? AppTheme.primaryColor;
    final period = '${_getMonthName(budget.month)} ${budget.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            budget.category?.icon ?? Icons.savings_rounded,
            color: categoryColor,
          ),
        ),
        title: Text(
          categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              period,
              style: TextStyle(
                  color: AppTheme.getTextColor(context, isSecondary: true),
                  fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormat.simpleCurrency(name: currency).format(budget.amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: categoryColor,
              ),
            ),
            Text(
              'Budget',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.getTextColor(context,
                    isSecondary: true, opacity: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppTheme.getTextColor(context, isSecondary: true),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.memberName} hasn\'t shared any data yet',
            style: TextStyle(
                color: AppTheme.getTextColor(context,
                    isSecondary: true, opacity: 0.9),
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
