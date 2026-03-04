import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:budget_tracking_app/features/my_account/presentation/providers/profile_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/account_provider.dart';
import '../widgets/add_account_sheet.dart';
import '../pages/account_details_page.dart';
import '../../data/models/account.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';
import 'package:budget_tracking_app/core/utils/currency_formatter.dart';

class AccountsOverviewPage extends ConsumerWidget {
  const AccountsOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final profile = ref.watch(profileProvider);

    return AppScaffold(
      withTealHeader: true,
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppAppBar(
        title: Text('Expense Accounts',
            style: TextStyle(
                color: AppTheme.getSurfaceColor(context),
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return _buildEmptyState(context);
          }
          final expensesAsync = ref.watch(expensesProvider);
          final allExpenses = expensesAsync.value ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(accountsProvider.notifier).loadAccounts();
              await ref.read(expensesProvider.notifier).loadExpenses();
            },
            child: ListView.builder(
              padding: AppSpacing.cardPadding,
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                final accountExpenses = allExpenses
                    .where((e) => e.linkedAccount == account.id)
                    .toList();
                final totalSpent = accountExpenses.fold<double>(
                    0.0, (sum, e) => sum + e.amount);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildAccountCard(
                      context, account, totalSpent, ref, profile.currency),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'accounts_fab',
        onPressed: () => _showAddAccountSheet(context),
        label: const Text('New Account',
            style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account,
      double totalSpent, WidgetRef ref, String currency) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(AppSpacing.r24),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.r24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AccountDetailsPage(account: account)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.r16),
                  border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.15)),
                ),
                child: Icon(account.type.icon,
                    color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 4),
                    Text(
                      account.type.label,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getTextColor(context, opacity: 0.6),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(totalSpent, currency),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                      letterSpacing: -1,
                    ),
                  )
                      .animate(key: ValueKey(totalSpent))
                      .shimmer(duration: 800.ms),
                  SizedBox(height: 4),
                  Text(
                    'TOTAL SPENT',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context, opacity: 0.4)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_rounded,
              size: 100, color: AppTheme.primaryColor.withOpacity(0.5)),
          SizedBox(height: 24),
          Text(
            'No accounts detected',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context, opacity: 0.4)),
          ),
          AppSpacing.gapXxl,
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r16)),
            ),
            onPressed: () => _showAddAccountSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Account',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  void _showAddAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddAccountSheet(),
    );
  }
}
