import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/cash_book_provider.dart';
import '../../domain/models/cash_book_entry.dart';
import '../../domain/models/cash_account.dart';
import '../widgets/add_cash_entry_sheet.dart';
import '../widgets/add_cash_account_sheet.dart';
import '../../../sharing/presentation/pages/sharing_overview_page.dart';
import '../../../data_management/services/csv_service.dart';
import 'package:budget_tracking_app/features/my_account/presentation/providers/profile_provider.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';
import 'package:budget_tracking_app/core/utils/currency_formatter.dart';

class CashBookPage extends ConsumerWidget {
  const CashBookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(cashBookFilterProvider);
    final activeAccountId = ref.watch(activeCashAccountIdProvider);
    final accountsAsync = ref.watch(cashAccountsProvider);
    final entriesAsync = ref.watch(cashBookProvider);
    final balance = ref.watch(cashBalanceProvider);
    final profile = ref.watch(profileProvider);

    // Compute inflow/outflow summaries for the hero bar
    double totalInflow = 0;
    double totalOutflow = 0;
    entriesAsync.whenData((entries) {
      for (final e in entries) {
        if (e.type == CashBookEntryType.inflow) {
          totalInflow += e.amount;
        } else {
          totalOutflow += e.amount;
        }
      }
    });

    return AppScaffold(
      withTealHeader: true,
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppAppBar(
        title: const Text('Cash Ledger',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const SharingOverviewPage()),
            ),
            tooltip: 'Team Collaboration',
          ),
          IconButton(
            icon: const Icon(Icons.upload_rounded),
            onPressed: () => entriesAsync
                .whenData((entries) => _exportToCsv(context, entries)),
            tooltip: 'Export CSV',
          ),
          AppSpacing.gapXs,
        ],
      ),
      heroContent: Padding(
        padding: AppSpacing.listItemPadding,
        child: Column(
          children: [
            Row(
              children: [
                // Inflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.call_made_rounded,
                              size: 14, color: Colors.white.withOpacity(0.9)),
                          AppSpacing.gapXs,
                          Text('Inflow',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      AppSpacing.gapXs,
                      Text(
                        CurrencyFormatter.format(totalInflow, profile.currency),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                    width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                AppSpacing.gapLg,
                // Outflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.call_received_rounded,
                              size: 14, color: Colors.white.withOpacity(0.9)),
                          AppSpacing.gapXs,
                          Text('Outflow',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      AppSpacing.gapXs,
                      Text(
                        CurrencyFormatter.format(totalOutflow, profile.currency),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
          ],
        ),
      ),
      body: Column(
        children: [
          // Balance card
          _buildBalanceCard(context, balance, accountsAsync, activeAccountId,
              profile.currency),
          // Account switcher + add
          _buildAccountSwitcher(context, ref, accountsAsync, activeAccountId),
          // Filter chips
          _buildFilterChips(context, ref, activeFilter),
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                final filtered = _applyFilter(entries, activeFilter);
                if (filtered.isEmpty) return _buildEmptyState(context);
                return _buildLedgerView(filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorState(e.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'cash_book_fab',
        onPressed: () => _showAddEntry(context),
        label: const Text('Add Entry',
            style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context,
      double balance,
      AsyncValue<List<CashAccount>> accountsAsync,
      String? activeId,
      String currency) {
    String accountName = 'Total Balance';
    accountsAsync.whenData((accounts) {
      if (accounts.isNotEmpty) {
        final account = accounts.firstWhere((a) => a.id == activeId,
            orElse: () => accounts.first);
        accountName = account.name;
      }
    });

    final isPositive = balance >= 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.r24),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: AppTheme.primaryColor, size: 22),
          ),
          AppSpacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Text(
                  'Running Balance',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(balance, currency),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isPositive ? AppTheme.primaryColor : AppTheme.dangerColor,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.05, end: 0);
  }

  Widget _buildAccountSwitcher(BuildContext context, WidgetRef ref,
      AsyncValue<List<CashAccount>> accountsAsync, String? activeId) {
    return accountsAsync.when(
      data: (accounts) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Row(
          children: accounts.map((account) {
            final isSelected = account.id == activeId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(
                  account.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                onPressed: () => ref
                    .read(activeCashAccountIdProvider.notifier)
                    .state = account.id,
                backgroundColor: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withOpacity(0.08),
                side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withOpacity(0.2)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r24)),
              ),
            );
          }).toList()
            ..add(
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: const Icon(Icons.add_rounded,
                      size: 18, color: AppTheme.primaryColor),
                  onPressed: () => _showAddAccount(context),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
                  side:
                      BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r24)),
                ),
              ),
            ),
        ),
      ),
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildFilterChips(
      BuildContext context, WidgetRef ref, CashBookFilter active) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: CashBookFilter.values.map((filter) {
          final isSelected = active == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(
                filter.name[0].toUpperCase() + filter.name.substring(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
              selected: isSelected,
              onSelected: (_) =>
                  ref.read(cashBookFilterProvider.notifier).state = filter,
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.white,
              side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.withOpacity(0.2)),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r24)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              child: const Icon(Icons.library_books_rounded,
                  size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'No entries found',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            AppSpacing.gapSm,
            const Text(
              'Tap + Add Entry to get started',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 60, color: AppTheme.dangerColor),
            AppSpacing.gapLg,
            const Text(
              'Failed to load entries',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dangerColor),
            ),
            AppSpacing.gapSm,
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  List<CashBookEntry> _applyFilter(
      List<CashBookEntry> entries, CashBookFilter filter) {
    switch (filter) {
      case CashBookFilter.all:
        return entries;
      case CashBookFilter.inflow:
        return entries
            .where((e) => e.type == CashBookEntryType.inflow)
            .toList();
      case CashBookFilter.outflow:
        return entries
            .where((e) => e.type == CashBookEntryType.outflow)
            .toList();
    }
  }

  Widget _buildLedgerView(List<CashBookEntry> entries) {
    final Map<DateTime, List<CashBookEntry>> grouped = {};
    for (var entry in entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      grouped.putIfAbsent(date, () => []).add(entry);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayEntries = grouped[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    DateFormat('EEEE, MMM d').format(date).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            ...dayEntries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EntryTile(entry: e),
                )),
          ],
        );
      },
    );
  }

  Future<void> _exportToCsv(
      BuildContext context, List<CashBookEntry> entries) async {
    final List<List<dynamic>> rows = [
      ['Date', 'Description', 'Category', 'Type', 'Amount']
    ];
    for (var entry in entries) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(entry.date),
        entry.description,
        entry.category,
        entry.type.name,
        entry.amount,
      ]);
    }
    await CsvService.exportAndShareCsv(
      filename: 'CashLedger_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      rows: rows,
    );
  }

  void _showAddEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCashEntrySheet(),
    );
  }

  void _showAddAccount(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCashAccountSheet(),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  final CashBookEntry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(profileProvider).currency;
    final isInflow = entry.type == CashBookEntryType.inflow;
    final amountColor = isInflow ? AppTheme.successColor : AppTheme.dangerColor;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.dangerColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_sweep_rounded,
            color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        ref.read(cashBookProvider.notifier).deleteEntry(entry.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isInflow
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          title: Text(
            entry.description,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textPrimary),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${entry.category} · ${DateFormat('h:mm a').format(entry.date)}',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isInflow ? '+' : '-'}${CurrencyFormatter.format(entry.amount, currency)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: amountColor,
                ),
              ),
              Text(
                isInflow ? 'Inflow' : 'Outflow',
                style: TextStyle(
                    fontSize: 10,
                    color: amountColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }
}
