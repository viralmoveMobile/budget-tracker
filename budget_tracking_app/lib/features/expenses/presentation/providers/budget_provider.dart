import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_limit.dart';
import '../../data/models/expense_category.dart';
import '../../data/repositories/expense_repository.dart';
import 'expense_provider.dart';
import '../../../sharing/data/services/budget_sync_service.dart';
import '../../../sharing/presentation/providers/budget_sync_provider.dart';

final budgetLimitsProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<List<BudgetLimit>>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  final syncService = ref.watch(budgetSyncServiceProvider);
  return BudgetNotifier(repository, syncService);
});

class BudgetNotifier extends StateNotifier<AsyncValue<List<BudgetLimit>>> {
  final ExpenseRepository _repository;
  final BudgetSyncService? _syncService;

  BudgetNotifier(this._repository, this._syncService)
      : super(const AsyncValue.loading()) {
    loadLimits();
  }

  Future<void> loadLimits() async {
    final now = DateTime.now();
    try {
      final limits = await _repository.getBudgetLimits(now.month, now.year);
      if (!mounted) return;
      state = AsyncValue.data(limits);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveLimit(BudgetLimit limit) async {
    try {
      print('[BudgetNotifier] Saving budget limit: ${limit.id}');
      await _repository.saveBudgetLimit(limit);

      // Auto-sync to Firestore if sharing is active
      if (_syncService != null) {
        try {
          await _syncService.syncBudgetToFirestore(limit);
          print('[BudgetNotifier] Budget synced to Firestore');
        } catch (e) {
          print('[BudgetNotifier] Sync failed: $e');
        }
      }

      if (!mounted) return;
      await loadLimits();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}

// Helper provider for calculating budget usage
final budgetUsageProvider = Provider((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final limitsAsync = ref.watch(budgetLimitsProvider);

  return expensesAsync.when(
    data: (expenses) => limitsAsync.when(
      data: (limits) {
        final now = DateTime.now();
        final currentMonthExpenses = expenses
            .where((e) => e.date.month == now.month && e.date.year == now.year)
            .toList();

        final totalSpent = currentMonthExpenses
            .where((e) => !e.isIncome)
            .fold(0.0, (sum, e) => sum + e.amount);
        final totalIncome = currentMonthExpenses
            .where((e) => e.isIncome)
            .fold(0.0, (sum, e) => sum + e.amount);
        final totalLimit = limits
            .where((l) => l.category == null)
            .fold(0.0, (sum, l) => sum + l.amount);

        final categoryUsage = <ExpenseCategory, Map<String, double>>{};
        for (final category in ExpenseCategory.values) {
          final spent = currentMonthExpenses
              .where((e) => e.category == category && !e.isIncome)
              .fold(0.0, (sum, e) => sum + e.amount);
          final income = currentMonthExpenses
              .where((e) => e.category == category && e.isIncome)
              .fold(0.0, (sum, e) => sum + e.amount);
          final limit = limits
              .where((l) => l.category == category)
              .fold(0.0, (sum, l) => sum + l.amount);
          categoryUsage[category] = {
            'spent': spent,
            'income': income,
            'limit': limit
          };
        }

        return {
          'totalSpent': totalSpent,
          'totalIncome': totalIncome,
          'totalLimit': totalLimit,
          'categoryUsage': categoryUsage,
        };
      },
      loading: () => null,
      error: (_, __) => null,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});
