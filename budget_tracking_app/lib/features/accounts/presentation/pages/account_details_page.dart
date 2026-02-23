import 'package:budget_tracking_app/core/theme/app_theme.dart';
import 'package:budget_tracking_app/features/my_account/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/account_provider.dart';
import '../../data/models/account.dart';
import '../../data/models/transaction.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';

class AccountDetailsPage extends ConsumerWidget {
  final Account account;

  const AccountDetailsPage({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync =
        ref.watch(accountTransactionsProvider(account.id));
    final currency = ref.watch(profileProvider).currency;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBalanceHeader(context),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                      child: Text('No transactions for this account'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return _buildTransactionItem(context, tx, currency);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHeader(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final expensesAsync = ref.watch(expensesProvider);
      final profile = ref.watch(profileProvider);
      final accountExpenses =
          expensesAsync.value?.where((e) => e.linkedAccount == account.id) ??
              [];

      final inAmount = accountExpenses
          .where((e) => e.isIncome)
          .fold(0.0, (sum, e) => sum + e.amount);
      final outAmount = accountExpenses
          .where((e) => !e.isIncome)
          .fold(0.0, (sum, e) => sum + e.amount);

      return Container(
        width: double.infinity,
        color: account.type.color.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat(context, 'Income', inAmount, Colors.green,
                    profile.currency),
                _buildStat(context, 'Expenses', outAmount, Colors.red,
                    profile.currency),
              ],
            ),
            const SizedBox(height: 16),
            Chip(
              avatar:
                  Icon(account.type.icon, size: 16, color: account.type.color),
              label: Text(account.type.label),
              backgroundColor: account.type.color.withOpacity(0.1),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStat(BuildContext context, String label, double amount,
      Color color, String currency) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: AppTheme.getTextColor(context, isSecondary: true),
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormat.simpleCurrency(name: currency, decimalDigits: 0)
              .format(amount),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
      BuildContext context, AccountTransaction tx, String currency) {
    final isTransfer = tx.type == TransactionType.transfer;
    final isNegative = tx.type == TransactionType.expense ||
        (isTransfer && tx.category == 'Transfer Out');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isTransfer
            ? Colors.blue.withOpacity(0.1)
            : (isNegative
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1)),
        child: Icon(
          isTransfer
              ? Icons.swap_horiz
              : (isNegative ? Icons.remove : Icons.add),
          color: isTransfer
              ? Colors.blue
              : (isNegative ? Colors.red : Colors.green),
        ),
      ),
      title: Text(tx.category),
      subtitle: Text(DateFormat('MMM dd, yyyy • HH:mm').format(tx.date)),
      trailing: Text(
        '${isNegative ? '-' : '+'}${NumberFormat.simpleCurrency(name: currency).format(tx.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isNegative ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Text(
            'This will permanently delete "${account.name}" and all its transaction history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(accountsProvider.notifier).deleteAccount(account.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close details page
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
