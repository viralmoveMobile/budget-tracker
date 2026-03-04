import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/invoice_provider.dart';
import '../../domain/models/invoice.dart';
import 'create_invoice_page.dart';
import 'invoice_settings_page.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class InvoiceListPage extends ConsumerWidget {
  const InvoiceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return AppScaffold(
      withTealHeader: true,
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppAppBar(
        title: const Text('Invoices',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const InvoiceSettingsPage()),
            ),
          ),
          AppSpacing.gapXs,
        ],
      ),
      heroContent: invoicesAsync.whenOrNull(
        data: (invoices) {
          final totalGenerated =
              invoices.fold<double>(0, (sum, inv) => sum + inv.total);
          final pendingInvoices =
              invoices.where((i) => i.status != InvoiceStatus.paid);
          final totalPending =
              pendingInvoices.fold<double>(0, (sum, inv) => sum + inv.total);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeroStat(
                      '\$${totalGenerated.toStringAsFixed(0)}',
                      'Total Generated',
                      Icons.receipt_long_rounded,
                    ),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3)),
                    _buildHeroStat(
                      '\$${totalPending.toStringAsFixed(0)}',
                      'Pending Payment',
                      Icons.pending_actions_rounded,
                    ),
                  ],
                ),
                AppSpacing.gapSm,
              ],
            ),
          ).animate().fadeIn();
        },
      ),
      body: invoicesAsync.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.description_rounded,
                          size: 40, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 20),
                    const Text('No invoices issued yet',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text(
                        'Create your first professional invoice\nto send to a client.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    AppSpacing.gapXxl,
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.r16)),
                      ),
                      onPressed: () => _createNew(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Invoice',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ).animate().fadeIn(),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: invoices.length,
            separatorBuilder: (context, index) => AppSpacing.gapLg,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return _InvoiceCard(invoice: invoice);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: invoicesAsync.whenOrNull(
        data: (invoices) => invoices.isNotEmpty
            ? FloatingActionButton.extended(
                heroTag: 'invoice_list_fab',
                onPressed: () => _createNew(context),
                label: const Text('New Invoice',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                icon: const Icon(Icons.add_rounded),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
              ).animate().scale(delay: 400.ms)
            : null,
      ),
    );
  }

  Widget _buildHeroStat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
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
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = invoice.status == InvoiceStatus.paid;
    final isOverdue = invoice.status != InvoiceStatus.paid &&
        DateTime.now().isAfter(invoice.dueDate);

    Color statusColor;
    IconData statusIcon;

    if (isPaid) {
      statusColor = AppTheme.successColor;
      statusIcon = Icons.check_circle_rounded;
    } else if (isOverdue) {
      statusColor = AppTheme.dangerColor;
      statusIcon = Icons.error_rounded;
    } else {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.pending_actions_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
          padding: AppSpacing.cardPadding,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              invoice.clientName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '\$${invoice.total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapXs,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              invoice.invoiceNumber,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isOverdue && !isPaid
                                    ? 'OVERDUE'
                                    : invoice.status.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip(
                      label: 'Issued',
                      value:
                          DateFormat('dd MMM yyyy').format(invoice.issueDate),
                      icon: Icons.calendar_today_rounded),
                  _InfoChip(
                      label: 'Due',
                      value: DateFormat('dd MMM yyyy').format(invoice.dueDate),
                      isDue: isOverdue && !isPaid,
                      icon: Icons.event_busy_rounded),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isPaid
                                ? Icons.undo_rounded
                                : Icons.check_circle_outline_rounded,
                            color: isPaid
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                            size: 18,
                          ),
                          onPressed: () => ref
                              .read(invoicesProvider.notifier)
                              .toggleStatus(invoice),
                          tooltip: isPaid ? 'Mark Unpaid' : 'Mark Paid',
                        ),
                      ),
                      AppSpacing.gapSm,
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.dangerColor.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppTheme.dangerColor, size: 18),
                          onPressed: () {
                            ref
                                .read(invoicesProvider.notifier)
                                .deleteInvoice(invoice.id);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.1, end: 0).fadeIn();
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isDue;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.value,
    this.isDue = false,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color: isDue ? AppTheme.dangerColor : AppTheme.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        isDue ? AppTheme.dangerColor : AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }
}
