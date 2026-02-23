import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cash_book_entry.dart';
import '../../domain/models/cash_account.dart';
import '../../data/repositories/cash_book_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../sharing/data/services/cash_book_sync_service.dart';
import '../../../sharing/presentation/providers/cash_book_sync_provider.dart';
import '../../../my_account/presentation/providers/profile_provider.dart';

final cashBookRepositoryProvider = Provider<CashBookRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  final profile = ref.watch(profileProvider);
  return CashBookRepository(
    user?.uid ?? 'guest',
    profileType: profile.profileType.index,
  );
});

class CashBookNotifier extends StateNotifier<AsyncValue<List<CashBookEntry>>> {
  final CashBookRepository _repository;
  final String? _accountId;
  final CashBookSyncService? _syncService;

  CashBookNotifier(this._repository, this._accountId, this._syncService)
      : super(const AsyncValue.loading()) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getAllEntries(accountId: _accountId);
      if (!mounted) return;
      state = AsyncValue.data(entries);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEntry(CashBookEntry entry) async {
    try {
      await _repository.insertEntry(entry);

      // Auto-sync to Firestore if sharing is active
      if (_syncService != null) {
        try {
          await _syncService.syncEntryToFirestore(entry);
          print('[CashBookNotifier] Entry synced to Firestore');
        } catch (e) {
          print('[CashBookNotifier] Sync failed: $e');
        }
      }

      if (!mounted) return;
      await loadEntries();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _repository.deleteEntry(id);

      // Auto-delete from Firestore if sharing is active
      if (_syncService != null) {
        try {
          await _syncService.deleteEntryFromFirestore(id);
          print('[CashBookNotifier] Entry deleted from Firestore');
        } catch (e) {
          print('[CashBookNotifier] Deletion sync failed: $e');
        }
      }

      if (!mounted) return;
      await loadEntries();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}

final activeCashAccountIdProvider =
    StateProvider<String?>((ref) => 'default_cash_account');

final cashAccountsProvider = FutureProvider<List<CashAccount>>((ref) async {
  final repo = ref.watch(cashBookRepositoryProvider);
  return repo.getAccounts();
});

final cashBookProvider =
    StateNotifierProvider<CashBookNotifier, AsyncValue<List<CashBookEntry>>>(
        (ref) {
  final repository = ref.watch(cashBookRepositoryProvider);
  final activeAccountId = ref.watch(activeCashAccountIdProvider);
  final syncService = ref.watch(cashBookSyncServiceProvider);
  return CashBookNotifier(repository, activeAccountId, syncService);
});

// Provides the current running balance
final cashBalanceProvider = Provider<double>((ref) {
  final entriesAsync = ref.watch(cashBookProvider);
  return entriesAsync.when(
    data: (entries) {
      return entries.fold(0.0, (balance, entry) {
        if (entry.type == CashBookEntryType.inflow) {
          return balance + entry.amount;
        } else {
          return balance - entry.amount;
        }
      });
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// Enum for filtering entries
enum CashBookFilter { all, inflow, outflow }

final cashBookFilterProvider =
    StateProvider<CashBookFilter>((ref) => CashBookFilter.all);

// Provides filtered entries
final filteredCashBookProvider = Provider<List<CashBookEntry>>((ref) {
  final entriesAsync = ref.watch(cashBookProvider);
  final filter = ref.watch(cashBookFilterProvider);

  return entriesAsync.when(
    data: (entries) {
      switch (filter) {
        case CashBookFilter.all:
          return entries;
        case CashBookFilter.inflow:
          return entries
              .where((e) => e.type == CashBookEntryType.inflow)
              .toList();
        case CashBookFilter.outflow:
          return entries
              .where((e) => e.type == CashBookEntryType.outflow)
              .toList();
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
