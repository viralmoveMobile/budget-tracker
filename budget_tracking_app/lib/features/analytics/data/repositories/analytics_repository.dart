import 'package:budget_tracking_app/features/expenses/data/models/expense.dart';
import 'package:budget_tracking_app/features/accounts/data/models/transaction.dart';
import 'package:budget_tracking_app/features/expenses/data/local/database_helper.dart';

class AnalyticsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final String userId;

  AnalyticsRepository(this.userId);

  Future<List<Expense>> getExpensesInRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'expenses',
      where: 'userId = ? AND date BETWEEN ? AND ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<List<AccountTransaction>> getIncomeTransactionsInRange(
      DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'userId = ? AND type = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        userId,
        TransactionType.income.name,
        start.toIso8601String(),
        end.toIso8601String()
      ],
      orderBy: 'date DESC',
    );
    return result.map((json) => AccountTransaction.fromMap(json)).toList();
  }
}
