import 'package:flutter/material.dart';
import '../../../expenses/data/models/expense_category.dart';

class CategorySpending {
  final String category;
  final double amount;
  final Color color;

  CategorySpending({
    required this.category,
    required this.amount,
    required this.color,
  });
}

class CategoryPerformance {
  final ExpenseCategory category;
  final double spent;
  final double budget;
  final double percentage; // spent / budget

  CategoryPerformance({
    required this.category,
    required this.spent,
    required this.budget,
    required this.percentage,
  });

  Color get performanceColor {
    if (percentage > 1.0) return Colors.red;
    if (percentage > 0.8) return Colors.orange;
    return Colors.green;
  }
}

class FinancialInsight {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  FinancialInsight({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

class MonthlyTrend {
  final String month;
  final double income;
  final double expense;

  MonthlyTrend({
    required this.month,
    required this.income,
    required this.expense,
  });
}

class AnalyticsDashboardData {
  final List<CategorySpending> spendingDistribution;
  final List<MonthlyTrend> monthlyTrends;
  final List<CategoryPerformance> performance;
  final List<FinancialInsight> insights;
  final double totalIncome;
  final double totalExpense;

  double get netBalance => totalIncome - totalExpense;

  AnalyticsDashboardData({
    required this.spendingDistribution,
    required this.monthlyTrends,
    required this.performance,
    required this.insights,
    required this.totalIncome,
    required this.totalExpense,
  });
}
