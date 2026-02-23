import 'package:budget_tracking_app/features/expenses/data/local/database_helper.dart';
import '../../domain/models/financial_goal.dart';

class GoalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final String userId;
  final int profileType;

  GoalRepository(this.userId, {this.profileType = 0});

  Future<void> insertGoal(FinancialGoal goal) async {
    final db = await _dbHelper.database;
    await db.insert('financial_goals',
        goal.copyWith(userId: userId, profileType: profileType).toMap());
  }

  Future<List<FinancialGoal>> getGoals() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'financial_goals',
      where: 'userId = ? AND profileType = ?',
      whereArgs: [userId, profileType],
    );
    return result.map((json) => FinancialGoal.fromMap(json)).toList();
  }

  Future<void> updateGoal(FinancialGoal goal) async {
    final db = await _dbHelper.database;
    await db.update(
      'financial_goals',
      goal.copyWith(userId: userId, profileType: profileType).toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [goal.id, userId],
    );
  }

  Future<void> deleteGoal(String id) async {
    final db = await _dbHelper.database;
    await db.delete('financial_goals',
        where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }
}
