import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/expense_provider.dart';
import '../widgets/budget_overview.dart';
import '../widgets/add_expense_sheet.dart';
import '../../data/models/expense.dart';
import 'budget_settings_page.dart';
import '../widgets/expense_calendar_view.dart';
import '../../../accounts/presentation/pages/accounts_overview_page.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../accounts/data/models/account.dart';
import '../../../sharing/presentation/providers/expense_sync_provider.dart';
import '../../../sharing/presentation/providers/firestore_sharing_provider.dart';

final expenseViewModeProvider =
    StateProvider<bool>((ref) => false); // false = List, true = Calendar

final selectedPoolProvider =
    StateProvider<String?>((ref) => null); // null = All Accounts

class ExpenseListPage extends ConsumerWidget {
  const ExpenseListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppTheme.expensesColor,
        title: Text('Everyday Expenses',
            style: TextStyle(
                color: AppTheme.getSurfaceColor(context),
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(expenseViewModeProvider)
                  ? Icons.view_list_rounded
                  : Icons.calendar_month_rounded,
              color: AppTheme.getSurfaceColor(context),
            ),
            onPressed: () {
              ref.read(expenseViewModeProvider.notifier).state =
                  !ref.read(expenseViewModeProvider.notifier).state;
            },
          ),
          IconButton(
            icon:
                Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
            tooltip: 'Manage Accounts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AccountsOverviewPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BudgetSettingsPage()),
              );
            },
          ),
        ],
      ),
      body: ref.watch(expenseViewModeProvider)
          ? expensesAsync.when(
              data: (expenses) => ExpenseCalendarView(expenses: expenses),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            )
          : CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: BudgetOverview(),
                ),
                SliverToBoxAdapter(
                  child: _AccountSelector(),
                ),
                // Shared Expenses Section
                SliverToBoxAdapter(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final sharedExpensesAsync =
                          ref.watch(sharedExpensesProvider);

                      return sharedExpensesAsync.when(
                        data: (sharedExpenses) {
                          if (sharedExpenses.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 16, 24, 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.people_outline_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Shared Expenses',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${sharedExpenses.length}',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  children: sharedExpenses.map((expense) {
                                    // Find the owner's info for this expense
                                    final sharedWithMeAsync =
                                        ref.watch(usersSharedWithMeProvider);
                                    final ownerEmail = sharedWithMeAsync.when(
                                      data: (relationships) {
                                        if (relationships.isEmpty) return '';

                                        try {
                                          final relationship =
                                              relationships.firstWhere(
                                            (r) => r.ownerId == expense.userId,
                                          );
                                          return relationship.ownerEmail;
                                        } catch (e) {
                                          // No matching relationship found
                                          return relationships.isNotEmpty
                                              ? relationships.first.ownerEmail
                                              : '';
                                        }
                                      },
                                      loading: () => '',
                                      error: (_, __) => '',
                                    );

                                    return ExpenseCard(
                                      expense: expense,
                                      isShared: true,
                                      sharedByEmail: ownerEmail,
                                      onTap:
                                          null, // Read-only for shared expenses
                                      onLongPress: null,
                                    );
                                  }).toList(),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Divider(height: 1),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          'My Expenses',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextColor(context)),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                expensesAsync.when(
                  data: (allExpenses) {
                    final selectedPool = ref.watch(selectedPoolProvider);
                    final expenses = selectedPool == null
                        ? allExpenses
                        : allExpenses
                            .where((e) => e.linkedAccount == selectedPool)
                            .toList();

                    if (expenses.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 80,
                                  color: AppTheme.getTextColor(context,
                                      opacity: 0.15)),
                              SizedBox(height: 20),
                              Text(
                                'No expenses tracked yet',
                                style: TextStyle(
                                    color: AppTheme.getTextColor(context,
                                        opacity: 0.4),
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final expense = expenses[index];
                            return ExpenseCard(
                              expense: expense,
                              isShared: false,
                            );
                          },
                          childCount: expenses.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                    child: Center(child: Text('Error: $err')),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expenses_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const AddExpenseSheet(),
          );
        },
        label:
            Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ).animate().scale(delay: 500.ms),
    );
  }
}

class _AccountSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final selectedPool = ref.watch(selectedPoolProvider);

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _AccountChip(
                label: 'All Accounts',
                isSelected: selectedPool == null,
                onTap: () =>
                    ref.read(selectedPoolProvider.notifier).state = null,
                icon: Icons.all_inclusive_rounded,
                color: AppTheme.expensesColor,
              ),
              ...accounts.map((account) => _AccountChip(
                    label: account.name,
                    isSelected: selectedPool == account.id,
                    onTap: () => ref.read(selectedPoolProvider.notifier).state =
                        account.id,
                    icon: account.type.icon,
                    color: account.type.color,
                  )),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AccountChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  const _AccountChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FilterChip(
        showCheckmark: false,
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: color,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? color : AppTheme.getBorderColor(context),
          ),
        ),
      ),
    );
  }
}

class ExpenseCard extends ConsumerWidget {
  final Expense expense;
  final bool isShared;
  final String? sharedByEmail;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.isShared = false,
    this.sharedByEmail,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve account name
    final accountsAsync = ref.watch(accountsProvider);
    final accountName = accountsAsync.when(
      data: (accounts) {
        final account = accounts.firstWhere(
          (a) => a.id == expense.linkedAccount,
          orElse: () =>
              Account(id: '', name: 'General', type: AccountType.personal),
        );
        return account.name;
      },
      loading: () => '...',
      error: (_, __) => 'Error',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            isShared ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isShared
            ? Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: expense.category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(expense.category.icon, color: expense.category.color),
            ),
            title: Text(
              expense.category.label,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM dd').format(expense.date) +
                        (expense.notes?.isNotEmpty == true
                            ? ' • ${expense.notes}'
                            : ''),
                    style: TextStyle(
                        color: AppTheme.getTextColor(context, opacity: 0.5),
                        fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 10, color: AppTheme.accountsColor),
                      const SizedBox(width: 4),
                      Text(
                        accountName,
                        style: const TextStyle(
                          color: AppTheme.accountsColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: Text(
              '${expense.isIncome ? '+' : '-'}${NumberFormat.simpleCurrency(name: expense.currency, decimalDigits: 0).format(expense.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: expense.isIncome ? Colors.green : Colors.black87,
              ),
            ),
            onTap: onTap ??
                (isShared
                    ? null
                    : () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) =>
                              AddExpenseSheet(expense: expense),
                        );
                      }),
            onLongPress: onLongPress ??
                (isShared
                    ? null
                    : () {
                        _showDeleteDialog(context, ref);
                      }),
          ),
          if (isShared)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: AppTheme.getSurfaceColor(context),
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      sharedByEmail?.isNotEmpty == true
                          ? sharedByEmail!.split('@').first
                          : 'Shared',
                      style: TextStyle(
                        color: AppTheme.getSurfaceColor(context),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Expense?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(expensesProvider.notifier).deleteExpense(expense.id);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: AppTheme.dangerColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
