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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('Wages & Earnings',
            style: TextStyle(
                color: AppTheme.getSurfaceColor(context),
                fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.wagesColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            onPressed: () => _showAddJob(context),
            tooltip: 'Add Job / Employer',
          ),
        ],
      ),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return _buildEmptyJobsState(context);
          }

          // Auto-select first job if none selected
          if (currentJobId == null || !jobs.any((j) => j.id == currentJobId)) {
            Future.microtask(() =>
                ref.read(currentJobIdProvider.notifier).state = jobs.first.id);
            return const Center(child: CircularProgressIndicator());
          }

          final currentJob = jobs.firstWhere((j) => j.id == currentJobId);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildJobSelector(context, jobs, currentJobId),
                _buildMonthNavigation(context, selectedMonth),
                _buildSummaryCard(
                    context, summaryAsync, currentJob, profile.currency),
                _buildCalendar(context, currentJobId),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyJobsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_history_rounded,
                size: 100, color: AppTheme.wagesColor.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text(
              'No Jobs Tracked Yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context, opacity: 0.6)),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your employers or income streams to start tracking wages daily.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.getTextColor(context, opacity: 0.4)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddJob(context),
              icon: const Icon(Icons.add),
              label: const Text('Add My First Job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.wagesColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobSelector(
      BuildContext context, List<WageJob> jobs, String? currentId) {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          final isSelected = job.id == currentId;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () =>
                  ref.read(currentJobIdProvider.notifier).state = job.id,
              onLongPress: () => _showEditJob(context, job),
              child: AnimatedContainer(
                duration: 200.ms,
                width: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.wagesColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isSelected ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.employer ??
                          (job.mode == WageMode.hourly ? 'Hourly' : 'Monthly'),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white70 : Colors.black38,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              final newDate =
                  DateTime(selectedMonth.year, selectedMonth.month - 1);
              ref.read(selectedMonthProvider.notifier).state = newDate;
              setState(() => _focusedDay = newDate);
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.getTextColor(context)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              final newDate =
                  DateTime(selectedMonth.year, selectedMonth.month + 1);
              ref.read(selectedMonthProvider.notifier).state = newDate;
              setState(() => _focusedDay = newDate);
            },
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
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.wagesColor,
                AppTheme.wagesColor.withOpacity(0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.wagesColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estimated Net Pay',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                        job.mode == WageMode.hourly ? 'Hourly' : 'Salary',
                        style: TextStyle(
                            color: AppTheme.getSurfaceColor(context),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormat.simpleCurrency(name: currency)
                    .format(summary.netPay),
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.getSurfaceColor(context),
                    letterSpacing: -1),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                      'Gross',
                      NumberFormat.simpleCurrency(
                              name: currency, decimalDigits: 0)
                          .format(summary.grossIncome)),
                  _buildSummaryItem(
                      'Hours', summary.totalHours.toStringAsFixed(1)),
                  _buildSummaryItem('Overtime',
                      summary.totalOvertimeHours.toStringAsFixed(1)),
                  _buildSummaryItem(
                      'Tax', '${job.taxPercentage.toStringAsFixed(0)}%'),
                ],
              ),
            ],
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOut);
      },
      loading: () => const SizedBox(
          height: 180, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: AppTheme.getSurfaceColor(context),
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context, String jobId) {
    final entriesAsync = ref.watch(workEntriesProvider(jobId));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppTheme.getDividerColor(context),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: entriesAsync.when(
        data: (entries) => TableCalendar(
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
          onFormatChanged: (format) => setState(() => _calendarFormat = format),
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
            // Sync current month provider if needed, or just let the navigation bar do it
          },
          eventLoader: (day) {
            return entries.where((e) => isSameDay(e.date, day)).toList();
          },
          calendarStyle: CalendarStyle(
            markerDecoration: const BoxDecoration(
                color: AppTheme.wagesColor, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(
                color: AppTheme.wagesColor.withOpacity(0.2),
                shape: BoxShape.circle),
            todayTextStyle: const TextStyle(
                color: AppTheme.wagesColor, fontWeight: FontWeight.bold),
            selectedDecoration: const BoxDecoration(
                color: AppTheme.wagesColor, shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontWeight: FontWeight.bold),
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
