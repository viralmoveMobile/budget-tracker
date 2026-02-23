import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/holiday_provider.dart';
import '../../domain/models/holiday.dart';
import 'holiday_detail_page.dart';
import '../widgets/add_holiday_sheet.dart';

class HolidayListPage extends ConsumerWidget {
  const HolidayListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidayListProvider);

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('Holiday Planner',
            style: TextStyle(color: AppTheme.getSurfaceColor(context), fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.holidayColor,
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
                  Icon(Icons.beach_access_rounded,
                      size: 100, color: AppTheme.getTextColor(context, opacity: 0.15)),
                  SizedBox(height: 24),
                  Text(
                    'No holidays planned yet',
                    style: TextStyle(
                        color: AppTheme.getTextColor(context, opacity: 0.4),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _showAddHoliday(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Plan New Trip',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ).animate().fadeIn(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: holidays.length,
            itemBuilder: (context, index) {
              final holiday = holidays[index];
              return _HolidayCard(holiday: holiday);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'holiday_list_fab',
        onPressed: () => _showAddHoliday(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Plan Holiday',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ).animate().scale(delay: 400.ms),
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
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.holidayColor.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
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
                          size: 14, color: AppTheme.getTextColor(context, opacity: 0.5)),
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
                                    color: AppTheme.getTextColor(context, opacity: 0.5), fontSize: 12)),
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
                                    color: AppTheme.getTextColor(context, opacity: 0.5), fontSize: 12)),
                            TextSpan(
                              text:
                                  '\$${holiday.totalBudget.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.getTextColor(context, opacity: 0.6)),
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
                                        : AppTheme.infoColor)
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
