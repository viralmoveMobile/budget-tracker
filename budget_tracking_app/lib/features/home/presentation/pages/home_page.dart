import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/presentation/widgets/main_layout.dart';
import '../../../common/presentation/widgets/feature_card.dart';
import '../../../expenses/presentation/pages/expense_list_screen.dart';
import '../../../wages_calculator/presentation/pages/wages_calculator_page.dart';
import '../../../accounts/presentation/pages/accounts_overview_page.dart';
import '../../../exchange/presentation/pages/currency_converter_page.dart';
import '../../../holidays/presentation/pages/holiday_list_page.dart';
import '../../../cash_book/presentation/pages/cash_book_page.dart';
import '../../../sharing/presentation/pages/sharing_overview_page.dart';
import '../../../sharing/presentation/pages/shared_data_hub_page.dart';
import '../../../invoices/presentation/pages/invoice_list_page.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import 'package:budget_tracking_app/features/my_account/presentation/pages/profile_page.dart';
import '../../../../core/services/rating_service.dart';

import 'package:budget_tracking_app/features/my_account/presentation/providers/profile_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final profile = ref.watch(profileProvider);

    // Check and show rating dialog after data loads
    ref.listen(expensesProvider, (previous, next) {
      if (next.hasValue && context.mounted) {
        // Delay to avoid showing immediately
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            RatingService.instance.checkAndShowRating(context);
          }
        });
      }
    });

    // Calculate Total Expense
    final double totalExpense = expensesAsync.value
            ?.where((e) => !e.isIncome)
            .fold<double>(0.0, (sum, expense) => sum + expense.amount) ??
        0.0;

    return MainLayout(
      title: 'Dashboard',
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Text(
              DateFormat('EEEE, d MMMM').format(DateTime.now()).toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context, isSecondary: true),
                letterSpacing: 1.2,
              ),
            ).animate().fadeIn().slideX(begin: -0.1),
            SizedBox(height: 8),
            Text(
              'Financial Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
            SizedBox(height: 24),

            // Hero Total Expense Card
            // Hero Total Expense Card
            _buildHeroCard(context, totalExpense, expensesAsync.isLoading,
                profile.currency),
            const SizedBox(height: 24),

            const SizedBox(height: 40),

            // Tools / Features Section
            Row(
              children: [
                Icon(Icons.grid_view_rounded,
                    size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Tools & Features',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),

            _buildFeatureGrid(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, double netWorth, bool isLoading,
      String currencyCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 20),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'TOTAL EXPENSES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (isLoading)
            const SizedBox(
                height: 40,
                child: Center(
                    child: CircularProgressIndicator(color: Colors.white)))
          else
            Text(
              NumberFormat.simpleCurrency(name: currencyCode).format(netWorth),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ).animate().fadeIn().scale(),
          const SizedBox(height: 8),
          Text(
            'Your Complete Money Management Companion',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMonthlySummary(BuildContext context, double income,
      double expense, String currencyCode) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Income',
            amount: income,
            color: AppTheme.successColor,
            icon: Icons.arrow_downward_rounded,
            currencyCode: currencyCode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Expense',
            amount: expense,
            color: AppTheme.dangerColor,
            icon: Icons.arrow_upward_rounded,
            currencyCode: currencyCode,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        FeatureCard(
          title: 'Expenses',
          featureType: FeatureType.expenses,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ExpenseListPage())),
          child: Center(
              child: Icon(Icons.receipt_long_rounded,
                  size: 32, color: Theme.of(context).colorScheme.primary)),
        ),
        FeatureCard(
          title: 'Expense Accounts',
          featureType: FeatureType.accounts,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AccountsOverviewPage())),
          child: Center(
              child: Icon(Icons.account_balance_wallet_rounded,
                  size: 32, color: Theme.of(context).colorScheme.primary)),
        ),
        FeatureCard(
          title: 'Cash Book',
          featureType: FeatureType.cashBook,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CashBookPage())),
          child: Center(
              child: Icon(Icons.book_rounded,
                  size: 32, color: Theme.of(context).colorScheme.primary)),
        ),
        FeatureCard(
          title: 'Wages',
          featureType: FeatureType.wages,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WagesCalculatorPage())),
          child: Center(
              child: Icon(Icons.work_history_rounded,
                  size: 32, color: Theme.of(context).colorScheme.primary)),
        ),
        FeatureCard(
          title: 'Exchange',
          featureType: FeatureType.exchange,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CurrencyConverterPage())),
          child: Center(
              child: Icon(Icons.currency_exchange_rounded,
                  size: 32, color: Theme.of(context).colorScheme.primary)),
        ),
        FeatureCard(
          title: 'Invoices',
          featureType: FeatureType.invoices,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const InvoiceListPage())),
          child: Center(
              child: Icon(Icons.description_rounded,
                  size: 32, color: Theme.of(context).colorScheme.primary)),
        ),
        FeatureCard(
          title: 'Holidays',
          featureType: FeatureType.holiday,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HolidayListPage())),
          child: Center(
              child: Icon(Icons.flight_takeoff_rounded,
                  size: 32, color: Theme.of(context).colorScheme.primary)),
        ),
        FeatureCard(
          title: 'Sharing',
          featureType: FeatureType.sharing,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SharingOverviewPage())),
          child: Center(
              child: Icon(Icons.ios_share_rounded,
                  size: 32, color: Theme.of(context).colorScheme.primary)),
        ),
        FeatureCard(
          title: 'Shared Data',
          featureType: FeatureType.sharing,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SharedDataHubPage())),
          child: Center(
              child: Icon(Icons.folder_shared_rounded,
                  size: 32, color: Theme.of(context).colorScheme.primary)),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primaryColor),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet,
                      color: AppTheme.getSurfaceColor(context), size: 40),
                  const SizedBox(height: 10),
                  Text('Everyday Expenses',
                      style: AppTheme.h3Style.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('My Account'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(AppTheme.spaceMd),
            child: Text('Version 1.0.0', style: AppTheme.captionStyle),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final String currencyCode;

  const _SummaryCard(
      {required this.title,
      required this.amount,
      required this.color,
      required this.icon,
      required this.currencyCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.getTextColor(context, isSecondary: true),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            NumberFormat.compactSimpleCurrency(name: currencyCode)
                .format(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
