import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../expenses/data/models/expense.dart';
import '../../accounts/data/models/account.dart';
import '../../cash_book/domain/models/cash_book_entry.dart';

class DataReportService {
  static Future<Uint8List> generateFinancialSummaryPdf({
    required List<Expense> expenses,
    required List<Account> accounts,
    required List<CashBookEntry> cashEntries,
    DateTimeRange? dateRange,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('FINANCIAL SUMMARY REPORT',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                if (dateRange != null)
                  pw.Text(
                      '${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildAccountsSummary(accounts),
          pw.SizedBox(height: 30),
          _buildExpenseSummary(expenses),
          pw.SizedBox(height: 30),
          _buildBalanceSummary(expenses, cashEntries),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildAccountsSummary(List<Account> accounts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ACCOUNTS OVERVIEW',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Pool Name', 'Type'],
          data: accounts
              .map((a) => [
                    a.name,
                    (a.type.name ?? 'Unknown').toUpperCase(),
                  ])
              .toList(),
        ),
        pw.SizedBox(height: 5),
      ],
    );
  }

  static pw.Widget _buildExpenseSummary(List<Expense> expenses) {
    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('EXPENSE BREAKDOWN',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Category', 'Description', 'Amount'],
          data: expenses
              .map((e) => [
                    DateFormat('MM/dd').format(e.date),
                    e.category.name ?? 'Unknown',
                    e.notes ?? '-',
                    '\$${e.amount.toStringAsFixed(2)}'
                  ])
              .toList(),
        ),
        pw.SizedBox(height: 5),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Total Expenses: \$${totalExpense.toStringAsFixed(2)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  static pw.Widget _buildBalanceSummary(
      List<Expense> expenses, List<CashBookEntry> cashEntries) {
    // This is just a simple metric placeholder
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: PdfColors.grey100),
      child: pw.Column(
        children: [
          pw.Text('End of Report',
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
        ],
      ),
    );
  }

  static Future<void> printReport(Uint8List pdfData) async {
    await Printing.layoutPdf(onLayout: (format) async => pdfData);
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  DateTimeRange({required this.start, required this.end});
}
