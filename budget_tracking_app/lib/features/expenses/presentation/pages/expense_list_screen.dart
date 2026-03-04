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
import '../../../my_account/presentation/providers/profile_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:budget_tracking_app/core/utils/currency_formatter.dart';

final expenseViewModeProvider =
    StateProvider<bool>((ref) => false); // false = List, true = Calendar

final selectedPoolProvider =
    StateProvider<String?>((ref) => null); // null = All Accounts


class ExpenseListPage extends ConsumerWidget {
  const ExpenseListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final profile = ref.watch(profileProvider);

    final double totalExpense = expensesAsync.value
            ?.where((e) => !e.isIncome)
            .fold<double>(0.0, (sum, expense) => sum + expense.amount) ??
        0.0;

    final double totalIncome = expensesAsync.value
            ?.where((e) => e.isIncome)
            .fold<double>(0.0, (sum, income) => sum + income.amount) ??
        0.0;
    return AppScaffold(
      withTealHeader: true,
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppAppBar(
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
      heroContent: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Column(
          children: [
            // Income / Expense Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.call_made_rounded,
                              size: 14, color: Colors.white.withOpacity(0.9)),
                          AppSpacing.gapXs,
                          Text('Total Income',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      AppSpacing.gapXs,
                      Text(
                        CurrencyFormatter.format(totalIncome, profile.currency),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
                Container(
                    width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                AppSpacing.gapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.call_received_rounded,
                              size: 14, color: Colors.white.withOpacity(0.9)),
                          AppSpacing.gapXs,
                          Text('Total Expenses',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      AppSpacing.gapXs,
                      Text(
                        CurrencyFormatter.format(totalExpense, profile.currency),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapLg,
          ],
        ),
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
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.people_outline_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                    AppSpacing.gapSm,
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
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppSpacing.r12),
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
                              AppSpacing.gapXs,
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg),
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
                                padding: AppSpacing.cardPadding,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          'My Expenses',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
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
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.5)),
                              AppSpacing.gapLg,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r24),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.withOpacity(0.2),
            width: 1,
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

    return GestureDetector(
      onTap: onTap ??
          (isShared
              ? null
              : () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => AddExpenseSheet(expense: expense),
                  );
                }),
      onLongPress: onLongPress ??
          (isShared
              ? null
              : () {
                  _showDeleteDialog(context, ref);
                }),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          color: isShared
              ? AppTheme.primaryColor.withOpacity(0.05)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isShared)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
          border: isShared
              ? Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: expense.isIncome
                              ? AppTheme.successColor.withOpacity(0.1)
                              : AppTheme.dangerColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          expense.isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: expense.isIncome
                              ? AppTheme.successColor
                              : AppTheme.dangerColor,
                          size: 24,
                        ),
                      ),
                      AppSpacing.gapLg,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.notes?.isNotEmpty == true
                                  ? expense.notes!
                                  : expense.category.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppTheme.spaceXs),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    DateFormat('HH:mm - MMM dd')
                                        .format(expense.date),
                                    style: AppTheme.smallStyle,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Icon(Icons.account_balance_wallet_outlined,
                                    size: 10, color: AppTheme.accountsColor),
                                const SizedBox(width: AppTheme.spaceXs),
                                Flexible(
                                  child: Text(
                                    accountName,
                                    style: AppTheme.smallStyle.copyWith(
                                      color: AppTheme.accountsColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapLg,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      (expense.isIncome ? '+' : '-') +
                          CurrencyFormatter.format(expense.amount, expense.currency),
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.w800,
                        color: expense.isIncome
                            ? AppTheme.successColor
                            : AppTheme.textPrimary,
                      ),
                    ),
                    AppSpacing.gapXs,
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        expense.category.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isShared)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        color: AppTheme.getSurfaceColor(context),
                        size: 10,
                      ),
                      AppSpacing.gapXs,
                      Text(
                        sharedByEmail?.isNotEmpty == true
                            ? sharedByEmail!.split('@').first
                            : 'Shared',
                        style: TextStyle(
                          color: AppTheme.getSurfaceColor(context),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.r24)),
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