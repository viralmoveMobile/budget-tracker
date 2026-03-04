import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import 'help_support_page.dart';
import 'privacy_policy_page.dart';
import '../../../../features/data_management/presentation/pages/data_management_page.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class SettingsOverviewPage extends ConsumerWidget {
  const SettingsOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppAppBar(
        title: Text('Settings',
            style: TextStyle(
                color: AppTheme.getSurfaceColor(context),
                fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildProfileHeader(context),
          AppSpacing.gapXxl,
          _buildSectionTitle(context, 'SUPPORT & SECURITY'),
          AppSpacing.gapMd,
          _buildSettingsCard(context, [
            _buildSettingsItem(
              context,
              title: 'Help & Support',
              subtitle: 'FAQs, Tutorials & User Guides',
              icon: Icons.help_center_rounded,
              color: Colors.blue,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HelpSupportPage())),
            ),
            _buildDivider(),
            _buildSettingsItem(
              context,
              title: 'Privacy Policy',
              subtitle: 'Data Use & Security Measures',
              icon: Icons.security_rounded,
              color: Colors.teal,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage())),
            ),
          ]),
          AppSpacing.gapXxl,
          _buildSectionTitle(context, 'DATA MANAGEMENT'),
          AppSpacing.gapMd,
          _buildSettingsCard(context, [
            _buildSettingsItem(
              context,
              title: 'Backup & Restore',
              subtitle: 'Export data or Secure Cloud Sync',
              icon: Icons.cloud_sync_rounded,
              color: AppTheme.primaryColor,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DataManagementPage())),
            ),
          ]),
          AppSpacing.gapXxl,
          _buildSectionTitle(context, 'MASTER COMMUNITY'),
          AppSpacing.gapMd,
          _buildSettingsCard(context, [
            _buildSettingsItem(
              context,
              title: 'Rate & Recommend',
              subtitle: 'Feedback & Share with friends',
              icon: Icons.star_rounded,
              color: Colors.orange,
              onTap: () {
                Share.share(
                  'Master your finances with Master Budget Tracking! Download today to track expenses, manage pots, and send professional invoices.',
                );
              },
            ),
          ]),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Text('Master Budget Tracking',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context, opacity: 0.3))),
                Text('Version 1.0.0 (Stable)',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextColor(context, opacity: 0.15))),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(AppSpacing.r24),
        boxShadow: [
          BoxShadow(
              color: AppTheme.getDividerColor(context),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Icon(Icons.person_rounded,
                color: AppTheme.primaryColor, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account Settings',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Manage your profile & preferences',
                    style: TextStyle(
                        color: AppTheme.getTextColor(context, opacity: 0.6),
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
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

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(AppSpacing.r24),
        boxShadow: [
          BoxShadow(
              color: AppTheme.getDividerColor(context),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: AppSpacing.listItemPadding,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.r12)),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle,
          style: TextStyle(
              color: AppTheme.getTextColor(context, opacity: 0.6),
              fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppTheme.getTextColor(context, opacity: 0.3)),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1, indent: 64, endIndent: 20, color: Color(0xFFF5F5F7));
  }
}
