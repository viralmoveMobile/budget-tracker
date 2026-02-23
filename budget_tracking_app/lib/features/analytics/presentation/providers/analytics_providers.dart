import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/analytics_data.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../expenses/presentation/providers/budget_provider.dart';
import '../../../expenses/data/models/expense_category.dart';
import '../../../cash_book/presentation/providers/cash_book_provider.dart';
import '../../../cash_book/domain/models/cash_book_entry.dart';
import '../../../common/services/location_service.dart';
import '../../../exchange/data/services/currency_api_service.dart';

final timeRangeProvider =
    StateProvider<String>((ref) => 'Monthly'); // 'Weekly', 'Monthly', 'Yearly'

final analyticsDashboardProvider =
    FutureProvider<AnalyticsDashboardData>((ref) async {
  final expensesAsync = ref.watch(expensesProvider);
  final cashEntriesAsync = ref.watch(cashBookProvider);
  final budgetLimitsAsync = ref.watch(budgetLimitsProvider);

  final expenses = expensesAsync.value ?? [];
  final cashEntries = cashEntriesAsync.value ?? [];
  final limits = budgetLimitsAsync.value ?? [];

  // 0. Get Real-time Exchange Rates for Conversion
  final homeCurrency = await ref.watch(primaryCurrencyProvider.future);
  final rates =
      await ref.read(currencyApiServiceProvider).getRateMap(homeCurrency);

  double convert(double amount, String from) {
    if (from == homeCurrency) return amount;
    final rate = rates[from] ?? 1.0;
    return amount /
        rate; // Since rates are base -> foreign, we divide to get base
  }

  // 1. Spending Distribution (Pie Chart) - Only Expenses
  final Map<String, double> categoryMap = {};
  final List<Color> palette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber
  ];

  for (final e in expenses) {
    if (e.isIncome) continue;
    final catKey = e.category.label;
    final homeAmount = convert(e.amount, e.currency);
    categoryMap[catKey] = (categoryMap[catKey] ?? 0) + homeAmount;
  }

  final List<CategorySpending> distribution = [];
  int colorIdx = 0;
  categoryMap.forEach((cat, amt) {
    distribution.add(CategorySpending(
      category: cat,
      amount: amt,
      color: palette[colorIdx % palette.length],
    ));
    colorIdx++;
  });

  // 2. Budget Performance
  final now = DateTime.now();
  final currentMonthExpenses = expenses
      .where((e) => e.date.month == now.month && e.date.year == now.year)
      .toList();

  final List<CategoryPerformance> performanceItems = [];
  for (final cat in ExpenseCategory.values) {
    final spent = currentMonthExpenses
        .where((e) => e.category == cat && !e.isIncome)
        .fold(0.0, (sum, e) => sum + convert(e.amount, e.currency));

    final limit = limits
        .where((l) => l.category == cat)
        .fold(0.0, (sum, l) => sum + l.amount);

    if (spent > 0 || limit > 0) {
      performanceItems.add(CategoryPerformance(
        category: cat,
        spent: spent,
        budget: limit,
        percentage: limit > 0 ? spent / limit : 0,
      ));
    }
  }
  // Sort by percentage descending
  performanceItems.sort((a, b) => b.percentage.compareTo(a.percentage));

  // 3. Monthly Trends
  final Map<String, MonthlyTrend> trendMap = {};
  for (int i = 5; i >= 0; i--) {
    final date = DateTime(now.year, now.month - i, 1);
    final monthKey = DateFormat('MMM').format(date);
    trendMap[monthKey] = MonthlyTrend(month: monthKey, income: 0, expense: 0);
  }

  for (final e in expenses) {
    final monthKey = DateFormat('MMM').format(e.date);
    if (trendMap.containsKey(monthKey)) {
      final current = trendMap[monthKey]!;
      final homeAmount = convert(e.amount, e.currency);
      if (e.isIncome) {
        trendMap[monthKey] = MonthlyTrend(
          month: monthKey,
          income: current.income + homeAmount,
          expense: current.expense,
        );
      } else {
        trendMap[monthKey] = MonthlyTrend(
          month: monthKey,
          income: current.income,
          expense: current.expense + homeAmount,
        );
      }
    }
  }

  for (final c in cashEntries) {
    final monthKey = DateFormat('MMM').format(c.date);
    if (trendMap.containsKey(monthKey)) {
      final current = trendMap[monthKey]!;
      final homeAmount = convert(
          c.amount, 'USD'); // Assuming cash book is in USD or needs detection
      if (c.type == CashBookEntryType.inflow) {
        trendMap[monthKey] = MonthlyTrend(
          month: monthKey,
          income: current.income + homeAmount,
          expense: current.expense,
        );
      } else {
        trendMap[monthKey] = MonthlyTrend(
          month: monthKey,
          income: current.income,
          expense: current.expense + homeAmount,
        );
      }
    }
  }

  final List<MonthlyTrend> trends = trendMap.values.toList();
  double totalIncome = 0;
  double totalExpense = 0;
  for (final trend in trends) {
    totalIncome += trend.income;
    totalExpense += trend.expense;
  }

  // 4. Generate Insights
  final List<FinancialInsight> insights = [];

  // Over budget insight
  final overBudget = performanceItems.where((p) => p.percentage > 1.0).toList();
  if (overBudget.isNotEmpty) {
    insights.add(FinancialInsight(
      title: 'Over Budget Alert',
      message:
          'You have exceeded your budget in ${overBudget.length} categories, especially ${overBudget.first.category.label}.',
      icon: Icons.warning_amber_rounded,
      color: Colors.red,
    ));
  }

  // Leisure spike check (Simplified spike check)
  final leisurePerformance = performanceItems
      .where((p) => p.category == ExpenseCategory.leisure)
      .firstOrNull;
  if (leisurePerformance != null && leisurePerformance.percentage > 0.9) {
    insights.add(FinancialInsight(
      title: 'Leisure Warning',
      message:
          'Your leisure spending is at ${(leisurePerformance.percentage * 100).toStringAsFixed(0)}% of budget. Be careful!',
      icon: Icons.sports_esports_outlined,
      color: Colors.orange,
    ));
  }

  // Savings insight
  final savings = totalIncome - totalExpense;
  if (savings > 0) {
    insights.add(FinancialInsight(
      title: 'Good Progress',
      message:
          'You have saved \$${savings.toStringAsFixed(0)} over the last 6 months. Keep it up!',
      icon: Icons.trending_up_rounded,
      color: Colors.green,
    ));
  } else if (totalExpense > totalIncome) {
    insights.add(FinancialInsight(
      title: 'Spending Pattern',
      message:
          'Your expenses exceed your income in the tracked period. Review your fixed costs.',
      icon: Icons.info_outline,
      color: Colors.blue,
    ));
  }

  if (insights.isEmpty) {
    insights.add(FinancialInsight(
      title: 'System Analyzed',
      message:
          'Keep tracking your daily expenses to get personalized financial advice.',
      icon: Icons.insights_rounded,
      color: Colors.grey,
    ));
  }

  return AnalyticsDashboardData(
    spendingDistribution: distribution,
    monthlyTrends: trends,
    performance: performanceItems,
    insights: insights,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
  );
});
