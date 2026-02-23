import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/invoice_provider.dart';
import '../../domain/models/invoice.dart';
import 'create_invoice_page.dart';
import 'invoice_settings_page.dart';

class InvoiceListPage extends ConsumerWidget {
  const InvoiceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('Invoices',
            style: TextStyle(color: AppTheme.getSurfaceColor(context), fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.invoiceColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const InvoiceSettingsPage()),
            ),
          ),
        ],
      ),
      body: invoicesAsync.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_rounded,
                      size: 100, color: AppTheme.getTextColor(context, opacity: 0.15)),
                  SizedBox(height: 24),
                  Text('No invoices issued yet',
                      style: TextStyle(
                          color: AppTheme.getTextColor(context, opacity: 0.4),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _createNew(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Invoice',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ).animate().fadeIn();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: invoices.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return _InvoiceCard(invoice: invoice);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'invoice_list_fab',
        onPressed: () => _createNew(context),
        label: const Text('New Invoice',
            style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ).animate().scale(delay: 400.ms),
    );
  }

  void _createNew(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateInvoicePage()),
    );
  }
}

class _InvoiceCard extends ConsumerWidget {
  final Invoice invoice;
  _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.invoiceColor.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          ref.read(currentInvoiceProvider.notifier).state = invoice;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInvoicePage(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: -0.5,
                            color: AppTheme.getTextColor(context)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        invoice.clientName,
                        style: TextStyle(
                            color: AppTheme.getTextColor(context, opacity: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    '\$${invoice.total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.invoiceColor,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: invoice.status == InvoiceStatus.paid
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.dangerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      invoice.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: invoice.status == InvoiceStatus.paid
                            ? AppTheme.successColor
                            : AppTheme.dangerColor,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppTheme.getBorderColor(context)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip(
                      label: 'Issued',
                      value: DateFormat('dd MMM').format(invoice.issueDate)),
                  _InfoChip(
                      label: 'Due',
                      value: DateFormat('dd MMM').format(invoice.dueDate),
                      isDue: DateTime.now().isAfter(invoice.dueDate)),
                  Container(
                    decoration: BoxDecoration(
                      color: (invoice.status == InvoiceStatus.paid
                              ? AppTheme.warningColor
                              : AppTheme.successColor)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        invoice.status == InvoiceStatus.paid
                            ? Icons.undo_rounded
                            : Icons.check_circle_outline_rounded,
                        color: invoice.status == InvoiceStatus.paid
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                        size: 20,
                      ),
                      onPressed: () => ref
                          .read(invoicesProvider.notifier)
                          .toggleStatus(invoice),
                      tooltip: invoice.status == InvoiceStatus.paid
                          ? 'Mark as Unpaid'
                          : 'Mark as Paid',
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.dangerColor, size: 20),
                      onPressed: () => ref
                          .read(invoicesProvider.notifier)
                          .deleteInvoice(invoice.id),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().slideX(begin: 0.05, end: 0).fadeIn();
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isDue;
  const _InfoChip(
      {required this.label, required this.value, this.isDue = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: AppTheme.getTextColor(context, opacity: 0.5),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDue ? AppTheme.dangerColor : Colors.black87)),
      ],
    );
  }
}
