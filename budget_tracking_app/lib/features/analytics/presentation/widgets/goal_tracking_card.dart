import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/goal_provider.dart';
import '../../domain/models/financial_goal.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class GoalListWidget extends ConsumerWidget {
  const GoalListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) return const Center(child: Text('No goals set yet'));
        return Column(
          children: goals.map((goal) => _GoalCard(goal: goal)).toList(),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error loading goals: $e'),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final FinancialGoal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final isSavings = goal.type == GoalType.savings;
    final color = isSavings ? Colors.blue : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(goal.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.r12),
                  ),
                  child: Text(
                    goal.type.label,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            AppSpacing.gapLg,
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    backgroundColor: color.withOpacity(0.1),
                    color: color,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                AppSpacing.gapLg,
                Text('${(goal.progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            AppSpacing.gapSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '\$${goal.currentAmount.toStringAsFixed(0)} of \$${goal.targetAmount.toStringAsFixed(0)}'),
                if (goal.isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20)
                else
                  Text(
                    'Ends ${goal.deadline.month}/${goal.deadline.year}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
