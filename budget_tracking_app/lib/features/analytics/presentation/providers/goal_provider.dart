import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_goal.dart';
import '../../data/repositories/goal_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../my_account/presentation/providers/profile_provider.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  final profile = ref.watch(profileProvider);
  return GoalRepository(user?.uid ?? 'guest',
      profileType: profile.profileType.index);
});

class GoalNotifier extends StateNotifier<AsyncValue<List<FinancialGoal>>> {
  final GoalRepository _repository;

  GoalNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    try {
      final goals = await _repository.getGoals();
      if (!mounted) return;
      state = AsyncValue.data(goals);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGoal(FinancialGoal goal) async {
    try {
      await _repository.insertGoal(goal);
      if (!mounted) return;
      await loadGoals();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateGoal(FinancialGoal goal) async {
    try {
      await _repository.updateGoal(goal);
      if (!mounted) return;
      await loadGoals();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _repository.deleteGoal(id);
      if (!mounted) return;
      await loadGoals();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}

final goalsProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<List<FinancialGoal>>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GoalNotifier(repository);
});
