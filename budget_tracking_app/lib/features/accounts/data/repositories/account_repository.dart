import 'package:budget_tracking_app/features/expenses/data/local/database_helper.dart';
import '../models/account.dart';
import '../models/transaction.dart';

class AccountRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final String userId;
  final int profileType;

  AccountRepository(this.userId, {this.profileType = 0});

  Future<List<Account>> getAccounts() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'accounts',
      where: 'userId = ? AND profileType = ?',
      whereArgs: [userId, profileType],
    );
    return result.map((json) => Account.fromMap(json)).toList();
  }

  Future<void> addAccount(Account account) async {
    final db = await _dbHelper.database;
    await db.insert('accounts',
        account.copyWith(userId: userId, profileType: profileType).toMap());
  }

  Future<void> updateAccount(Account account) async {
    final db = await _dbHelper.database;
    await db.update(
      'accounts',
      account.copyWith(userId: userId, profileType: profileType).toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [account.id, userId],
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await _dbHelper.database;
    await db.delete('accounts',
        where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
    await db.delete('transactions',
        where: 'accountId = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<List<AccountTransaction>> getTransactions(String accountId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'accountId = ? AND userId = ?',
      whereArgs: [accountId, userId],
      orderBy: 'date DESC',
    );
    return result.map((json) => AccountTransaction.fromMap(json)).toList();
  }

  Future<void> addTransaction(AccountTransaction transaction) async {
    final db = await _dbHelper.database;
    await db.insert(
        'transactions', transaction.copyWith(userId: userId).toMap());
  }

  Future<void> transferFunds({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    final transferId = DateTime.now()
        .millisecondsSinceEpoch
        .toString(); // Simple ID for linking

    await db.transaction((txn) async {
      // 3. Record transactions
      await txn.insert('transactions', {
        'id': 'T_OUT_$transferId',
        'userId': userId,
        'accountId': fromAccountId,
        'amount': amount,
        'type': 'transfer',
        'category': 'Transfer Out',
        'date': date.toIso8601String(),
        'notes': notes,
        'relatedTransactionId': toAccountId,
      });

      await txn.insert('transactions', {
        'id': 'T_IN_$transferId',
        'userId': userId,
        'accountId': toAccountId,
        'amount': amount,
        'type': 'transfer',
        'category': 'Transfer In',
        'date': date.toIso8601String(),
        'notes': notes,
        'relatedTransactionId': fromAccountId,
      });
    });
  }
}
