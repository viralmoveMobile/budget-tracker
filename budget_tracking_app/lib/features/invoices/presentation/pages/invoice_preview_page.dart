import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../services/pdf_service.dart';
import '../providers/invoice_provider.dart';
import '../../domain/models/invoice.dart';

class InvoicePreviewPage extends ConsumerStatefulWidget {
  const InvoicePreviewPage({super.key});

  @override
  ConsumerState<InvoicePreviewPage> createState() => _InvoicePreviewPageState();
}

class _InvoicePreviewPageState extends ConsumerState<InvoicePreviewPage> {
  InvoiceTemplate _selectedTemplate = InvoiceTemplate.classic;

  @override
  Widget build(BuildContext context) {
    final invoice = ref.watch(currentInvoiceProvider);
    final settingsAsync = ref.watch(invoiceSettingsProvider);

    if (invoice == null) {
      return const Scaffold(body: Center(child: Text('No invoice to preview')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        actions: [
          DropdownButton<InvoiceTemplate>(
            value: _selectedTemplate,
            onChanged: (val) {
              if (val != null) setState(() => _selectedTemplate = val);
            },
            items: const [
              DropdownMenuItem(
                  value: InvoiceTemplate.classic, child: Text('Classic')),
              DropdownMenuItem(
                  value: InvoiceTemplate.modern, child: Text('Modern')),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: PdfPreview(
        build: (format) {
          print('PdfPreview building for format: $format');
          return PdfService.generateInvoicePdf(
            invoice,
            template: _selectedTemplate,
            settings: settingsAsync.asData?.value,
          );
        },
        onError: (context, error) {
          print('PdfPreview Error: $error');
          return Center(child: Text('Error: $error'));
        },
        allowSharing: true,
        allowPrinting: true,
        canChangePageFormat: false,
        onShared: (context) => _handleSave(invoice),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'invoice_preview_fab',
        onPressed: () => _handleSave(invoice),
        label: const Text('Save & Finish'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  Future<void> _handleSave(Invoice invoice) async {
    await ref.read(invoicesProvider.notifier).saveInvoice(invoice);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved successfully!')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
