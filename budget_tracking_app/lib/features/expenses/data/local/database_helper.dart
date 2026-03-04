import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/budget_limit.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('budget.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 23,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        print('Database opened. Verifying tables...');
        await _verifyTables(db);
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _verifyTables(Database db) async {
    // Fallback to ensure tables exist even if migration was skipped during hot reload
    final tables = await db.query('sqlite_master',
        where: 'name = ?', whereArgs: ['cash_book_entries']);
    if (tables.isEmpty) {
      print('Creating missing cash_book_entries table...');
      await _createCashBookTable(db);
    }

    final accountTables = await db.query('sqlite_master',
        where: 'name = ?', whereArgs: ['cash_accounts']);
    if (accountTables.isEmpty) {
      print('Creating missing cash_accounts table...');
      await _createCashAccountTable(db);
    } else {
      // Ensure at least one account exists
      final accounts = await db.query('cash_accounts');
      if (accounts.isEmpty) {
        await db.insert('cash_accounts', {
          'id': 'default_cash_account',
          'name': 'Main Cash Account',
          'description': 'Primary ledger for cash tracking'
        });
      }

      // Double check columns in entries
      final List<Map<String, dynamic>> entryCols =
          await db.rawQuery('PRAGMA table_info(cash_book_entries)');
      final bool hasAccountId = entryCols.any((c) => c['name'] == 'accountId');
      if (!hasAccountId) {
        await db
            .execute('ALTER TABLE cash_book_entries ADD COLUMN accountId TEXT');
        // Migrate existing entries to default account
        await db.execute(
            'UPDATE cash_book_entries SET accountId = ? WHERE accountId IS NULL',
            ['default_cash_account']);
      }
    }

    final holidayTables = await db
        .query('sqlite_master', where: 'name = ?', whereArgs: ['holidays']);
    if (holidayTables.isEmpty) {
      print('Creating missing holiday tables...');
      await _createHolidayTables(db);
    }

    final sharingTables = await db.query('sqlite_master',
        where: 'name = ?', whereArgs: ['sharing_groups']);
    if (sharingTables.isEmpty) {
      print('Creating missing sharing tables...');
      await _createSharingTables(db);
    }

    final goalTables = await db.query('sqlite_master',
        where: 'name = ?', whereArgs: ['financial_goals']);
    if (goalTables.isEmpty) {
      print('Creating missing financial_goals table...');
      await _createGoalsTable(db);
    }

    final invoiceTables = await db
        .query('sqlite_master', where: 'name = ?', whereArgs: ['invoices']);
    if (invoiceTables.isEmpty) {
      print('Creating missing invoice tables...');
      await _createInvoiceTables(db);
    }

    // New verification for isIncome column
    final List<Map<String, dynamic>> columns =
        await db.rawQuery('PRAGMA table_info(expenses)');
    final bool hasIsIncome = columns.any((c) => c['name'] == 'isIncome');
    if (!hasIsIncome) {
      print('Adding missing isIncome column to expenses table...');
      await db.execute(
          'ALTER TABLE expenses ADD COLUMN isIncome INTEGER NOT NULL DEFAULT 0');
    }

    // Verify accounts table
    final List<Map<String, dynamic>> accountColumns =
        await db.rawQuery('PRAGMA table_info(accounts)');
    final bool hasType = accountColumns.any((c) => c['name'] == 'type');
    if (!hasType) {
      print('Adding missing type column to accounts table...');
      await db.execute(
          'ALTER TABLE accounts ADD COLUMN type TEXT NOT NULL DEFAULT "personal"');
    }

    // Verify wage tables
    final wageTables = await db
        .query('sqlite_master', where: 'name = ?', whereArgs: ['wage_jobs']);
    if (wageTables.isEmpty) {
      print('Creating missing wage tables...');
      await _createWageTables(db);
    }

    // Verify invoice status column
    final List<Map<String, dynamic>> invoiceCols =
        await db.rawQuery('PRAGMA table_info(invoices)');
    final bool hasStatus = invoiceCols.any((c) => c['name'] == 'status');
    if (!hasStatus) {
      await db.execute(
          'ALTER TABLE invoices ADD COLUMN status TEXT DEFAULT "unpaid"');
    }

    final settingsTables = await db.query('sqlite_master',
        where: 'name = ?', whereArgs: ['invoice_settings']);
    if (settingsTables.isEmpty) {
      await _createInvoiceSettingsTable(db);
    }

    // Fix: Ensure profileType exists (missed in some create scripts)
    final expCols = await db.rawQuery('PRAGMA table_info(expenses)');
    if (!expCols.any((c) => c['name'] == 'profileType')) {
      await db.execute(
          'ALTER TABLE expenses ADD COLUMN profileType INTEGER NOT NULL DEFAULT 0');
    }

    final budgetCols = await db.rawQuery('PRAGMA table_info(budget_limits)');
    if (!budgetCols.any((c) => c['name'] == 'profileType')) {
      await db.execute(
          'ALTER TABLE budget_limits ADD COLUMN profileType INTEGER NOT NULL DEFAULT 0');
    }

    final cbCols = await db.rawQuery('PRAGMA table_info(cash_book_entries)');
    if (!cbCols.any((c) => c['name'] == 'profileType')) {
      await db.execute(
          'ALTER TABLE cash_book_entries ADD COLUMN profileType INTEGER NOT NULL DEFAULT 0');
    }

    // Verify other tables for profileType (v22)
    final tablesToCheck = [
      'accounts',
      'cash_accounts',
      'wage_jobs',
      'holidays',
      'financial_goals',
      'invoices',
      'invoice_settings'
    ];

    for (var table in tablesToCheck) {
      final cols = await db.rawQuery('PRAGMA table_info($table)');
      if (cols.isNotEmpty && !cols.any((c) => c['name'] == 'profileType')) {
        try {
          await db.execute(
              'ALTER TABLE $table ADD COLUMN profileType INTEGER NOT NULL DEFAULT 0');
        } catch (e) {
          print('Error adding profileType to $table: $e');
        }
      }
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Updating database from $oldVersion to $newVersion');
    if (oldVersion < 2) {
      await _createAccountsAndTransactions(db);
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
            'ALTER TABLE expenses ADD COLUMN currency TEXT NOT NULL DEFAULT "USD"');
      } catch (e) {
        print('Column currency might already exist: $e');
      }
    }
    if (oldVersion < 4) {
      await _createHolidayTables(db);
    }
    if (oldVersion < 5) {
      await _createCashBookTable(db);
    }
    if (oldVersion < 6) {
      await _createSharingTables(db);
    }
    if (oldVersion < 7) {
      await _createGoalsTable(db);
    }
    if (oldVersion < 8) {
      await _createInvoiceTables(db);
    }
    if (oldVersion < 9) {
      try {
        await db.execute(
            'ALTER TABLE expenses ADD COLUMN isIncome INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        print('Column isIncome might already exist: $e');
      }
    }
    if (oldVersion < 11) {
      await _migrateAccountsTableV11(db);
    }
    if (oldVersion < 12) {
      await _createWageTables(db);
    }
    if (oldVersion < 13) {
      try {
        await db
            .execute('ALTER TABLE expenses ADD COLUMN homeCurrencyAmount REAL');
      } catch (e) {
        print('Column homeCurrencyAmount might already exist: $e');
      }
    }
    if (oldVersion < 19) {
      await _migrateToV19(db);
    }
    if (oldVersion < 20) {
      await _migrateToV20(db);
    }
    if (oldVersion < 21) {
      await _migrateToV21(db);
    }
    if (oldVersion < 22) {
      await _migrateToV22(db);
    }
    if (oldVersion < 23) {
      await _migrateToV23(db);
    }
  }

  Future<void> _migrateToV23(Database db) async {
    print(
        'Migrating holiday_expenses to v23: making originalAmount nullable...');
    await db.transaction((txn) async {
      await txn.execute(
          'ALTER TABLE holiday_expenses RENAME TO holiday_expenses_old');
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const doubleType = 'REAL NOT NULL';
      const textNullableType = 'TEXT';
      await txn.execute('''
CREATE TABLE holiday_expenses (
  id $idType,
  userId TEXT,
  holidayId $textType,
  amount $doubleType,
  originalAmount REAL,
  currency $textType,
  category $textType,
  date $textType,
  description $textType,
  receiptPath $textNullableType,
  FOREIGN KEY (holidayId) REFERENCES holidays (id) ON DELETE CASCADE
)
''');
      await txn.execute('''
        INSERT INTO holiday_expenses (id, userId, holidayId, amount, originalAmount, currency, category, date, description, receiptPath)
        SELECT id, userId, holidayId, amount, originalAmount, currency, category, date, description, receiptPath FROM holiday_expenses_old
      ''');
      await txn.execute('DROP TABLE holiday_expenses_old');
    });
  }

  Future<void> _migrateToV20(Database db) async {
    print('Migrating to v20: Adding profileType to cash_book_entries...');
    try {
      await db.execute(
          'ALTER TABLE cash_book_entries ADD COLUMN profileType INTEGER NOT NULL DEFAULT 0');
    } catch (e) {
      print('Error adding profileType to cash_book_entries (v20): $e');
    }
  }

  Future<void> _migrateToV21(Database db) async {
    print('Migrating to v21: Verifying profileType in cash_book_entries...');
    try {
      // Re-run the v20 migration logic just in case it was missed or if created fresh with v20 schema
      // but without the column (bug fix).
      final List<Map<String, dynamic>> columns =
          await db.rawQuery('PRAGMA table_info(cash_book_entries)');
      final bool hasProfileType =
          columns.any((c) => c['name'] == 'profileType');
      if (!hasProfileType) {
        await db.execute(
            'ALTER TABLE cash_book_entries ADD COLUMN profileType INTEGER NOT NULL DEFAULT 0');
      }
    } catch (e) {
      print('Error verifying profileType in cash_book_entries (v21): $e');
    }
  }

  Future<void> _migrateToV22(Database db) async {
    print('Migrating to v22: Adding profileType to all remaining tables...');
    final tables = [
      'accounts',
      'cash_accounts',
      'wage_jobs',
      'holidays',
      'financial_goals',
      'invoices',
      'invoice_settings'
    ];

    for (var table in tables) {
      try {
        await db.execute(
            'ALTER TABLE $table ADD COLUMN profileType INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        print('Error adding profileType to $table (v22): $e');
      }
    }
  }

  Future<void> _migrateToV19(Database db) async {
    print(
        'Migrating to v19: Adding profileType to expenses and budget_limits...');
    try {
      await db.execute(
          'ALTER TABLE expenses ADD COLUMN profileType INTEGER NOT NULL DEFAULT 0');
    } catch (e) {
      print('Error adding profileType to expenses: $e');
    }
    try {
      await db.execute(
          'ALTER TABLE budget_limits ADD COLUMN profileType INTEGER NOT NULL DEFAULT 0');
    } catch (e) {
      print('Error adding profileType to budget_limits: $e');
    }
  }

  Future<void> _migrateToV18(Database db) async {
    print('Migrating to v18: Adding userId column to all tables...');
    final tables = [
      'expenses',
      'budget_limits',
      'accounts',
      'transactions',
      'holidays',
      'holiday_expenses',
      'cash_accounts',
      'cash_book_entries',
      'sharing_groups',
      'sharing_members',
      'financial_goals',
      'invoices',
      'invoice_items',
      'invoice_settings',
      'wage_jobs',
      'work_entries'
    ];

    for (var table in tables) {
      try {
        await db.execute('ALTER TABLE $table ADD COLUMN userId TEXT');
      } catch (e) {
        print('Error adding userId to $table: $e');
      }
    }
  }

  Future<void> _migrateToAccountBasedCashBook(Database db) async {
    print('Migrating Cash Book to multi-account (v16)...');

    // 1. Create cash_accounts if missing
    final accountTables = await db.query('sqlite_master',
        where: 'name = ?', whereArgs: ['cash_accounts']);
    if (accountTables.isEmpty) {
      await _createCashAccountTable(db);
    } else {
      // Ensure default account exists
      final accounts = await db.query('cash_accounts');
      if (accounts.isEmpty) {
        await db.insert('cash_accounts', {
          'id': 'default_cash_account',
          'name': 'Main Cash Account',
          'description': 'Primary ledger for cash tracking'
        });
      }
    }

    // 2. Add accountId to cash_book_entries if missing
    final List<Map<String, dynamic>> columns =
        await db.rawQuery('PRAGMA table_info(cash_book_entries)');
    final bool hasAccountId = columns.any((c) => c['name'] == 'accountId');

    if (!hasAccountId) {
      await db
          .execute('ALTER TABLE cash_book_entries ADD COLUMN accountId TEXT');
      // Migrate existing entries to default account
      await db.execute(
          'UPDATE cash_book_entries SET accountId = ? WHERE accountId IS NULL',
          ['default_cash_account']);
    }
  }

  Future<void> _migrateAccountsTableV11(Database db) async {
    print('Migrating accounts table to version 11...');
    // This handles any legacy NOT NULL constraints (like balance) by recreating the table
    await db.transaction((txn) async {
      // 1. Rename old table
      await txn.execute('ALTER TABLE accounts RENAME TO accounts_old');

      // 2. Create new table
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const textNullableType = 'TEXT';

      await txn.execute('''
        CREATE TABLE accounts (
          id $idType,
          name $textType,
          type $textType,
          description $textNullableType
        )
      ''');

      // 3. Copy data (only columns that exist in the new schema)
      // We use a safe copy that handles missing source columns
      final List<Map<String, dynamic>> oldColumns =
          await txn.rawQuery('PRAGMA table_info(accounts_old)');
      final bool hasType = oldColumns.any((c) => c['name'] == 'type');
      final bool hasDescription =
          oldColumns.any((c) => c['name'] == 'description');

      String selectCols = 'id, name';
      if (hasType)
        selectCols += ', type';
      else
        selectCols += ', "personal" as type'; // Provide default if missing

      if (hasDescription)
        selectCols += ', description';
      else
        selectCols += ', NULL as description';

      await txn.execute('''
        INSERT INTO accounts (id, name, type, description)
        SELECT $selectCols FROM accounts_old
      ''');

      // 4. Drop old table
      await txn.execute('DROP TABLE accounts_old');
    });
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const textNullableType = 'TEXT';

    await db.execute('''
CREATE TABLE expenses (
  id $idType,
  userId TEXT,
  amount $doubleType,
  category $textType,
  date $textType,
  notes $textNullableType,
  linkedAccount $textNullableType,
   currency $textType,
   isIncome INTEGER NOT NULL DEFAULT 0,
   homeCurrencyAmount REAL,
   profileType INTEGER NOT NULL DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE budget_limits (
  id $idType,
  userId TEXT,
  amount $doubleType,
  category $textNullableType,
  month $integerType,
  year $integerType,
  profileType INTEGER NOT NULL DEFAULT 0
)
''');

    await _createAccountsAndTransactions(db);
    await _createHolidayTables(db);
    await _createCashAccountTable(db);
    await _createCashBookTable(db);
    await _createSharingTables(db);
    await _createGoalsTable(db);
    await _createInvoiceTables(db);
    await _createInvoiceSettingsTable(db);
    await _createWageTables(db);
  }

  Future _createWageTables(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textNullableType = 'TEXT';

    await db.execute('''
CREATE TABLE wage_jobs (
  id $idType,
  userId TEXT,
  name $textType,
  mode $textType,
  baseAmount $doubleType,
  overtimeRate $doubleType,
  taxPercentage $doubleType,
  employer $textNullableType,
  profileType INTEGER NOT NULL DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE work_entries (
  id $idType,
  userId TEXT,
  jobId $textType,
  date $textType,
  hours $doubleType,
  overtimeHours $doubleType,
  notes $textNullableType,
  FOREIGN KEY (jobId) REFERENCES wage_jobs (id) ON DELETE CASCADE
)
''');
  }

  Future _createInvoiceTables(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textNullableType = 'TEXT';

    await db.execute('''
CREATE TABLE invoices (
  id $idType,
  userId TEXT,
  invoiceNumber $textType,
  issueDate $textType,
  dueDate $textType,
  clientName $textType,
  clientEmail $textNullableType,
  clientAddress $textNullableType,
  subtotal $doubleType,
  tax $doubleType,
  total $doubleType,
  status TEXT DEFAULT "unpaid",
  profileType INTEGER NOT NULL DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE invoice_items (
  id $idType,
  userId TEXT,
  invoiceId $textType,
  description $textType,
  quantity $doubleType,
  rate $doubleType,
  total $doubleType,
  FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
)
''');
  }

  Future _createInvoiceSettingsTable(Database db) async {
    await db.execute('''
CREATE TABLE invoice_settings (
  id INTEGER PRIMARY KEY,
  userId TEXT,
  companyName TEXT,
  companyAddress TEXT,
  companyEmail TEXT,
  companyPhone TEXT,
  logoPath TEXT,
  defaultTaxRate REAL,
  defaultHourlyRate REAL,
  bankName TEXT,
  accountName TEXT,
  accountNumber TEXT,
  routingNumber TEXT,
  profileType INTEGER NOT NULL DEFAULT 0
)
''');

    // Insert initial empty settings
    await db.insert('invoice_settings', {
      'id': 1,
      'companyName': '',
      'companyAddress': '',
      'companyEmail': '',
      'companyPhone': '',
      'bankName': '',
      'accountName': '',
      'accountNumber': ''
    });
  }

  Future _createGoalsTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE financial_goals (
  id $idType,
  userId TEXT,
  name $textType,
  targetAmount $doubleType,
  currentAmount $doubleType,
  deadline $textType,
  type $textType,
  profileType INTEGER NOT NULL DEFAULT 0
)
''');
  }

  Future _createSharingTables(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE sharing_groups (
  id $idType,
  userId TEXT,
  name $textType,
  description $textType,
  sharedDataTypes $textType
)
''');

    await db.execute('''
CREATE TABLE sharing_members (
  id $idType,
  userId TEXT,
  groupId $textType,
  name $textType,
  email $textType,
  permission $textType,
  FOREIGN KEY (groupId) REFERENCES sharing_groups (id) ON DELETE CASCADE
)
''');
  }

  Future _createCashAccountTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';

    await db.execute('''
CREATE TABLE cash_accounts (
  id $idType,
  userId TEXT,
  name $textType,
  description $textNullableType,
  profileType INTEGER NOT NULL DEFAULT 0
)
''');

    // Insert default account
    await db.insert('cash_accounts', {
      'id': 'default_cash_account',
      'name': 'Main Cash Account',
      'description': 'Primary ledger for cash tracking'
    });
  }

  Future _createCashBookTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textNullableType = 'TEXT';

    await db.execute('''
CREATE TABLE cash_book_entries (
  id $idType,
  userId TEXT,
  amount $doubleType,
  date $textType,
  description $textType,
  type $textType,
  category $textType,
  accountId $textNullableType,
  profileType INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (accountId) REFERENCES cash_accounts (id) ON DELETE CASCADE
)
''');
  }

  Future _createHolidayTables(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textNullableType = 'TEXT';

    await db.execute('''
CREATE TABLE holidays (
  id $idType,
  userId TEXT,
  name $textType,
  startDate $textType,
  endDate $textType,
  totalBudget $doubleType,
  notes $textNullableType,
  profileType INTEGER NOT NULL DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE holiday_expenses (
  id $idType,
  userId TEXT,
  holidayId $textType,
  amount $doubleType,
  originalAmount REAL,
  currency $textType,
  category $textType,
  date $textType,
  description $textType,
  receiptPath $textNullableType,
  FOREIGN KEY (holidayId) REFERENCES holidays (id) ON DELETE CASCADE
)
''');
  }

  Future _createAccountsAndTransactions(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textNullableType = 'TEXT';

    await db.execute('''
CREATE TABLE accounts (
  id $idType,
  userId TEXT,
  name $textType,
  type $textType,
  description $textNullableType,
  profileType INTEGER NOT NULL DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  userId TEXT,
  accountId $textType,
  amount $doubleType,
  type $textType,
  category $textType,
  date $textType,
  notes $textNullableType,
  relatedTransactionId $textNullableType
)
''');
  }

  // Expense CRUD
  Future<void> insertExpense(Expense expense) async {
    final db = await instance.database;
    await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses(String userId, int profileType) async {
    final db = await instance.database;
    final result = await db.query(
      'expenses',
      where: 'userId = ? AND profileType = ?',
      whereArgs: [userId, profileType],
      orderBy: 'date DESC',
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await instance.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id, String userId) async {
    final db = await instance.database;
    await db.delete(
      'expenses',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  // Budget Limits CRUD
  Future<void> insertBudgetLimit(BudgetLimit limit) async {
    final db = await instance.database;
    await db.insert('budget_limits', limit.toMap());
  }

  Future<List<BudgetLimit>> getBudgetLimits(
      int month, int year, String userId, int profileType) async {
    final db = await instance.database;
    final result = await db.query(
      'budget_limits',
      where: 'month = ? AND year = ? AND userId = ? AND profileType = ?',
      whereArgs: [month, year, userId, profileType],
    );
    return result.map((json) => BudgetLimit.fromMap(json)).toList();
  }

  Future<void> updateBudgetLimit(BudgetLimit limit) async {
    final db = await instance.database;
    await db.update(
      'budget_limits',
      limit.toMap(),
      where: 'id = ?',
      whereArgs: [limit.id],
    );
  }
}
