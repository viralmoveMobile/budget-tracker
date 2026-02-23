import 'package:budget_tracking_app/features/expenses/data/local/database_helper.dart';
import '../../domain/models/holiday.dart';
import '../../domain/models/holiday_expense.dart';

class HolidayRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final String userId;
  final int profileType;

  HolidayRepository(this.userId, {this.profileType = 0});

  Future<void> insertHoliday(Holiday holiday) async {
    final db = await _dbHelper.database;
    await db.insert('holidays',
        holiday.copyWith(userId: userId, profileType: profileType).toMap());
  }

  Future<List<Holiday>> getHolidays() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'holidays',
      where: 'userId = ? AND profileType = ?',
      whereArgs: [userId, profileType],
      orderBy: 'startDate DESC',
    );
    return result.map((json) => Holiday.fromMap(json)).toList();
  }

  Future<void> deleteHoliday(String id) async {
    final db = await _dbHelper.database;
    await db.delete('holidays',
        where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
    await db.delete('holiday_expenses',
        where: 'holidayId = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<void> insertHolidayExpense(HolidayExpense expense) async {
    final db = await _dbHelper.database;
    await db.insert(
        'holiday_expenses', expense.copyWith(userId: userId).toMap());
  }

  Future<List<HolidayExpense>> getHolidayExpenses(String holidayId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'holiday_expenses',
      where: 'holidayId = ? AND userId = ?',
      whereArgs: [holidayId, userId],
      orderBy: 'date DESC',
    );
    return result.map((json) => HolidayExpense.fromMap(json)).toList();
  }

  Future<void> deleteHolidayExpense(String id) async {
    final db = await _dbHelper.database;
    await db.delete('holiday_expenses',
        where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }
}
