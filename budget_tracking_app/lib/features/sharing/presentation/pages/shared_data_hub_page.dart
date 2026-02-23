import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/expense_sync_provider.dart';
import '../providers/cash_book_sync_provider.dart';
import '../providers/budget_sync_provider.dart';
import '../providers/firestore_sharing_provider.dart';
import 'member_detail_page.dart';

class SharedDataHubPage extends ConsumerWidget {
  const SharedDataHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedExpensesAsync = ref.watch(sharedExpensesProvider);
    final sharedCashBookAsync = ref.watch(sharedCashBookEntriesProvider);
    final sharedBudgetsAsync = ref.watch(sharedBudgetsProvider);
    final relationshipsAsync = ref.watch(usersSharedWithMeProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Shared Data', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sharedExpensesProvider);
          ref.invalidate(sharedCashBookEntriesProvider);
          ref.invalidate(sharedBudgetsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Summary Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dashboard_rounded,
                            color: AppTheme.getSurfaceColor(context), size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Summary',
                          style: TextStyle(
                            color: AppTheme.getSurfaceColor(context),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildSummaryRow(
                      context,
                      'Expenses',
                      sharedExpensesAsync.value?.length ?? 0,
                      Icons.receipt_long_rounded,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      context,
                      'Transactions',
                      sharedCashBookAsync.value?.length ?? 0,
                      Icons.book_rounded,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      context,
                      'Budgets',
                      sharedBudgetsAsync.value?.length ?? 0,
                      Icons.savings_rounded,
                    ),
                    const Divider(
                        height: 24, color: Colors.white38, thickness: 1),
                    _buildSummaryRow(
                      context,
                      'Sharing Partners',
                      relationshipsAsync.value?.length ?? 0,
                      Icons.people_rounded,
                    ),
                  ],
                ),
              ),
            ),

            // Sharing Partners Section
            relationshipsAsync.when(
              data: (relationships) {
                if (relationships.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline_rounded,
                              size: 80,
                              color: AppTheme.getTextColor(context,
                                  isSecondary: true, opacity: 0.5)),
                          SizedBox(height: 16),
                          Text(
                            'No sharing partners yet',
                            style: TextStyle(
                                color: AppTheme.getTextColor(context,
                                    isSecondary: true),
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Invite others to start sharing data',
                            style: TextStyle(
                                color: AppTheme.getTextColor(context,
                                    isSecondary: true, opacity: 0.9)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final relationship = relationships[index];
                      return _buildPartnerCard(
                        context,
                        ref,
                        relationship.ownerEmail,
                        relationship.ownerId,
                        relationship.dataTypes,
                      );
                    },
                    childCount: relationships.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      BuildContext context, String label, int count, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: AppTheme.getSurfaceColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerCard(
    BuildContext context,
    WidgetRef ref,
    String email,
    String userId,
    List<String> dataTypes,
  ) {
    final sharedExpenses = ref.watch(sharedExpensesByUserProvider(userId));
    final sharedCashBook =
        ref.watch(sharedCashBookEntriesByUserProvider(userId));
    final sharedBudgets = ref.watch(sharedBudgetsByUserProvider(userId));

    final expenseCount = sharedExpenses.value?.length ?? 0;
    final cashBookCount = sharedCashBook.value?.length ?? 0;
    final budgetCount = sharedBudgets.value?.length ?? 0;

    final name = email.split('@').first;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MemberDetailPage(
                  memberName: name,
                  memberEmail: email,
                  memberId: userId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        name[0].toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              color: AppTheme.getTextColor(context,
                                  isSecondary: true),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color:
                            AppTheme.getTextColor(context, isSecondary: true)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDataTypeChip(
                      context,
                      'Expenses',
                      expenseCount,
                      Icons.receipt_long_rounded,
                      AppTheme.expensesColor,
                    ),
                    _buildDataTypeChip(
                      context,
                      'Cash Book',
                      cashBookCount,
                      Icons.book_rounded,
                      AppTheme.accountsColor,
                    ),
                    _buildDataTypeChip(
                      context,
                      'Budgets',
                      budgetCount,
                      Icons.savings_rounded,
                      AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTypeChip(BuildContext context, String label, int count,
      IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.getTextColor(context, isSecondary: true),
          ),
        ),
      ],
    );
  }

  void _showPartnerDetails(
    BuildContext context,
    WidgetRef ref,
    String name,
    String email,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.getTextColor(context,
                        isSecondary: true, opacity: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            color: AppTheme.getTextColor(context,
                                isSecondary: true),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Shared Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailSection(
                      ref,
                      context,
                      'Expenses',
                      Icons.receipt_long_rounded,
                      AppTheme.expensesColor,
                      ref.watch(sharedExpensesByUserProvider(userId)),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      ref,
                      context,
                      'Cash Book',
                      Icons.book_rounded,
                      AppTheme.accountsColor,
                      ref.watch(sharedCashBookEntriesByUserProvider(userId)),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      ref,
                      context,
                      'Budgets',
                      Icons.savings_rounded,
                      AppTheme.primaryColor,
                      ref.watch(sharedBudgetsByUserProvider(userId)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    WidgetRef ref,
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    AsyncValue<List<dynamic>> dataAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        dataAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No $title shared',
                  style: TextStyle(
                      color: AppTheme.getTextColor(context,
                          isSecondary: true, opacity: 0.9)),
                ),
              );
            }
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                '${items.length} $title',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => Text(
            'Error loading $title',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
