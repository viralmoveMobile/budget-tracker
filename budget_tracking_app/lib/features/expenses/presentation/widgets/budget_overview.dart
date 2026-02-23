import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/budget_provider.dart';
import '../../data/models/expense_category.dart';

import 'package:budget_tracking_app/features/my_account/presentation/providers/profile_provider.dart';

class BudgetOverview extends ConsumerWidget {
  const BudgetOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(budgetUsageProvider);
    final profile = ref.watch(profileProvider);

    if (usage == null) {
      return const SizedBox.shrink();
    }

    final double totalSpent = (usage['totalSpent'] as num).toDouble();
    final double totalLimit = (usage['totalLimit'] as num).toDouble();
    final Map<ExpenseCategory, Map<String, double>> categoryUsage =
        usage['categoryUsage'] as Map<ExpenseCategory, Map<String, double>>;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Budget',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(totalSpent / (totalLimit > 0 ? totalLimit : 1) * 100).toStringAsFixed(0)}% used',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressBar(
            context,
            'Total Budget',
            totalSpent,
            totalLimit,
            isTotal: true,
            color: AppTheme.primaryColor,
            currency: profile.currency,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.grey.withOpacity(0.1)),
          ),
          ...categoryUsage.entries
              .where((e) => e.value['limit']! > 0)
              .map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildProgressBar(
                context,
                entry.key.label,
                entry.value['spent']!,
                entry.value['limit']!,
                icon: entry.key.icon,
                color: entry.key.color,
                currency: profile.currency,
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildProgressBar(
    BuildContext context,
    String label,
    double spent,
    double limit, {
    bool isTotal = false,
    IconData? icon,
    Color? color,
    required String currency,
  }) {
    final double percent = limit > 0 ? spent / limit : 0;
    final effectiveColor = color ?? Colors.blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: effectiveColor.withOpacity(0.8)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontSize: isTotal ? 16 : 14,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: NumberFormat.simpleCurrency(
                            name: currency, decimalDigits: 0)
                        .format(spent),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isTotal ? 16 : 14,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' / ${NumberFormat.simpleCurrency(name: currency, decimalDigits: 0).format(limit)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: isTotal ? 12 : 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percent > 1.0 ? 1.0 : percent,
              child: Container(
                height: isTotal ? 12 : 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      effectiveColor,
                      effectiveColor.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (percent >= 0.9)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              percent >= 1.0 ? '⚠ Budget Exceeded' : '⚠ Near Limit',
              style: TextStyle(
                color: percent >= 1.0 ? AppTheme.dangerColor : Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeOut(duration: 800.ms),
          ),
      ],
    );
  }
}
