import 'package:budget_tracking_app/features/expenses/data/local/database_helper.dart';
import 'package:budget_tracking_app/features/my_account/domain/models/user_profile.dart'; // Import ProfileType
import '../../domain/models/cash_book_entry.dart';
import '../../domain/models/cash_account.dart';

class CashBookRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final String userId;
  final int profileType; // 0 = Personal, 1 = Business

  CashBookRepository(this.userId, {this.profileType = 0});

  Future<void> insertEntry(CashBookEntry entry) async {
    final db = await _dbHelper.database;
    await db.insert(
        'cash_book_entries',
        entry
            .copyWith(
                userId: userId, profileType: ProfileType.values[profileType])
            .toMap());
  }

  Future<List<CashBookEntry>> getAllEntries({String? accountId}) async {
    final db = await _dbHelper.database;
    final whereClause = accountId != null
        ? 'accountId = ? AND userId = ? AND profileType = ?'
        : 'userId = ? AND profileType = ?';
    final whereArgs = accountId != null
        ? [accountId, userId, profileType]
        : [userId, profileType];

    final result = await db.query(
      'cash_book_entries',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return result.map((json) => CashBookEntry.fromMap(json)).toList();
  }

  Future<List<CashAccount>> getAccounts() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'cash_accounts',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.map((json) => CashAccount.fromMap(json)).toList();
  }

  Future<void> insertAccount(CashAccount account) async {
    final db = await _dbHelper.database;
    await db.insert('cash_accounts', account.copyWith(userId: userId).toMap());
  }

  Future<void> deleteEntry(String id) async {
    final db = await _dbHelper.database;
    await db.delete('cash_book_entries',
        where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }
}
