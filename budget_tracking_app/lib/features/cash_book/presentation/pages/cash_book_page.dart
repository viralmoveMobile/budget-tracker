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

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('Cash Ledger',
            style: TextStyle(
                color: AppTheme.getSurfaceColor(context),
                fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cashBookColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.people_alt_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const SharingOverviewPage()),
            ),
            tooltip: 'Team Collaboration',
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => entriesAsync
                .whenData((entries) => _exportToCsv(context, entries)),
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAccountSwitcher(context, ref, accountsAsync, activeAccountId),
          _buildBalanceCard(context, balance, accountsAsync, activeAccountId,
              profile.currency),
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

  Widget _buildAccountSwitcher(BuildContext context, WidgetRef ref,
      AsyncValue<List<CashAccount>> accountsAsync, String? activeId) {
    return accountsAsync.when(
      data: (accounts) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: accounts.map((account) {
            final isSelected = account.id == activeId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(
                  account.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.cashBookColor,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onPressed: () => ref
                    .read(activeCashAccountIdProvider.notifier)
                    .state = account.id,
                backgroundColor: isSelected
                    ? AppTheme.cashBookColor
                    : AppTheme.cashBookColor.withOpacity(0.1),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            );
          }).toList()
            ..add(
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: const Icon(Icons.add_rounded,
                      size: 20, color: AppTheme.cashBookColor),
                  onPressed: () => _showAddAccount(context),
                  backgroundColor: AppTheme.cashBookColor.withOpacity(0.05),
                  side: BorderSide(
                      color: AppTheme.cashBookColor.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
        ),
      ),
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
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

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.cashBookColor,
            AppTheme.cashBookColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cashBookColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.white70),
                ),
                const Text(
                  'Running Balance',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white38),
                ),
              ],
            ),
          ),
          Text(
            NumberFormat.simpleCurrency(name: currency, decimalDigits: 0)
                .format(balance),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.getSurfaceColor(context),
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildFilterChips(
      BuildContext context, WidgetRef ref, CashBookFilter active) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: CashBookFilter.values.map((filter) {
          final isSelected = active == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(
                filter.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black45,
                ),
              ),
              selected: isSelected,
              onSelected: (_) =>
                  ref.read(cashBookFilterProvider.notifier).state = filter,
              selectedColor: AppTheme.primaryColor,
              backgroundColor: AppTheme.getDividerColor(context),
              side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : Colors.black12),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_rounded,
              size: 100, color: AppTheme.getTextColor(context, opacity: 0.15)),
          SizedBox(height: 24),
          Text(
            'No entries found',
            style: TextStyle(
              color: AppTheme.getTextColor(context, opacity: 0.4),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: AppTheme.dangerColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load entries',
              style: AppTheme.h3Style.copyWith(color: AppTheme.dangerColor),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTheme.captionStyle,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayEntries = grouped[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(4, 16, 4, 12),
              child: Text(
                DateFormat('EEEE, MMM d').format(date).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.getTextColor(context, opacity: 0.5),
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
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
    final color = isInflow ? AppTheme.successColor : AppTheme.dangerColor;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.dangerColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_sweep_rounded,
            color: AppTheme.getSurfaceColor(context), size: 28),
      ),
      onDismissed: (_) {
        ref.read(cashBookProvider.notifier).deleteEntry(entry.id);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.getDividerColor(context),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(
              isInflow
                  ? Icons.add_circle_outline_rounded
                  : Icons.remove_circle_outline_rounded,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            entry.description,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.getTextColor(context)),
          ),
          subtitle: Text(
            entry.category,
            style: TextStyle(
                color: AppTheme.getTextColor(context, opacity: 0.6),
                fontSize: 12),
          ),
          trailing: Text(
            '${isInflow ? '+' : '-'}${NumberFormat.simpleCurrency(name: currency, decimalDigits: 0).format(entry.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }
}
