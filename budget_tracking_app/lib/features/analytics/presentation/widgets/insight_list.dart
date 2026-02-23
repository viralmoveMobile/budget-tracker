import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InsightList extends StatelessWidget {
  final List<String> insights;

  const InsightList({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Insights & Suggestions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...insights.map((insight) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading:
                    const Icon(Icons.lightbulb_outline, color: Colors.orange),
                title: Text(
                  insight,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1, end: 0)),
      ],
    );
  }
}
