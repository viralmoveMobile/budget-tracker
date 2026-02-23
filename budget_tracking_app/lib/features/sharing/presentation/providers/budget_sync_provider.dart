import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/data/models/budget_limit.dart';
import '../../data/services/budget_sync_service.dart';
import 'firestore_sharing_provider.dart';

import '../../../my_account/presentation/providers/profile_provider.dart';

/// Provider for budget sync service
final budgetSyncServiceProvider = Provider<BudgetSyncService?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) return null;

  return BudgetSyncService(currentUserId: user.uid);
});

// ...

/// Provider for shared budgets from all users sharing with me
final sharedBudgetsProvider = StreamProvider<List<BudgetLimit>>((ref) {
  print('[SharedBudgets] Provider called');
  final syncService = ref.watch(budgetSyncServiceProvider);
  final sharedWithMe = ref.watch(usersSharedWithMeProvider);
  final profile = ref.watch(profileProvider); // Watch profile for changes

  print('[SharedBudgets] Sync service available: ${syncService != null}');

  if (syncService == null) {
    print('[SharedBudgets] No sync service - returning empty stream');
    return Stream.value([]);
  }

  return sharedWithMe.when(
    data: (relationships) {
      print(
          '[SharedBudgets] Got ${relationships.length} sharing relationships');
      if (relationships.isEmpty) {
        print('[SharedBudgets] No sharing relationships found');
        return Stream.value([]);
      }

      // Get list of owner IDs who are sharing with me
      final ownerIds = relationships
          .where((r) => r.dataTypes.contains('budgets'))
          .map((r) => r.ownerId)
          .toList();

      print(
          '[SharedBudgets] Found ${ownerIds.length} users sharing budgets: $ownerIds');

      if (ownerIds.isEmpty) {
        print('[SharedBudgets] No users sharing budgets');
        return Stream.value([]);
      }

      // Stream budgets from all these users
      print(
          '[SharedBudgets] Starting budget stream from ${ownerIds.length} users');
      return syncService.streamAllSharedBudgets(
          ownerIds, profile.profileType.index);
    },
    loading: () {
      print('[SharedBudgets] Relationships loading...');
      return Stream.value([]);
    },
    error: (err, stack) {
      print('[SharedBudgets] Error loading relationships: $err');
      return Stream.value([]);
    },
  );
});

/// Provider for budgets shared by specific user
final sharedBudgetsByUserProvider =
    StreamProvider.family<List<BudgetLimit>, String>((ref, userId) {
  final syncService = ref.watch(budgetSyncServiceProvider);
  final profile = ref.watch(profileProvider); // Watch profile for changes

  if (syncService == null) {
    return Stream.value([]);
  }

  return syncService.streamSharedBudgets(userId, profile.profileType.index);
});

/// State for managing budget sync operations
class BudgetSyncState {
  final bool isSyncing;
  final String? errorMessage;
  final String? successMessage;

  const BudgetSyncState({
    this.isSyncing = false,
    this.errorMessage,
    this.successMessage,
  });

  BudgetSyncState copyWith({
    bool? isSyncing,
    String? errorMessage,
    String? successMessage,
  }) {
    return BudgetSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// Controller for managing budget sync operations
class BudgetSyncController extends StateNotifier<BudgetSyncState> {
  final BudgetSyncService _syncService;

  BudgetSyncController(this._syncService, Ref ref)
      : super(const BudgetSyncState());

  /// Sync budget to Firestore
  Future<void> syncBudget(BudgetLimit budget) async {
    state = state.copyWith(isSyncing: true, errorMessage: null);
    try {
      await _syncService.syncBudgetToFirestore(budget);
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        successMessage: 'Budget synced',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Failed to sync: $e',
      );
    }
  }

  /// Delete synced budget from Firestore
  Future<void> deleteSyncedBudget(String budgetId) async {
    state = state.copyWith(isSyncing: true, errorMessage: null);
    try {
      await _syncService.deleteBudgetFromFirestore(budgetId);
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        successMessage: 'Budget deleted from shared data',
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

final budgetSyncControllerProvider =
    StateNotifierProvider<BudgetSyncController, BudgetSyncState>((ref) {
  final syncService = ref.watch(budgetSyncServiceProvider);
  if (syncService == null) {
    throw Exception(
        'BudgetSyncService is not available. User must be logged in.');
  }
  return BudgetSyncController(syncService, ref);
});
