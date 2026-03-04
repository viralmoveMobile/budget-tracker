import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import '../../../expenses/data/models/expense.dart';
import '../../../expenses/data/models/expense_category.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../expenses/presentation/providers/budget_provider.dart';
import '../../../analytics/presentation/providers/goal_provider.dart';
import '../../../../core/services/rating_service.dart';
import '../../../../core/presentation/widgets/sidebar_menu.dart';
import '../../../cash_book/presentation/pages/cash_book_page.dart';
import 'package:budget_tracking_app/features/my_account/presentation/providers/profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:budget_tracking_app/core/theme/app_spacing.dart';
import 'package:budget_tracking_app/core/utils/currency_formatter.dart';

final timeRangeProvider = StateProvider<String>((ref) => 'Weekly');


class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final profile = ref.watch(profileProvider);
    final selectedRange = ref.watch(timeRangeProvider);
    final budgetUsage = ref.watch(budgetUsageProvider);
    final goalsAsync = ref.watch(goalsProvider);

    // Calculate real data based on timeRangeProvider
    double totalExpense = 0;
    double totalIncome = 0;
    double foodExpense = 0;

    if (expensesAsync.hasValue && expensesAsync.value != null) {
      final now = DateTime.now();
      final expenses = expensesAsync.value!;

      Iterable<Expense> filteredExpenses;
      if (selectedRange == 'Daily') {
        filteredExpenses = expenses.where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day);
      } else if (selectedRange == 'Weekly') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        filteredExpenses = expenses.where((e) =>
            e.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            e.date.isBefore(endOfWeek.add(const Duration(days: 1))));
      } else {
        // Monthly
        filteredExpenses = expenses
            .where((e) => e.date.year == now.year && e.date.month == now.month);
      }

      for (var e in filteredExpenses) {
        if (e.isIncome) {
          totalIncome += e.amount;
        } else {
          totalExpense += e.amount;
          if (e.category == ExpenseCategory.food) {
            foodExpense += e.amount;
          }
        }
      }
    }

    // Budget data
    final budgetLimit = (budgetUsage?['totalLimit'] as double?) ?? 0;
    final budgetSpent = (budgetUsage?['totalSpent'] as double?) ?? 0;
    final budgetPercent =
        budgetLimit > 0 ? (budgetSpent / budgetLimit).clamp(0.0, 1.0) : 0.0;
    final budgetText = budgetLimit > 0
        ? '${(budgetPercent * 100).toInt()}% Used (Limit: ${CurrencyFormatter.format(budgetLimit, profile.currency)})'
        : 'No budget set';

    // Goals data
    double goalsProgress = 0;
    if (goalsAsync.hasValue &&
        goalsAsync.value != null &&
        goalsAsync.value!.isNotEmpty) {
      double totalCurrent = 0;
      double totalTarget = 0;
      for (var g in goalsAsync.value!) {
        totalCurrent += g.currentAmount;
        totalTarget += g.targetAmount;
      }
      goalsProgress =
          totalTarget > 0 ? (totalCurrent / totalTarget).clamp(0.0, 1.0) : 0;
    }

    // Check and show rating dialog after data loads
    ref.listen(expensesProvider, (previous, next) {
      if (next.hasValue && context.mounted) {
        // Delay to avoid showing immediately
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            RatingService.instance.checkAndShowRating(context);
          }
        });
      }
    });

    return AppScaffold(
      withTealHeader: true,
      drawer: const SidebarMenu(),
      appBar: AppAppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: _buildGreetingTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'Cash Ledger',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CashBookPage()),
              );
            },
          ),
          AppSpacing.gapXs,
        ],
      ),
      heroContent: Padding(
        padding: AppSpacing.listItemPadding,
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

            // Monthly Budget Progress Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Budget',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      Container(
                        height: 10,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                flex: (budgetPercent * 100).toInt() + 1,
                                child: Container(
                                    color: budgetPercent > 0.9
                                        ? AppTheme.dangerColor
                                        : Colors.white)),
                            Expanded(
                                flex: 100 - (budgetPercent * 100).toInt(),
                                child: const SizedBox()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(budgetText,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Goals and Categories Card
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSpacing.r16),
              ),
              child: Row(
                children: [
                  // Left Side: Savings On Goals
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 70,
                          width: 70,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 70,
                                width: 70,
                                child: CircularProgressIndicator(
                                  value: goalsProgress,
                                  strokeWidth: 5,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                ),
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.emoji_events_rounded,
                                    color: AppTheme.primaryColor, size: 20),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.gapSm,
                        const Text('Goals Progress',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${(goalsProgress * 100).toInt()}%',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // Vertical Divider
                  Container(
                      width: 1,
                      height: 80,
                      color: Colors.white.withOpacity(0.3)),

                  // Right Side
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Revenue
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.attach_money_rounded,
                                    color: Colors.white, size: 16),
                              ),
                              AppSpacing.gapSm,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Revenue',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text(
                                      CurrencyFormatter.format(totalIncome, profile.currency),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                ],
                              )
                            ],
                          ),
                          AppSpacing.gapSm,
                          Divider(
                              color: Colors.white.withOpacity(0.2), height: 1),
                          AppSpacing.gapSm,
                          // Food
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.restaurant_rounded,
                                    color: Colors.white, size: 16),
                              ),
                              AppSpacing.gapSm,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Food Expense',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text(
                                      foodExpense > 0
                                          ? '-${CurrencyFormatter.format(foodExpense, profile.currency)}'
                                          : CurrencyFormatter.format(0, profile.currency),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.only(left: 20, right: 20, top: 32, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const Center(
                      child: Text('No transactions yet.',
                          style: TextStyle(color: AppTheme.textSecondary)));
                }

                // Temporary logic: Simply list all expenses for now. Grouping by month can be added later if needed.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Range Toggle
                    Consumer(
                      builder: (context, ref, child) {
                        final selectedRange = ref.watch(timeRangeProvider);
                        final ranges = ['Daily', 'Weekly', 'Monthly'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.r24),
                          ),
                          child: Row(
                            children: ranges.map((range) {
                              final isSelected = selectedRange == range;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => ref
                                      .read(timeRangeProvider.notifier)
                                      .state = range,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        range,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : AppTheme.textSecondary,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...expenses.take(10).map((expense) => _buildTransactionItem(
                        context, expense, profile.currency)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
      BuildContext context, Expense expense, String currencyCode) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
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
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.notes?.isNotEmpty == true
                            ? expense.notes!
                            : 'Transaction',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spaceXs),
                      Text(
                        DateFormat('HH:mm - MMM dd').format(expense.date),
                        style: AppTheme.smallStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (expense.isIncome ? '+' : '-') +
                    CurrencyFormatter.format(expense.amount, currencyCode),
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w800,
                  color: expense.isIncome
                      ? AppTheme.successColor
                      : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXs),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSm, vertical: AppTheme.spaceXs),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  expense.category.label,
                  style: AppTheme.smallStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingTitle() {
    final hour = DateTime.now().hour;
    final String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first ?? 'there';
    // Capitalize first letter only
    final displayName = name.isNotEmpty
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : 'there';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Hi, $displayName 👋',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          greeting,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}