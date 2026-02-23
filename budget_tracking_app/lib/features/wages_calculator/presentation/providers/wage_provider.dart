import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/wage_models.dart';
import '../../data/wage_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../my_account/presentation/providers/profile_provider.dart';

final wageRepositoryProvider = Provider<WageRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  final profile = ref.watch(profileProvider);
  return WageRepository(user?.uid ?? 'guest',
      profileType: profile.profileType.index);
});

final wageJobsProvider =
    StateNotifierProvider<WageJobsNotifier, AsyncValue<List<WageJob>>>((ref) {
  return WageJobsNotifier(ref.watch(wageRepositoryProvider));
});

class WageJobsNotifier extends StateNotifier<AsyncValue<List<WageJob>>> {
  final WageRepository _repository;
  WageJobsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadJobs();
  }

  Future<void> loadJobs() async {
    state = const AsyncValue.loading();
    try {
      final jobs = await _repository.getJobs();
      if (!mounted) return;
      state = AsyncValue.data(jobs);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addJob(WageJob job) async {
    await _repository.addJob(job);
    if (!mounted) return;
    await loadJobs();
  }

  Future<void> updateJob(WageJob job) async {
    await _repository.updateJob(job);
    if (!mounted) return;
    await loadJobs();
  }

  Future<void> deleteJob(String id) async {
    await _repository.deleteJob(id);
    if (!mounted) return;
    await loadJobs();
  }
}

final currentJobIdProvider = StateProvider<String?>((ref) => null);

final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final workEntriesProvider = StateNotifierProvider.family<WorkEntriesNotifier,
    AsyncValue<List<WorkEntry>>, String>((ref, jobId) {
  return WorkEntriesNotifier(ref.watch(wageRepositoryProvider), jobId);
});

class WorkEntriesNotifier extends StateNotifier<AsyncValue<List<WorkEntry>>> {
  final WageRepository _repository;
  final String _jobId;

  WorkEntriesNotifier(this._repository, this._jobId)
      : super(const AsyncValue.loading()) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getEntries(_jobId);
      if (!mounted) return;
      state = AsyncValue.data(entries);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEntry(WorkEntry entry) async {
    await _repository.addEntry(entry);
    if (!mounted) return;
    await loadEntries();
  }

  Future<void> updateEntry(WorkEntry entry) async {
    await _repository.updateEntry(entry);
    if (!mounted) return;
    await loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await _repository.deleteEntry(id);
    if (!mounted) return;
    await loadEntries();
  }
}

final monthlyWageSummaryProvider =
    Provider<AsyncValue<MonthlyWageSummary?>>((ref) {
  final jobId = ref.watch(currentJobIdProvider);
  if (jobId == null) return const AsyncValue.data(null);

  final jobsAsync = ref.watch(wageJobsProvider);
  final entriesAsync = ref.watch(workEntriesProvider(jobId));
  final selectedMonth = ref.watch(selectedMonthProvider);

  return jobsAsync.when(
    data: (jobs) {
      final job = jobs.firstWhere((j) => j.id == jobId,
          orElse: () => throw Exception('Job not found'));
      return entriesAsync.when(
        data: (entries) {
          final summary = MonthlyWageSummary.calculate(
            job,
            entries,
            selectedMonth.month,
            selectedMonth.year,
          );
          return AsyncValue.data(summary);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
