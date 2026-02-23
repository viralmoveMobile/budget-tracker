import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/data/models/expense.dart';
import '../../data/services/expense_sync_service.dart';
import 'firestore_sharing_provider.dart';
import '../../../my_account/presentation/providers/profile_provider.dart'; // Import ProfileType

/// Provider for expense sync service
final expenseSyncServiceProvider = Provider<ExpenseSyncService?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) return null;

  return ExpenseSyncService(currentUserId: user.uid);
});

// ... (Existing code)

/// Provider for shared expenses from all users sharing with me
final sharedExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final syncService = ref.watch(expenseSyncServiceProvider);
  final sharedWithMe = ref.watch(usersSharedWithMeProvider);
  final profile = ref.watch(profileProvider); // Watch profile for changes

  if (syncService == null) {
    return Stream.value([]);
  }

  return sharedWithMe.when(
    data: (relationships) {
      if (relationships.isEmpty) {
        return Stream.value([]);
      }

      // Get list of owner IDs who are sharing with me
      final ownerIds = relationships
          .where((r) => r.dataTypes.contains('expenses'))
          .map((r) => r.ownerId)
          .toList();

      if (ownerIds.isEmpty) {
        return Stream.value([]);
      }

      // Stream expenses from all these users
      return syncService.streamAllSharedExpenses(
          ownerIds, profile.profileType.index);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Provider for expenses shared by specific user
final sharedExpensesByUserProvider =
    StreamProvider.family<List<Expense>, String>((ref, userId) {
  final syncService = ref.watch(expenseSyncServiceProvider);
  final profile = ref.watch(profileProvider); // Watch profile for changes

  if (syncService == null) {
    return Stream.value([]);
  }

  return syncService.streamSharedExpenses(userId, profile.profileType.index);
});

/// State for managing expense sync operations
class ExpenseSyncState {
  final bool isSyncing;
  final String? errorMessage;
  final String? successMessage;

  const ExpenseSyncState({
    this.isSyncing = false,
    this.errorMessage,
    this.successMessage,
  });

  ExpenseSyncState copyWith({
    bool? isSyncing,
    String? errorMessage,
    String? successMessage,
  }) {
    return ExpenseSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// Controller for managing expense sync operations
class ExpenseSyncController extends StateNotifier<ExpenseSyncState> {
  final ExpenseSyncService _syncService;

  ExpenseSyncController(this._syncService, Ref ref)
      : super(const ExpenseSyncState());

  /// Sync expense to Firestore (called after adding/updating expense)
  Future<void> syncExpense(Expense expense) async {
    state = state.copyWith(isSyncing: true, errorMessage: null);
    try {
      await _syncService.syncExpenseToFirestore(expense);
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        successMessage: 'Expense synced',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Failed to sync: $e',
      );
    }
  }

  /// Delete synced expense from Firestore
  Future<void> deleteSyncedExpense(String expenseId) async {
    state = state.copyWith(isSyncing: true, errorMessage: null);
    try {
      await _syncService.deleteExpenseFromFirestore(expenseId);
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        successMessage: 'Expense deleted from shared data',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Failed to delete: $e',
      );
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(successMessage: null, errorMessage: null);
  }
}

final expenseSyncControllerProvider =
    StateNotifierProvider<ExpenseSyncController, ExpenseSyncState>((ref) {
  final syncService = ref.watch(expenseSyncServiceProvider);
  if (syncService == null) {
    throw Exception(
        'ExpenseSyncService is not available. User must be logged in.');
  }
  return ExpenseSyncController(syncService, ref);
});
