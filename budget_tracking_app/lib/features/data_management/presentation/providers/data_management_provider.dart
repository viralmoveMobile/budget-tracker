import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/csv_service.dart';
import '../../services/excel_service.dart';
import '../../services/data_report_service.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../cash_book/presentation/providers/cash_book_provider.dart';
import '../../../invoices/presentation/providers/invoice_provider.dart';
import '../../../expenses/data/models/expense.dart';
import '../../../accounts/data/models/account.dart';
import '../../../cash_book/domain/models/cash_book_entry.dart';
import '../../../invoices/domain/models/invoice.dart';
import '../../../expenses/data/models/expense_category.dart';
import 'dart:io';

final dataManagementProvider = Provider((ref) => DataManagementNotifier(ref));

class DataManagementNotifier {
  final Ref _ref;

  DataManagementNotifier(this._ref);

  Future<void> pickAndImportCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final rows = CsvService.csvToList(csvString);

      if (rows.isEmpty) return;

      final headers =
          rows.first.map((e) => e.toString().toLowerCase()).toList();
      final data = rows.skip(1).toList();

      if (headers.contains('amount') && headers.contains('category')) {
        // Looks like Expenses
        for (var row in data) {
          final expense = Expense(
            id: row[0].toString(),
            amount: double.tryParse(row[1].toString()) ?? 0.0,
            category: ExpenseCategory.values.firstWhere(
              (e) => e.name == row[2].toString(),
              orElse: () => ExpenseCategory.others,
            ),
            date: DateTime.tryParse(row[3].toString()) ?? DateTime.now(),
            notes: row[4]?.toString(),
            linkedAccount: row[5]?.toString(),
            currency: row[6]?.toString() ?? 'USD',
          );
          await _ref.read(expensesProvider.notifier).addExpense(expense);
        }
      } else if (headers.contains('name') && headers.contains('type')) {
        // Looks like Accounts
        for (var row in data) {
          final account = Account(
            id: row[0].toString(),
            name: row[1].toString(),
            type: AccountType.values.firstWhere(
              (e) => e.name == row[2].toString(),
              orElse: () => AccountType.others,
            ),
            description: row[4]?.toString(),
          );
          await _ref.read(accountsProvider.notifier).addAccount(account);
        }
      }
    } catch (e) {
      print('IMPORT ERROR: $e');
      rethrow;
    }
  }

  Future<void> exportAllToCsv() async {
    final expensesAsync = _ref.read(expensesProvider);
    final accountsAsync = _ref.read(accountsProvider);
    final cashEntriesAsync = _ref.read(cashBookProvider);

    final expenses = expensesAsync.value ?? [];
    final accounts = accountsAsync.value ?? [];
    final cashEntries = cashEntriesAsync.when(
      data: (d) => d,
      loading: () => <CashBookEntry>[],
      error: (_, __) => <CashBookEntry>[],
    );

    if (expenses.isNotEmpty) {
      await CsvService.exportAndShareCsv(
        filename: 'Expenses_${DateTime.now().millisecondsSinceEpoch}',
        rows: [
          [
            'ID',
            'Amount',
            'Category',
            'Date',
            'Notes',
            'Linked Account',
            'Currency'
          ],
          ...expenses.map((e) => [
                e.id,
                e.amount,
                e.category.name,
                e.date.toIso8601String(),
                e.notes,
                e.linkedAccount,
                e.currency
              ])
        ],
      );
    }

    if (accounts.isNotEmpty) {
      await CsvService.exportAndShareCsv(
        filename: 'Accounts_${DateTime.now().millisecondsSinceEpoch}',
        rows: [
          ['ID', 'Name', 'Type', 'Description'],
          ...accounts.map((a) => [a.id, a.name, a.type.name, a.description])
        ],
      );
    }

    final invoices = _ref.read(invoicesProvider).value ?? [];
    if (invoices.isNotEmpty) {
      await CsvService.exportAndShareCsv(
        filename: 'Invoices_${DateTime.now().millisecondsSinceEpoch}',
        rows: [
          [
            'ID',
            'Invoice Number',
            'Issue Date',
            'Due Date',
            'Client Name',
            'Subtotal',
            'Tax',
            'Total'
          ],
          ...invoices.map((i) => [
                i.id,
                i.invoiceNumber,
                i.issueDate.toIso8601String(),
                i.dueDate.toIso8601String(),
                i.clientName,
                i.subtotal,
                i.tax,
                i.total
              ])
        ],
      );
    }
  }

  Future<void> exportToExcel() async {
    final expenses = _ref.read(expensesProvider).value ?? [];
    final accounts = _ref.read(accountsProvider).value ?? [];

    final Map<String, List<List<dynamic>>> sheets = {};

    if (expenses.isNotEmpty) {
      sheets['Expenses'] = [
        [
          'ID',
          'Amount',
          'Category',
          'Date',
          'Notes',
          'Linked Account',
          'Currency'
        ],
        ...expenses.map((e) => [
              e.id,
              e.amount,
              e.category.name,
              e.date.toIso8601String(),
              e.notes,
              e.linkedAccount,
              e.currency
            ])
      ];
    }

    if (accounts.isNotEmpty) {
      sheets['Accounts'] = [
        ['ID', 'Name', 'Type', 'Description'],
        ...accounts.map((a) => [a.id, a.name, a.type.name, a.description])
      ];
    }

    if (sheets.isNotEmpty) {
      await ExcelService.exportAndShareExcel(
        filename:
            'Full_Financial_Report_${DateTime.now().millisecondsSinceEpoch}',
        sheets: sheets,
      );
    }
  }

  Future<void> generateAndPrintPDFReport() async {
    final expenses = _ref.read(expensesProvider).value ?? [];
    final accounts = _ref.read(accountsProvider).value ?? [];
    final cashEntriesAsync = _ref.read(cashBookProvider);

    final cashEntries = cashEntriesAsync.when(
      data: (d) => d,
      loading: () => <CashBookEntry>[],
      error: (_, __) => <CashBookEntry>[],
    );

    final pdfData = await DataReportService.generateFinancialSummaryPdf(
      expenses: expenses,
      accounts: accounts,
      cashEntries: cashEntries,
    );

    await DataReportService.printReport(pdfData);
  }
}
