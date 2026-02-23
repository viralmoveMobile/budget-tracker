import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_providers.dart';

class ProjectionData {
  final double estimatedNextMonthExpense;
  final double estimatedNextMonthSavings;
  final String confidence;

  ProjectionData({
    required this.estimatedNextMonthExpense,
    required this.estimatedNextMonthSavings,
    required this.confidence,
  });
}

final projectionProvider = Provider<AsyncValue<ProjectionData>>((ref) {
  final analyticsAsync = ref.watch(analyticsDashboardProvider);

  return analyticsAsync.when(
    data: (data) {
      if (data.monthlyTrends.length < 2) {
        return AsyncValue.data(ProjectionData(
          estimatedNextMonthExpense: 0,
          estimatedNextMonthSavings: 0,
          confidence: 'Insufficient Data',
        ));
      }

      // Simple average projection
      double sumExpenses = 0;
      double sumIncome = 0;
      int count = 0;

      // Use last 3 months if available
      final lastMonths = data.monthlyTrends.reversed.take(3).toList();
      for (var trend in lastMonths) {
        if (trend.expense > 0 || trend.income > 0) {
          sumExpenses += trend.expense;
          sumIncome += trend.income;
          count++;
        }
      }

      if (count == 0) {
        return AsyncValue.data(ProjectionData(
          estimatedNextMonthExpense: 0,
          estimatedNextMonthSavings: 0,
          confidence: 'No activity found',
        ));
      }

      final avgExpense = sumExpenses / count;
      final avgIncome = sumIncome / count;

      return AsyncValue.data(ProjectionData(
        estimatedNextMonthExpense: avgExpense,
        estimatedNextMonthSavings:
            (avgIncome - avgExpense).clamp(0.0, double.infinity),
        confidence: count >= 3 ? 'High' : 'Medium',
      ));
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
