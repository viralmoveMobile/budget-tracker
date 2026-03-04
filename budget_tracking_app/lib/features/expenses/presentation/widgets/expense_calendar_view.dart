import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';
import 'package:budget_tracking_app/core/utils/currency_formatter.dart';

class ExpenseCalendarView extends ConsumerStatefulWidget {
  final List<Expense> expenses;

  const ExpenseCalendarView({super.key, required this.expenses});

  @override
  ConsumerState<ExpenseCalendarView> createState() =>
      _ExpenseCalendarViewState();
}

class _ExpenseCalendarViewState extends ConsumerState<ExpenseCalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, List<Expense>> expensesByDay = {};
    for (var expense in widget.expenses) {
      final date =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      expensesByDay[date] ??= [];
      expensesByDay[date]!.add(expense);
    }

    return Column(
      children: [
        TableCalendar<Expense>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          calendarFormat: _calendarFormat,
          rangeSelectionMode: _rangeSelectionMode,
          eventLoader: (day) {
            final date = DateTime(day.year, day.month, day.day);
            return expensesByDay[date] ?? [];
          },
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            selectedDecoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            rangeStartDecoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            rangeEndDecoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            rangeHighlightColor: AppTheme.primaryColor.withOpacity(0.1),
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: AppTheme.dangerColor,
              shape: BoxShape.circle,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _rangeStart = null; // Important to clean those
                _rangeEnd = null;
                _rangeSelectionMode = RangeSelectionMode.toggledOff;
              });
            }
          },
          onRangeSelected: (start, end, focusedDay) {
            setState(() {
              _selectedDay = null;
              _focusedDay = focusedDay;
              _rangeStart = start;
              _rangeEnd = end;
              _rangeSelectionMode = RangeSelectionMode.toggledOn;
            });
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        AppSpacing.gapLg,
        _buildRangeQuickSelect(),
        const Divider(),
        Expanded(
          child: _buildTransactionList(expensesByDay),
        ),
      ],
    );
  }

  Widget _buildRangeQuickSelect() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickSelectButton('7d', 7),
          _quickSelectButton('15d', 15),
          _quickSelectButton('30d', 30),
        ],
      ),
    );
  }

  Widget _quickSelectButton(String label, int days) {
    return TextButton(
      onPressed: () {
        final end = DateTime.now();
        final start = end.subtract(Duration(days: days));
        setState(() {
          _rangeStart = start;
          _rangeEnd = end;
          _focusedDay = end;
          _rangeSelectionMode = RangeSelectionMode.toggledOn;
        });
      },
      child: Text(label),
    );
  }

  Widget _buildTransactionList(Map<DateTime, List<Expense>> expensesByDay) {
    List<Expense> filtered;

    if (_rangeStart != null) {
      // Range view (even partial)
      final start =
          DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
      final end = _rangeEnd != null
          ? DateTime(
              _rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day, 23, 59, 59)
          : DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day,
              23, 59, 59);

      filtered = widget.expenses.where((e) {
        return e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    } else if (_selectedDay != null) {
      // Single day view
      filtered = widget.expenses
          .where((e) => isSameDay(e.date, _selectedDay))
          .toList();
    } else {
      return const Center(
          child: Text('Select a day or range to view transactions'));
    }

    if (filtered.isEmpty) {
      return const Center(child: Text('No transactions found'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final expense = filtered[index];
        return ListTile(
          leading: Icon(expense.category.icon, color: expense.category.color),
          title: Text(expense.category.label),
          subtitle: Text(DateFormat('MMM dd, yyyy').format(expense.date)),
          trailing: Text(
            '${expense.isIncome ? "+" : "-"}${CurrencyFormatter.format(expense.amount, expense.currency)}',
            style: TextStyle(
              color: expense.isIncome
                  ? AppTheme.successColor
                  : AppTheme.dangerColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
