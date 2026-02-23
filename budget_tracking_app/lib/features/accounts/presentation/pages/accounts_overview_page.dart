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

class AccountsOverviewPage extends ConsumerWidget {
  const AccountsOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppTheme.accountsColor,
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
              padding: const EdgeInsets.all(20),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accountsColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
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
                  color: account.type.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: account.type.color.withOpacity(0.2)),
                ),
                child: Icon(account.type.icon,
                    color: account.type.color, size: 24),
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
                    NumberFormat.simpleCurrency(
                            name: currency, decimalDigits: 0)
                        .format(totalSpent),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accountsColor,
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
              size: 100, color: AppTheme.getTextColor(context, opacity: 0.15)),
          SizedBox(height: 24),
          Text(
            'No accounts detected',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context, opacity: 0.4)),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
