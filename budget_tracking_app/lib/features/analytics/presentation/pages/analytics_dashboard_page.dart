import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/analytics_providers.dart';
import '../providers/projection_provider.dart';
import '../../domain/models/analytics_data.dart';
import '../widgets/add_goal_sheet.dart';
import '../widgets/goal_tracking_card.dart';

class AnalyticsDashboardPage extends ConsumerWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsDashboardProvider);
    final projectionAsync = ref.watch(projectionProvider);

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          'Analytics & Insights',
          style: TextStyle(
              color: AppTheme.getSurfaceColor(context),
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(analyticsDashboardProvider);
              ref.invalidate(projectionProvider);
            },
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Time Range
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(context, 'Performance Overview'),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppTheme.getBorderColor(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: ref.watch(timeRangeProvider),
                        isDense: true,
                        icon: Icon(Icons.filter_list_rounded,
                            size: 16,
                            color:
                                AppTheme.getTextColor(context, opacity: 0.6)),
                        items:
                            ['Weekly', 'Monthly', 'Yearly'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getTextColor(context)),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(timeRangeProvider.notifier).state = val;
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildMetricSummary(context, data),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Smart Insights'),
              const SizedBox(height: 16),
              _buildSmartInsights(context, data),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Trends & Forecasting'),
              const SizedBox(height: 16),
              _buildTrendChart(context, data),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Budget Performance'),
              const SizedBox(height: 16),
              _buildBudgetPerformance(context, data),
              const SizedBox(height: 32),

              projectionAsync.when(
                data: (proj) => _buildProjectionCard(context, proj),
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Spending Distribution'),
              const SizedBox(height: 16),
              _buildSpendingPieChart(context, data),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Monthly Financial summary'),
              const SizedBox(height: 16),
              _buildMonthlyBreakdown(context, data),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Financial Goals'),
              const SizedBox(height: 16),
              const GoalListWidget(),
              const SizedBox(height: 80),
            ],
          ),
        ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoal(context),
        label: Text('Add Goal', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_task_rounded),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.getTextColor(context, opacity: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSmartInsights(
      BuildContext context, AnalyticsDashboardData data) {
    if (data.insights.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.insights.length,
        itemBuilder: (context, index) {
          final insight = data.insights[index];
          return Container(
            width: 280,
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: insight.color.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: insight.color.withOpacity(0.05),
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
                    Icon(insight.icon, color: insight.color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      insight.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: insight.color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Expanded(
                  child: Text(
                    insight.message,
                    style: TextStyle(
                      color: AppTheme.getTextColor(context),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildBudgetPerformance(
      BuildContext context, AnalyticsDashboardData data) {
    if (data.performance.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: AppTheme.cardDecoration(),
        child: Center(
          child: Text('No budgets set for this month',
              style: TextStyle(
                  color: AppTheme.getTextColor(context, opacity: 0.5))),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: data.performance.take(5).map((p) {
          final isOverBudget = p.percentage > 1.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(p.category.icon,
                            size: 16,
                            color:
                                AppTheme.getTextColor(context, opacity: 0.6)),
                        const SizedBox(width: 8),
                        Text(
                          p.category.label,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      '\$${p.spent.toStringAsFixed(0)} / \$${p.budget.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isOverBudget ? Colors.red : Colors.black54,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.getBorderColor(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: p.percentage.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: p.performanceColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: p.performanceColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMetricSummary(
      BuildContext context, AnalyticsDashboardData data) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Avg Income',
            amount: data.totalIncome /
                (data.monthlyTrends.isEmpty ? 1 : data.monthlyTrends.length),
            color: AppTheme.successColor,
            icon: Icons.arrow_downward_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'Avg Expense',
            amount: data.totalExpense /
                (data.monthlyTrends.isEmpty ? 1 : data.monthlyTrends.length),
            color: AppTheme.dangerColor,
            icon: Icons.arrow_upward_rounded,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildTrendChart(BuildContext context, AnalyticsDashboardData data) {
    if (data.monthlyTrends.isEmpty) {
      return Container(
        height: 200,
        decoration: AppTheme.cardDecoration(),
        child: Center(
          child: Text('No data for trends',
              style: TextStyle(
                  color: AppTheme.getTextColor(context, opacity: 0.5))),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(context, 'Income', AppTheme.successColor),
              const SizedBox(width: 24),
              _buildLegendItem(context, 'Expense', AppTheme.dangerColor),
            ],
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.5,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (data.monthlyTrends
                        .map((e) => e.income > e.expense ? e.income : e.expense)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2),
                barGroups: data.monthlyTrends.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final trend = entry.value;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: trend.income,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.successColor,
                            AppTheme.successColor.withOpacity(0.6)
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                      BarChartRodData(
                        toY: trend.expense,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.dangerColor,
                            AppTheme.dangerColor.withOpacity(0.6)
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        if (val.toInt() < data.monthlyTrends.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              data.monthlyTrends[val.toInt()].month
                                  .substring(0, 3),
                              style: TextStyle(
                                  color: AppTheme.getTextColor(context,
                                      opacity: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.getDividerColor(context), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.darkSurface,
                    tooltipPadding: EdgeInsets.all(8),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(0)}',
                        TextStyle(
                          color: AppTheme.getSurfaceColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: AppTheme.getTextColor(context, opacity: 0.6),
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ],
    );
  }

  Widget _buildSpendingPieChart(
      BuildContext context, AnalyticsDashboardData data) {
    if (data.spendingDistribution.isEmpty) {
      return Container(
        height: 150,
        decoration: AppTheme.cardDecoration(),
        child: Center(
          child: Text('No spending data',
              style: TextStyle(
                  color: AppTheme.getTextColor(context, opacity: 0.5))),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections:
                      data.spendingDistribution.asMap().entries.map((entry) {
                    final item = entry.value;
                    return PieChartSectionData(
                      color: item.color,
                      value: item.amount,
                      title:
                          '${(item.amount / data.totalExpense * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: data.spendingDistribution.take(5).map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: item.color, shape: BoxShape.circle),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.category,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextColor(context)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: 0.1, end: 0).fadeIn();
  }

  Widget _buildMonthlyBreakdown(
      BuildContext context, AnalyticsDashboardData data) {
    return Column(
      children: data.monthlyTrends.reversed.map((trend) {
        final double balance = trend.income - trend.expense;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_today_rounded,
                    color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trend.month,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Income: \$${trend.income.toStringAsFixed(0)} • Expense: \$${trend.expense.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: AppTheme.getTextColor(context, opacity: 0.5),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${balance >= 0 ? "+" : ""}\$${balance.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: balance >= 0
                          ? AppTheme.successColor
                          : AppTheme.dangerColor,
                    ),
                  ),
                  Text(
                    balance >= 0 ? 'Surplus' : 'Deficit',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0
                          ? AppTheme.successColor.withOpacity(0.6)
                          : AppTheme.dangerColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProjectionCard(BuildContext context, ProjectionData proj) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_graph_rounded,
                    size: 24, color: AppTheme.primaryColor),
              ),
              SizedBox(width: 16),
              Text(
                'Forecast',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context)),
              ),
              const Spacer(),
              _ConfidenceBadge(label: proj.confidence),
            ],
          ),
          const SizedBox(height: 24),
          _ProjectionRow(
              label: 'Est. Spending',
              amount: proj.estimatedNextMonthExpense,
              color: AppTheme.dangerColor),
          SizedBox(height: 12),
          _ProjectionRow(
              label: 'Est. Savings',
              amount: proj.estimatedNextMonthSavings,
              color: AppTheme.successColor),
          if (proj.estimatedNextMonthSavings > 0) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                  color: AppTheme.getTextColor(context, isSecondary: true),
                  height: 1,
                  indent: 8,
                  endIndent: 8), // Thinner divider
            ),
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Insight: You are on track to save more next month!',
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            AppTheme.getTextColor(context, isSecondary: true),
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  void _showAddGoal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddGoalSheet(),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final String label;
  const _ConfidenceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _MetricCard(
      {required this.title,
      required this.amount,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      color: AppTheme.getTextColor(context, opacity: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: AppTheme.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _ProjectionRow(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    color: AppTheme.getTextColor(context, opacity: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500))),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
