import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/invoice.dart';
import '../domain/models/invoice_settings.dart';
import 'package:intl/intl.dart';

enum InvoiceTemplate { classic, modern }

class PdfService {
  static Future<Uint8List> generateInvoicePdf(
    Invoice invoice, {
    InvoiceTemplate template = InvoiceTemplate.classic,
    InvoiceSettings? settings,
  }) async {
    try {
      print('Generating PDF for invoice: ${invoice.invoiceNumber}');
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            if (template == InvoiceTemplate.classic)
              ..._buildClassicTemplate(invoice, settings)
            else
              ..._buildModernTemplate(invoice, settings),
          ],
        ),
      );

      final bytes = await pdf.save();
      print('PDF generated successfully, size: ${bytes.length} bytes');
      return bytes;
    } catch (e, st) {
      print('ERROR GENERATING PDF: $e');
      print(st);
      rethrow;
    }
  }

  static List<pw.Widget> _buildClassicTemplate(
      Invoice invoice, InvoiceSettings? settings) {
    return [
      if (settings != null && settings.companyName.isNotEmpty)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(settings.companyName,
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.Text(settings.companyAddress,
                style: const pw.TextStyle(fontSize: 10)),
            pw.Text('${settings.companyEmail} | ${settings.companyPhone}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 20),
          ],
        ),
      pw.Header(
        level: 0,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('INVOICE',
                style:
                    pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold)),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Invoice #: ${invoice.invoiceNumber}'),
                pw.Text(
                    'Date: ${DateFormat('dd MMM yyyy').format(invoice.issueDate)}'),
                pw.Text(
                    'Due: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}'),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 30),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('BILL TO:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice.clientName),
              if (invoice.clientEmail != null) pw.Text(invoice.clientEmail!),
              if (invoice.clientAddress != null)
                pw.Text(invoice.clientAddress!),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 40),
      _buildItemTable(invoice),
      pw.SizedBox(height: 30),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildTotalRow('Subtotal', invoice.subtotal),
              _buildTotalRow('Tax', invoice.tax),
              pw.Divider(),
              _buildTotalRow('Total', invoice.total, isTotal: true),
            ],
          ),
        ],
      ),
      if (settings != null && settings.bankName.isNotEmpty) ...[
        pw.SizedBox(height: 40),
        pw.Divider(),
        pw.Text('PAYMENT INFORMATION',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 10),
        pw.Text('Bank: ${settings.bankName}'),
        pw.Text('Account: ${settings.accountName}'),
        pw.Text('Account Number: ${settings.accountNumber}'),
        if (settings.routingNumber != null)
          pw.Text('Routing/IBAN: ${settings.routingNumber}'),
      ],
    ];
  }

  static List<pw.Widget> _buildModernTemplate(
      Invoice invoice, InvoiceSettings? settings) {
    final baseColor = PdfColors.blue900;
    return [
      pw.Container(
        height: 60,
        color: baseColor,
        padding: const pw.EdgeInsets.all(10),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(settings?.companyName ?? 'INVOICE',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold)),
                if (settings != null)
                  pw.Text(settings.companyEmail,
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 8)),
              ],
            ),
            pw.Text(invoice.invoiceNumber,
                style: pw.TextStyle(color: PdfColors.white, fontSize: 18)),
          ],
        ),
      ),
      pw.SizedBox(height: 30),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CLIENT',
                    style: pw.TextStyle(
                        color: baseColor, fontWeight: pw.FontWeight.bold)),
                pw.Text(invoice.clientName, style: pw.TextStyle(fontSize: 16)),
                if (invoice.clientEmail != null) pw.Text(invoice.clientEmail!),
                if (invoice.clientAddress != null)
                  pw.Text(invoice.clientAddress!),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('ISSUED',
                  style: pw.TextStyle(
                      color: baseColor, fontWeight: pw.FontWeight.bold)),
              pw.Text(DateFormat('dd MMM yyyy').format(invoice.issueDate)),
              pw.SizedBox(height: 10),
              pw.Text('DUE DATE',
                  style: pw.TextStyle(
                      color: baseColor, fontWeight: pw.FontWeight.bold)),
              pw.Text(DateFormat('dd MMM yyyy').format(invoice.dueDate)),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 40),
      _buildItemTable(invoice, modern: true, baseColor: baseColor),
      pw.SizedBox(height: 30),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Container(
          width: 200,
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal', invoice.subtotal),
              _buildTotalRow('Tax', invoice.tax),
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 5),
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: baseColor,
                child: _buildTotalRow('BALANCE DUE', invoice.total,
                    isTotal: true, color: PdfColors.white),
              ),
            ],
          ),
        ),
      ),
      if (settings != null && settings.bankName.isNotEmpty) ...[
        pw.SizedBox(height: 50),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PAYMENT DETAILS',
                  style: pw.TextStyle(
                      color: baseColor,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10)),
              pw.SizedBox(height: 5),
              pw.Text('${settings.bankName} | ${settings.accountName}',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text('ACC NO: ${settings.accountNumber}',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
              if (settings.routingNumber != null)
                pw.Text('IBAN/ROUTING: ${settings.routingNumber}',
                    style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    ];
  }

  static pw.Widget _buildItemTable(Invoice invoice,
      {bool modern = false, PdfColor? baseColor}) {
    final headers = ['Description', 'Qty', 'Rate', 'Total'];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: invoice.items.map((item) {
        return [
          item.description,
          item.quantity.toString(),
          item.rate.toStringAsFixed(2),
          item.total.toStringAsFixed(2),
        ];
      }).toList(),
      border: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: modern ? PdfColors.white : PdfColors.black,
      ),
      headerDecoration: pw.BoxDecoration(
        color: modern ? baseColor : PdfColors.grey200,
      ),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount,
      {bool isTotal = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontWeight: isTotal ? pw.FontWeight.bold : null,
                  color: color)),
          pw.Text('\$ ${amount.toStringAsFixed(2)}',
              style: pw.TextStyle(
                  fontWeight: isTotal ? pw.FontWeight.bold : null,
                  color: color)),
        ],
      ),
    );
  }

  static Future<void> sharePdf(Uint8List pdfData, String filename) async {
    await Printing.sharePdf(bytes: pdfData, filename: filename);
  }
}
