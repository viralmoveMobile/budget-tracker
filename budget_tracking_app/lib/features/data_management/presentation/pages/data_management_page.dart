import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/data_management_provider.dart';

class DataManagementPage extends ConsumerWidget {
  const DataManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dataManagementProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('Data & Tools',
            style: TextStyle(color: AppTheme.getSurfaceColor(context), fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildInfoCard(context),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Backup & Export'),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Export to Excel',
            subtitle: 'Professional multi-sheet workbook (.xlsx)',
            icon: Icons.table_view_rounded,
            color: AppTheme.successColor,
            onTap: () => notifier.exportToExcel(),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Backup to CSV',
            subtitle: 'Standard comma-separated files (.csv)',
            icon: Icons.backup_rounded,
            color: AppTheme.primaryColor,
            onTap: () => notifier.exportAllToCsv(),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Reports & Printing'),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Financial Summary',
            subtitle: 'Generate and print PDF report',
            icon: Icons.print_rounded,
            color: Colors.orange,
            onTap: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating report...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                await notifier.generateAndPrintPDFReport();
              } catch (e, stack) {
                if (context.mounted) {
                  // Debugging: Show first line of stack trace
                  final stackLine = stack.toString().split('\n').firstWhere(
                      (l) => l.contains('budget_tracking_app'),
                      orElse: () => 'Unknown location');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e\nLoc: $stackLine'),
                      backgroundColor: AppTheme.dangerColor,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Data Safety'),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Import Data',
            subtitle: 'Restore from CSV files',
            icon: Icons.restore_page_rounded,
            color: AppTheme.infoColor,
            onTap: () async {
              try {
                await notifier.pickAndImportCsv();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Import completed successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              }
            },
          ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
          const SizedBox(height: 48),
          _buildWarning(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.getTextColor(context, opacity: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined,
              color: AppTheme.primaryColor.withOpacity(0.8), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Your financial data is stored locally on this device. Create backups strictly for your own records.',
              style:
                  TextStyle(color: AppTheme.getTextColor(context, opacity: 0.6), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.getTextColor(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style:
                          TextStyle(color: AppTheme.getTextColor(context, opacity: 0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: AppTheme.getTextColor(context, opacity: 0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarning(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Colors.white10),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_rounded,
                size: 14, color: Colors.white.withOpacity(0.3)),
            const SizedBox(width: 8),
            Text(
              'Secure Local Storage • Offline First',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getTextColor(context, opacity: 0.4),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
