import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/account_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../my_account/presentation/providers/profile_provider.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  final profile = ref.watch(profileProvider);
  return AccountRepository(user?.uid ?? 'guest',
      profileType: profile.profileType.index);
});

final accountsProvider =
    StateNotifierProvider<AccountNotifier, AsyncValue<List<Account>>>((ref) {
  return AccountNotifier(ref.watch(accountRepositoryProvider));
});

class AccountNotifier extends StateNotifier<AsyncValue<List<Account>>> {
  final AccountRepository _repository;

  AccountNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    state = const AsyncValue.loading();
    try {
      final accounts = await _repository.getAccounts();
      if (!mounted) return;
      state = AsyncValue.data(accounts);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAccount(Account account) async {
    try {
      await _repository.addAccount(account);
      if (!mounted) return;
      await loadAccounts();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await _repository.deleteAccount(id);
      if (!mounted) return;
      await loadAccounts();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> transfer({
    required String fromId,
    required String toId,
    required double amount,
    String? notes,
  }) async {
    try {
      await _repository.transferFunds(
        fromAccountId: fromId,
        toAccountId: toId,
        amount: amount,
        date: DateTime.now(),
        notes: notes,
      );
      if (!mounted) return;
      await loadAccounts();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}

final accountTransactionsProvider =
    FutureProvider.family<List<AccountTransaction>, String>((ref, accountId) {
  return ref.watch(accountRepositoryProvider).getTransactions(accountId);
});
