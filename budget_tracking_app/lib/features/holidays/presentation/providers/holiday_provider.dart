import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/holiday.dart';
import '../../domain/models/holiday_expense.dart';
import '../../data/repositories/holiday_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../my_account/presentation/providers/profile_provider.dart';

final holidayRepositoryProvider = Provider<HolidayRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  final profile = ref.watch(profileProvider);
  return HolidayRepository(user?.uid ?? 'guest',
      profileType: profile.profileType.index);
});

class HolidayListNotifier extends StateNotifier<AsyncValue<List<Holiday>>> {
  final HolidayRepository _repository;

  HolidayListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadHolidays();
  }

  Future<void> loadHolidays() async {
    state = const AsyncValue.loading();
    try {
      final holidays = await _repository.getHolidays();
      if (!mounted) return;
      state = AsyncValue.data(holidays);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addHoliday(Holiday holiday) async {
    try {
      await _repository.insertHoliday(holiday);
      if (!mounted) return;
      await loadHolidays();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteHoliday(String id) async {
    try {
      await _repository.deleteHoliday(id);
      if (!mounted) return;
      await loadHolidays();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}

final holidayListProvider =
    StateNotifierProvider<HolidayListNotifier, AsyncValue<List<Holiday>>>(
        (ref) {
  final repository = ref.watch(holidayRepositoryProvider);
  return HolidayListNotifier(repository);
});

final holidayExpensesProvider =
    FutureProvider.family<List<HolidayExpense>, String>((ref, holidayId) async {
  final repository = ref.watch(holidayRepositoryProvider);
  return await repository.getHolidayExpenses(holidayId);
});

class HolidayExpensesNotifier extends StateNotifier<void> {
  final HolidayRepository _repository;
  final Ref _ref;

  HolidayExpensesNotifier(this._repository, this._ref) : super(null);

  Future<void> addExpense(HolidayExpense expense) async {
    await _repository.insertHolidayExpense(expense);
    if (!mounted) return;
    _ref.invalidate(holidayExpensesProvider(expense.holidayId));
  }

  Future<void> deleteExpense(String id, String holidayId) async {
    await _repository.deleteHolidayExpense(id);
    if (!mounted) return;
    _ref.invalidate(holidayExpensesProvider(holidayId));
  }
}

final holidayExpensesNotifierProvider = Provider((ref) =>
    HolidayExpensesNotifier(ref.watch(holidayRepositoryProvider), ref));
