import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/holiday_provider.dart';
import '../../domain/models/holiday.dart';
import 'holiday_detail_page.dart';
import '../widgets/add_holiday_sheet.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class HolidayListPage extends ConsumerWidget {
  const HolidayListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidayListProvider);

    return AppScaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppAppBar(
        title: Text('Holiday Planner',
            style: TextStyle(
                color: AppTheme.getSurfaceColor(context),
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5)),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: holidaysAsync.when(
        data: (holidays) {
          if (holidays.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.flight_takeoff_rounded,
                        size: 80, color: AppTheme.primaryColor),
                  ),
                  AppSpacing.gapXl,
                  Text(
                    'No trips planned yet',
                    style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'Start tracking your holiday budget today',
                    style: TextStyle(
                        color: AppTheme.getTextColor(context, opacity: 0.5),
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => _showAddHoliday(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Plan New Trip',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: holidays.length,
            itemBuilder: (context, index) {
              final holiday = holidays[index];
              return _HolidayCard(
                  holiday:
                      holiday); // `index` parameter was not added to _HolidayCard as it's not defined in the original code.
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: holidaysAsync.maybeWhen(
        data: (holidays) => holidays.isNotEmpty
            ? FloatingActionButton.extended(
                heroTag: 'holiday_list_fab',
                onPressed: () => _showAddHoliday(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Plan Holiday',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ).animate().scale(delay: 200.ms)
            : null,
        orElse: () => null,
      ),
    );
  }

  void _showAddHoliday(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddHolidaySheet(),
    );
  }
}

class _HolidayCard extends ConsumerWidget {
  final Holiday holiday;

  const _HolidayCard({required this.holiday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(holidayExpensesProvider(holiday.id));

    return expensesAsync.when(
      data: (expenses) {
        final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
        final progress =
            (totalSpent / (holiday.totalBudget > 0 ? holiday.totalBudget : 1))
                .clamp(0.0, 1.0);
        final isOverspent = totalSpent > holiday.totalBudget;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(AppSpacing.r24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
                color: AppTheme.getBorderColor(context, opacity: 0.2),
                width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.r24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HolidayDetailPage(holiday: holiday),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          holiday.name,
                          style: TextStyle(
                            color: AppTheme.getTextColor(context),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isOverspent
                                  ? AppTheme.dangerColor
                                  : AppTheme.successColor)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isOverspent ? 'Over budget' : 'On track',
                          style: TextStyle(
                            color: isOverspent
                                ? AppTheme.dangerColor
                                : AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14,
                          color: AppTheme.getTextColor(context, opacity: 0.5)),
                      SizedBox(width: 8),
                      Text(
                        '${DateFormat('MMM d').format(holiday.startDate)} - ${DateFormat('MMM d, y').format(holiday.endDate)}',
                        style: TextStyle(
                            color: AppTheme.getTextColor(context, opacity: 0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: 'Spent: ',
                                style: TextStyle(
                                    color: AppTheme.getTextColor(context,
                                        opacity: 0.5),
                                    fontSize: 12)),
                            TextSpan(
                              text: '\$${totalSpent.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppTheme.getTextColor(context)),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: 'Limit: ',
                                style: TextStyle(
                                    color: AppTheme.getTextColor(context,
                                        opacity: 0.5),
                                    fontSize: 12)),
                            TextSpan(
                              text:
                                  '\$${holiday.totalBudget.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.getTextColor(context,
                                      opacity: 0.6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.getBorderColor(context),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isOverspent
                                    ? AppTheme.dangerColor
                                    : AppTheme.primaryColor,
                                (isOverspent
                                        ? AppTheme.dangerColor
                                        : AppTheme.primaryColor)
                                    .withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: (isOverspent
                                        ? AppTheme.dangerColor
                                        : AppTheme.primaryColor)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
      },
      loading: () => const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, s) => const Text('Error loading expenses'),
    );
  }
}
