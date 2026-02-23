import 'package:sqflite/sqflite.dart';
import '../../../expenses/data/local/database_helper.dart';
import '../../domain/models/invoice_settings.dart';
import '../../domain/models/invoice.dart';
import '../../domain/models/invoice_item.dart';

class InvoiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final String userId;
  final int profileType;

  InvoiceRepository(this.userId, {this.profileType = 0});

  Future<void> saveInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Insert/Update Invoice
      await txn.insert(
        'invoices',
        invoice.copyWith(userId: userId, profileType: profileType).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Delete existing items (if update)
      await txn.delete(
        'invoice_items',
        where: 'invoiceId = ? AND userId = ?',
        whereArgs: [invoice.id, userId],
      );

      // 3. Insert items
      for (var item in invoice.items) {
        await txn.insert(
            'invoice_items', item.copyWith(userId: userId).toMap());
      }
    });
  }

  Future<List<Invoice>> getInvoices() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'issueDate DESC',
    );

    List<Invoice> invoices = [];
    for (var map in maps) {
      final items = await _getInvoiceItems(map['id']);
      invoices.add(Invoice.fromMap(map, items: items));
    }
    return invoices;
  }

  Future<List<InvoiceItem>> _getInvoiceItems(String invoiceId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoice_items',
      where: 'invoiceId = ? AND userId = ?',
      whereArgs: [invoiceId, userId],
    );
    return maps.map((m) => InvoiceItem.fromMap(m)).toList();
  }

  Future<void> deleteInvoice(String id) async {
    final db = await _dbHelper.database;
    await db.delete('invoices',
        where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
    await db.delete('invoice_items',
        where: 'invoiceId = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<InvoiceSettings> getSettings() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoice_settings',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return InvoiceSettings.fromMap(maps.first);
    }
    return InvoiceSettings.empty();
  }

  Future<void> updateSettings(InvoiceSettings settings) async {
    final db = await _dbHelper.database;
    final settingsMap = settings.copyWith(userId: userId).toMap();
    await db.insert(
      'invoice_settings',
      settingsMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateInvoiceStatus(String id, InvoiceStatus status) async {
    final db = await _dbHelper.database;
    await db.update(
      'invoices',
      {'status': status.name},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }
}
