import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../../../sharing/data/services/expense_sync_service.dart';
import '../../../sharing/presentation/providers/expense_sync_provider.dart';
import '../../../my_account/presentation/providers/profile_provider.dart'; // Import ProfileProvider

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  final profile = ref.watch(profileProvider); // Watch profile for changes
  return ExpenseRepository(
    user?.uid ?? 'guest',
    profileType: profile.profileType.index, // Pass profile type
  );
});

final expensesProvider =
    StateNotifierProvider<ExpenseNotifier, AsyncValue<List<Expense>>>((ref) {
  final syncService = ref.watch(expenseSyncServiceProvider);
  return ExpenseNotifier(
    ref.watch(expenseRepositoryProvider),
    syncService,
  );
});

class ExpenseNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ExpenseRepository _repository;
  final ExpenseSyncService? _syncService;

  ExpenseNotifier(this._repository, this._syncService)
      : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _repository.getExpenses();
      if (!mounted) return;
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _repository.addExpense(expense);

      // Auto-sync to Firestore if sharing is active
      if (_syncService != null) {
        try {
          await _syncService.syncExpenseToFirestore(expense);
          print('[ExpenseNotifier] Expense synced to Firestore');
        } catch (e) {
          print('[ExpenseNotifier] Sync failed: $e');
          // Don't fail the operation if sync fails
        }
      }

      if (!mounted) return;
      await loadExpenses();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _repository.updateExpense(expense);

      // Auto-sync to Firestore if sharing is active
      if (_syncService != null) {
        try {
          await _syncService.syncExpenseToFirestore(expense);
          print('[ExpenseNotifier] Expense update synced to Firestore');
        } catch (e) {
          print('[ExpenseNotifier] Sync failed: $e');
        }
      }

      if (!mounted) return;
      await loadExpenses();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _repository.deleteExpense(id);

      // Auto-delete from Firestore if sharing is active
      if (_syncService != null) {
        try {
          await _syncService.deleteExpenseFromFirestore(id);
          print('[ExpenseNotifier] Expense deleted from Firestore');
        } catch (e) {
          print('[ExpenseNotifier] Sync deletion failed: $e');
        }
      }

      if (!mounted) return;
      await loadExpenses();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}
