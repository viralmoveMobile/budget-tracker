import '../local/database_helper.dart';
import '../models/expense.dart';
import '../models/budget_limit.dart';

class ExpenseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final String userId;
  final int profileType; // 0 = Personal, 1 = Business

  ExpenseRepository(this.userId, {this.profileType = 0});

  Future<List<Expense>> getExpenses() async {
    return await _dbHelper.getAllExpenses(userId, profileType);
  }

  Future<void> addExpense(Expense expense) async {
    await _dbHelper.insertExpense(expense.copyWith(userId: userId));
  }

  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.updateExpense(expense.copyWith(userId: userId));
  }

  Future<void> deleteExpense(String id) async {
    await _dbHelper.deleteExpense(id, userId);
  }

  Future<List<BudgetLimit>> getBudgetLimits(int month, int year) async {
    return await _dbHelper.getBudgetLimits(month, year, userId, profileType);
  }

  Future<void> saveBudgetLimit(BudgetLimit limit) async {
    final limitWithUser = limit.copyWith(userId: userId);
    final existing = await _dbHelper.getBudgetLimits(
        limitWithUser.month, limitWithUser.year, userId, profileType);
    final sameCategory =
        existing.any((e) => e.category == limitWithUser.category);

    if (sameCategory) {
      await _dbHelper.updateBudgetLimit(limitWithUser);
    } else {
      await _dbHelper.insertBudgetLimit(limitWithUser);
    }
  }
}
