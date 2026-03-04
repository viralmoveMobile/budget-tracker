import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart'; // Added for PdfPreview
import '../../../../core/theme/app_theme.dart';
import '../providers/invoice_provider.dart';
import '../../domain/models/invoice.dart';
import '../../services/pdf_service.dart'; // Added for InvoiceTemplate and PdfService
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

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
      return AppScaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: const AppAppBar(title: Text('No Invoice')),
        body: const Center(child: Text('No invoice to preview')),
      );
    }

    return AppScaffold(
      withTealHeader: true,
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppAppBar(
        title: const Text('Invoice Preview',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.r12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<InvoiceTemplate>(
                value: _selectedTemplate,
                dropdownColor: AppTheme.primaryColor,
                iconEnabledColor: Colors.white,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
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
            ),
          ),
        ],
      ),
      body: Container(
        margin: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          child: PdfPreview(
            build: (format) {
              return PdfService.generateInvoicePdf(
                invoice,
                template: _selectedTemplate,
                settings: settingsAsync.asData?.value,
              );
            },
            onError: (context, error) {
              return Center(child: Text('Error: $error'));
            },
            allowSharing: true,
            allowPrinting: true,
            canChangePageFormat: false,
            onShared: (context) => _handleSave(invoice),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'invoice_preview_fab',
        onPressed: () => _handleSave(invoice),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        label: const Text('Save & Finish',
            style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.check_circle_rounded),
      ),
    );
  }

  Future<void> _handleSave(Invoice invoice) async {
    await ref.read(invoicesProvider.notifier).saveInvoice(invoice);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invoice saved successfully!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
