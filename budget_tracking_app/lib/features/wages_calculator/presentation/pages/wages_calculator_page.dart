import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/wage_provider.dart';
import '../../domain/wage_models.dart';
import '../widgets/add_job_sheet.dart';
import '../widgets/add_work_entry_sheet.dart';
import 'package:budget_tracking_app/features/my_account/presentation/providers/profile_provider.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';
import 'package:budget_tracking_app/core/utils/currency_formatter.dart';

class WagesCalculatorPage extends ConsumerStatefulWidget {
  const WagesCalculatorPage({super.key});

  @override
  ConsumerState<WagesCalculatorPage> createState() =>
      _WagesCalculatorPageState();
}

class _WagesCalculatorPageState extends ConsumerState<WagesCalculatorPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(wageJobsProvider);
    final currentJobId = ref.watch(currentJobIdProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final summaryAsync = ref.watch(monthlyWageSummaryProvider);
    final profile = ref.watch(profileProvider);

    // Extract summary values for hero bar
    final netPay = summaryAsync.value?.netPay ?? 0.0;
    final totalHours = summaryAsync.value?.totalHours ?? 0.0;
    final grossIncome = summaryAsync.value?.grossIncome ?? 0.0;

    return AppScaffold(
      withTealHeader: true,
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppAppBar(
        title: const Text('Wages & Earnings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            onPressed: () => _showAddJob(context),
            tooltip: 'Add Job / Employer',
          ),
          AppSpacing.gapXs,
        ],
      ),
      heroContent: Padding(
        padding: AppSpacing.listItemPadding,
        child: Column(
          children: [
            Row(
              children: [
                _buildHeroStat(
                  CurrencyFormatter.format(netPay, profile.currency),
                  'Net Pay',
                  Icons.payments_rounded,
                ),
                Container(
                    width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                _buildHeroStat(
                  CurrencyFormatter.format(grossIncome, profile.currency),
                  'Gross',
                  Icons.account_balance_wallet_rounded,
                ),
                Container(
                    width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                _buildHeroStat(
                  '${totalHours.toStringAsFixed(1)}h',
                  'Hours',
                  Icons.timer_rounded,
                ),
              ],
            ),
            AppSpacing.gapMd,
          ],
        ),
      ),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) return _buildEmptyJobsState(context);

          if (currentJobId == null || !jobs.any((j) => j.id == currentJobId)) {
            Future.microtask(() =>
                ref.read(currentJobIdProvider.notifier).state = jobs.first.id);
            return const Center(child: CircularProgressIndicator());
          }

          final currentJob = jobs.firstWhere((j) => j.id == currentJobId);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildJobSelector(context, jobs, currentJobId),
                _buildMonthNavigation(context, selectedMonth),
                _buildSummaryCard(
                    context, summaryAsync, currentJob, profile.currency),
                AppSpacing.gapLg,
                _buildCalendar(context, currentJobId),
                AppSpacing.gapXxl,
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeroStat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: Colors.white.withOpacity(0.9)),
              AppSpacing.gapXs,
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          AppSpacing.gapXs,
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyJobsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.work_history_rounded,
                  size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Jobs Tracked Yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add your employers or income streams\nto start tracking wages daily.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showAddJob(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add My First Job',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r16)),
              ),
            ),
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildJobSelector(
      BuildContext context, List<WageJob> jobs, String? currentId) {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          final isSelected = job.id == currentId;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () =>
                  ref.read(currentJobIdProvider.notifier).state = job.id,
              onLongPress: () => _showEditJob(context, job),
              child: AnimatedContainer(
                duration: 200.ms,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.r24),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.work_rounded,
                      size: 14,
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      job.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color:
                            isSelected ? Colors.white : AppTheme.primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthNavigation(BuildContext context, DateTime selectedMonth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left_rounded,
                  color: AppTheme.primaryColor),
              onPressed: () {
                final newDate =
                    DateTime(selectedMonth.year, selectedMonth.month - 1);
                ref.read(selectedMonthProvider.notifier).state = newDate;
                setState(() => _focusedDay = newDate);
              },
            ),
          ),
          Column(
            children: [
              Text(
                DateFormat('MMMM').format(selectedMonth).toUpperCase(),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 1),
              ),
              Text(
                DateFormat('yyyy').format(selectedMonth),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.primaryColor),
              onPressed: () {
                final newDate =
                    DateTime(selectedMonth.year, selectedMonth.month + 1);
                ref.read(selectedMonthProvider.notifier).state = newDate;
                setState(() => _focusedDay = newDate);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context,
      AsyncValue<MonthlyWageSummary?> summaryAsync,
      WageJob job,
      String currency) {
    return summaryAsync.when(
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.r24),
            border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_rounded,
                        color: AppTheme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimated Net Pay',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                        Text(
                          CurrencyFormatter.format(summary.netPay, currency),
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                              letterSpacing: -1),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      job.mode == WageMode.hourly ? 'Hourly' : 'Salary',
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryStatItem(
                    'Gross',
                    CurrencyFormatter.format(summary.grossIncome, currency),
                    Icons.account_balance_wallet_rounded,
                  ),
                  _buildSummaryStatItem(
                    'Hours',
                    summary.totalHours.toStringAsFixed(1),
                    Icons.timer_rounded,
                  ),
                  _buildSummaryStatItem(
                    'Overtime',
                    '${summary.totalOvertimeHours.toStringAsFixed(1)}h',
                    Icons.more_time_rounded,
                  ),
                  _buildSummaryStatItem(
                    'Tax',
                    '${job.taxPercentage.toStringAsFixed(0)}%',
                    Icons.receipt_rounded,
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
      },
      loading: () => const SizedBox(
          height: 140, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.textPrimary),
        ),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context, String jobId) {
    final entriesAsync = ref.watch(workEntriesProvider(jobId));

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.r24),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: entriesAsync.when(
        data: (entries) => ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.r24),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showAddHours(context, jobId, selectedDay, entries);
            },
            onFormatChanged: (format) =>
                setState(() => _calendarFormat = format),
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            eventLoader: (day) =>
                entries.where((e) => isSameDay(e.date, day)).toList(),
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(
                  color: AppTheme.primaryColor, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle),
              todayTextStyle: const TextStyle(
                  color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              selectedDecoration: const BoxDecoration(
                  color: AppTheme.primaryColor, shape: BoxShape.circle),
              selectedTextStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              weekendTextStyle: const TextStyle(color: AppTheme.dangerColor),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary),
              leftChevronIcon: Icon(Icons.chevron_left_rounded,
                  color: AppTheme.primaryColor),
              rightChevronIcon: Icon(Icons.chevron_right_rounded,
                  color: AppTheme.primaryColor),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.textSecondary),
              weekendStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.dangerColor),
            ),
          ),
        ),
        loading: () => const SizedBox(
            height: 300, child: Center(child: CircularProgressIndicator())),
        error: (_, __) => const SizedBox(
            height: 300, child: Center(child: Text('Error loading calendar'))),
      ),
    );
  }

  void _showAddJob(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddJobSheet(),
    );
  }

  void _showEditJob(BuildContext context, WageJob job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddJobSheet(job: job),
    );
  }

  void _showAddHours(BuildContext context, String jobId, DateTime date,
      List<WorkEntry> entries) {
    final existingEntry =
        entries.where((e) => isSameDay(e.date, date)).firstOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddWorkEntrySheet(
        jobId: jobId,
        date: date,
        entry: existingEntry,
      ),
    );
  }
}
