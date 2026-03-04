import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/budget_limit.dart';
import '../../data/models/expense_category.dart';
import '../providers/budget_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class BudgetSettingsPage extends ConsumerWidget {
  const BudgetSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitsAsync = ref.watch(budgetLimitsProvider);

    return AppScaffold(
      withTealHeader: true,
      backgroundColor: AppTheme.backgroundLight,
      appBar: const AppAppBar(
        title: Text('Budget Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      heroContent: Padding(
        padding: AppSpacing.listItemPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set spending limits to stay on track.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      body: limitsAsync.when(
        data: (limits) {
          final now = DateTime.now();
          final totalLimit =
              limits.where((l) => l.category == null).firstOrNull;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // Overall Budget Card
              _SectionHeader(title: 'Overall Budget'),
              const SizedBox(height: 10),
              _BudgetCard(
                icon: Icons.savings_rounded,
                iconColor: AppTheme.primaryColor,
                title: 'Total Monthly Budget',
                subtitle: totalLimit != null
                    ? 'Limit set: \$${totalLimit.amount.toStringAsFixed(0)}'
                    : 'No overall limit set',
                isSet: totalLimit != null,
                onEdit: () =>
                    _showEditDialog(context, ref, totalLimit, null, now),
              ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05, end: 0),

              AppSpacing.gapXl,
              _SectionHeader(title: 'Category Limits'),
              const SizedBox(height: 10),

              // Category cards
              ...ExpenseCategory.values.asMap().entries.map((entry) {
                final i = entry.key;
                final category = entry.value;
                final categoryLimit =
                    limits.where((l) => l.category == category).firstOrNull;
                return _BudgetCard(
                  icon: category.icon,
                  iconColor: category.color,
                  title: category.label,
                  subtitle: categoryLimit != null
                      ? 'Limit set: \$${categoryLimit.amount.toStringAsFixed(0)}'
                      : 'No limit set',
                  isSet: categoryLimit != null,
                  onEdit: () => _showEditDialog(
                      context, ref, categoryLimit, category, now),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 80 + i * 40))
                    .slideY(begin: 0.05, end: 0);
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    BudgetLimit? limit,
    ExpenseCategory? category,
    DateTime now,
  ) {
    final controller =
        TextEditingController(text: limit?.amount.toStringAsFixed(0) ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.r24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category?.icon ?? Icons.savings_rounded,
                color: category?.color ?? AppTheme.primaryColor,
                size: 20,
              ),
            ),
            AppSpacing.gapMd,
            Text(
              'Set ${category?.label ?? 'Total'} Budget',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Monthly Limit',
            prefixText: '\$ ',
            prefixStyle: const TextStyle(
                color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            hintText: '0',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              if (amount > 0) {
                final newLimit = BudgetLimit(
                  id: limit?.id ?? const Uuid().v4(),
                  amount: amount,
                  category: category,
                  month: now.month,
                  year: now.year,
                );
                ref.read(budgetLimitsProvider.notifier).saveLimit(newLimit);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r12)),
            ),
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSet;
  final VoidCallback onEdit;

  const _BudgetCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSet,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSet
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.grey.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.textPrimary),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSet ? AppTheme.successColor : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                subtitle,
                style: TextStyle(
                    fontSize: 12,
                    color:
                        isSet ? AppTheme.successColor : AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_rounded,
                size: 16, color: AppTheme.primaryColor),
          ),
          onPressed: onEdit,
        ),
      ),
    );
  }
}
