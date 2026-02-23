import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../features/expenses/presentation/pages/expense_list_screen.dart';
import '../../../features/wages_calculator/presentation/pages/wages_calculator_page.dart';
import '../../../features/accounts/presentation/pages/accounts_overview_page.dart';
import '../../../features/analytics/presentation/pages/analytics_dashboard_page.dart';
import '../../../features/exchange/presentation/pages/currency_converter_page.dart';
import '../../../features/holidays/presentation/pages/holiday_list_page.dart';
import '../../../features/cash_book/presentation/pages/cash_book_page.dart';
import '../../../features/sharing/presentation/pages/sharing_overview_page.dart';
import '../../../features/sharing/presentation/pages/shared_data_hub_page.dart';
import '../../../features/invoices/presentation/pages/invoice_list_page.dart';
import '../../../features/settings/presentation/pages/settings_overview_page.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/my_account/presentation/pages/profile_page.dart';

class SidebarMenu extends ConsumerWidget {
  const SidebarMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppTheme.surfaceLight,
      surfaceTintColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spaceMd,
                horizontal: AppTheme.spaceMd,
              ),
              children: [
                _buildMenuItem(
                  context,
                  'Dashboard',
                  Icons.dashboard_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  context,
                  'My Account',
                  Icons.person_outline_rounded,
                  onTap: () => _navigateTo(context, const ProfilePage()),
                ),
                const SizedBox(height: AppTheme.spaceXs),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppTheme.spaceSm,
                    horizontal: AppTheme.spaceMd,
                  ),
                  child: Divider(height: 1, color: AppTheme.borderLight),
                ),
                const SizedBox(height: AppTheme.spaceXs),
                _buildMenuItem(
                  context,
                  'Expenses',
                  Icons.receipt_long_rounded,
                  onTap: () => _navigateTo(context, const ExpenseListPage()),
                ),
                _buildMenuItem(
                  context,
                  'Wages',
                  Icons.work_history_rounded,
                  onTap: () =>
                      _navigateTo(context, const WagesCalculatorPage()),
                ),
                _buildMenuItem(
                  context,
                  'Accounts',
                  Icons.account_balance_wallet_rounded,
                  onTap: () =>
                      _navigateTo(context, const AccountsOverviewPage()),
                ),
                _buildMenuItem(
                  context,
                  'Analytics',
                  Icons.analytics_rounded,
                  onTap: () =>
                      _navigateTo(context, const AnalyticsDashboardPage()),
                ),
                _buildMenuItem(
                  context,
                  'Exchange',
                  Icons.currency_exchange_rounded,
                  onTap: () =>
                      _navigateTo(context, const CurrencyConverterPage()),
                ),
                _buildMenuItem(
                  context,
                  'Holidays',
                  Icons.flight_takeoff_rounded,
                  onTap: () => _navigateTo(context, const HolidayListPage()),
                ),
                _buildMenuItem(
                  context,
                  'Cash Ledger',
                  Icons.book_rounded,
                  onTap: () => _navigateTo(context, const CashBookPage()),
                ),
                _buildMenuItem(
                  context,
                  'Invoices',
                  Icons.description_rounded,
                  onTap: () => _navigateTo(context, const InvoiceListPage()),
                ),
                _buildMenuItem(
                  context,
                  'Manage Sharing',
                  Icons.person_add_rounded,
                  onTap: () =>
                      _navigateTo(context, const SharingOverviewPage()),
                ),
                _buildMenuItem(
                  context,
                  'Shared Data Hub',
                  Icons.folder_shared_rounded,
                  onTap: () => _navigateTo(context, const SharedDataHubPage()),
                ),
                const SizedBox(height: AppTheme.spaceXs),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppTheme.spaceSm,
                    horizontal: AppTheme.spaceMd,
                  ),
                  child: Divider(height: 1, color: AppTheme.borderLight),
                ),
                const SizedBox(height: AppTheme.spaceXs),
                _buildMenuItem(
                  context,
                  'Settings',
                  Icons.settings_rounded,
                  onTap: () =>
                      _navigateTo(context, const SettingsOverviewPage()),
                ),
              ],
            ),
          ),
          _buildDrawerFooter(context, ref),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authStateProvider);
        final user = authState.value;

        // Get user display name or email
        final displayName =
            user?.displayName ?? user?.email?.split('@').first ?? 'User';
        final userEmail = user?.email ?? '';

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 32,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (userEmail.isNotEmpty && user?.displayName != null)
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            Navigator.pop(context); // Close Drawer
            await ref.read(authControllerProvider.notifier).signOut();
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMd,
              vertical: AppTheme.spaceSm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: AppTheme.dangerColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Text(
                  'Log Out',
                  style: TextStyle(
                    color: AppTheme.dangerColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
