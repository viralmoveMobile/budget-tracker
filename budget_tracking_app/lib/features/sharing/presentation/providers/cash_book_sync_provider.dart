import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cash_book/domain/models/cash_book_entry.dart';
import '../../data/services/cash_book_sync_service.dart';
import 'firestore_sharing_provider.dart';

import '../../../my_account/presentation/providers/profile_provider.dart';

/// Provider for cash book sync service
final cashBookSyncServiceProvider = Provider<CashBookSyncService?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) return null;

  return CashBookSyncService(currentUserId: user.uid);
});

// ...

/// Provider for shared cash book entries from all users sharing with me
final sharedCashBookEntriesProvider =
    StreamProvider<List<CashBookEntry>>((ref) {
  print('[SharedCashBook] Provider called');
  final syncService = ref.watch(cashBookSyncServiceProvider);
  final sharedWithMe = ref.watch(usersSharedWithMeProvider);
  final profile = ref.watch(profileProvider); // Watch profile for changes

  print('[SharedCashBook] Sync service available: ${syncService != null}');

  if (syncService == null) {
    print('[SharedCashBook] No sync service - returning empty stream');
    return Stream.value([]);
  }

  return sharedWithMe.when(
    data: (relationships) {
      print(
          '[SharedCashBook] Got ${relationships.length} sharing relationships');
      if (relationships.isEmpty) {
        print('[SharedCashBook] No sharing relationships found');
        return Stream.value([]);
      }

      // Get list of owner IDs who are sharing with me
      final ownerIds = relationships
          .where((r) => r.dataTypes.contains('cash_book'))
          .map((r) => r.ownerId)
          .toList();

      print(
          '[SharedCashBook] Found ${ownerIds.length} users sharing cash books: $ownerIds');

      if (ownerIds.isEmpty) {
        print('[SharedCashBook] No users sharing cash books');
        return Stream.value([]);
      }

      // Stream entries from all these users
      print(
          '[SharedCashBook] Starting entry stream from ${ownerIds.length} users');
      return syncService.streamAllSharedEntries(
          ownerIds, profile.profileType.index);
    },
    loading: () {
      print('[SharedCashBook] Relationships loading...');
      return Stream.value([]);
    },
    error: (err, stack) {
      print('[SharedCashBook] Error loading relationships: $err');
      return Stream.value([]);
    },
  );
});

/// Provider for cash book entries shared by specific user
final sharedCashBookEntriesByUserProvider =
    StreamProvider.family<List<CashBookEntry>, String>((ref, userId) {
  final syncService = ref.watch(cashBookSyncServiceProvider);
  final profile = ref.watch(profileProvider); // Watch profile for changes

  if (syncService == null) {
    return Stream.value([]);
  }

  return syncService.streamSharedEntries(userId, profile.profileType.index);
});

/// State for managing cash book sync operations
class CashBookSyncState {
  final bool isSyncing;
  final String? errorMessage;
  final String? successMessage;

  const CashBookSyncState({
    this.isSyncing = false,
    this.errorMessage,
    this.successMessage,
  });

  CashBookSyncState copyWith({
    bool? isSyncing,
    String? errorMessage,
    String? successMessage,
  }) {
    return CashBookSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// Controller for managing cash book sync operations
class CashBookSyncController extends StateNotifier<CashBookSyncState> {
  final CashBookSyncService _syncService;

  CashBookSyncController(this._syncService, Ref ref)
      : super(const CashBookSyncState());

  /// Sync entry to Firestore
  Future<void> syncEntry(CashBookEntry entry) async {
    state = state.copyWith(isSyncing: true, errorMessage: null);
    try {
      await _syncService.syncEntryToFirestore(entry);
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        successMessage: 'Entry synced',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Failed to sync: $e',
      );
    }
  }

  /// Delete synced entry from Firestore
  Future<void> deleteSyncedEntry(String entryId) async {
    state = state.copyWith(isSyncing: true, errorMessage: null);
    try {
      await _syncService.deleteEntryFromFirestore(entryId);
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        successMessage: 'Entry deleted from shared data',
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

final cashBookSyncControllerProvider =
    StateNotifierProvider<CashBookSyncController, CashBookSyncState>((ref) {
  final syncService = ref.watch(cashBookSyncServiceProvider);
  if (syncService == null) {
    throw Exception(
        'CashBookSyncService is not available. User must be logged in.');
  }
  return CashBookSyncController(syncService, ref);
});
