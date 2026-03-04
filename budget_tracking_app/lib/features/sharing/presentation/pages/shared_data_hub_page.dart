import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/expense_sync_provider.dart';
import '../providers/cash_book_sync_provider.dart';
import '../providers/budget_sync_provider.dart';
import '../providers/firestore_sharing_provider.dart';
import 'member_detail_page.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class SharedDataHubPage extends ConsumerWidget {
  const SharedDataHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedExpensesAsync = ref.watch(sharedExpensesProvider);
    final sharedCashBookAsync = ref.watch(sharedCashBookEntriesProvider);
    final sharedBudgetsAsync = ref.watch(sharedBudgetsProvider);
    final relationshipsAsync = ref.watch(usersSharedWithMeProvider);

    return AppScaffold(
      withTealHeader: true,
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppAppBar(
        title: const Text('Shared Data',
            style: TextStyle(fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      heroContent: Padding(
        padding: AppSpacing.listItemPadding,
        child: Row(
          children: [
            _buildHeroStat(
              context,
              sharedExpensesAsync.value?.length ?? 0,
              'Expenses',
              Icons.receipt_long_rounded,
            ),
            Container(
                width: 1, height: 36, color: Colors.white.withOpacity(0.3)),
            _buildHeroStat(
              context,
              sharedCashBookAsync.value?.length ?? 0,
              'Cash Book',
              Icons.book_rounded,
            ),
            Container(
                width: 1, height: 36, color: Colors.white.withOpacity(0.3)),
            _buildHeroStat(
              context,
              sharedBudgetsAsync.value?.length ?? 0,
              'Budgets',
              Icons.savings_rounded,
            ),
            Container(
                width: 1, height: 36, color: Colors.white.withOpacity(0.3)),
            _buildHeroStat(
              context,
              relationshipsAsync.value?.length ?? 0,
              'Partners',
              Icons.people_rounded,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sharedExpensesProvider);
          ref.invalidate(sharedCashBookEntriesProvider);
          ref.invalidate(sharedBudgetsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Sharing Partners',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
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
                              child: const Icon(Icons.people_outline_rounded,
                                  size: 40, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No sharing partners yet',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary),
                            ),
                            AppSpacing.gapSm,
                            Text(
                              'Invite others to start sharing data',
                              style: TextStyle(
                                  color: AppTheme.getTextColor(context,
                                      isSecondary: true)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
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

  Widget _buildHeroStat(
      BuildContext context, int count, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
              AppSpacing.gapXs,
              Text(
                label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          AppSpacing.gapXs,
          Text(
            '$count',
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Partner header row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              color: AppTheme.getTextColor(context,
                                  isSecondary: true),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary),
                  ],
                ),
                const Divider(height: 20),
                // Data type stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDataStat(context, 'Expenses', expenseCount,
                        Icons.receipt_long_rounded),
                    _buildDataStat(context, 'Cash Book', cashBookCount,
                        Icons.book_rounded),
                    _buildDataStat(
                        context, 'Budgets', budgetCount, Icons.savings_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataStat(
      BuildContext context, String label, int count, IconData icon) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.getTextColor(context, isSecondary: true),
          ),
        ),
      ],
    );
  }
}
