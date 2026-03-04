import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final FeatureType featureType;
  final Widget child;
  final VoidCallback? onTap;
  final double? height;
  final Widget? headerAction;

  const FeatureCard({
    super.key,
    required this.title,
    required this.featureType,
    required this.child,
    this.onTap,
    this.height,
    this.headerAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context), // theme-aware surface color
        borderRadius: BorderRadius.circular(AppSpacing.r24),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.r24),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.r12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getIconForFeature(featureType),
                        size: 18,
                        color: color,
                      ),
                      AppSpacing.gapSm,
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (headerAction != null) headerAction!,
                    ],
                  ),
                ),
                AppSpacing.gapMd,
                // Content
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForFeature(FeatureType type) {
    switch (type) {
      case FeatureType.expenses:
        return Icons.receipt_long_rounded;
      case FeatureType.wages:
        return Icons.work_history_rounded;
      case FeatureType.accounts:
        return Icons.account_balance_wallet_rounded;
      case FeatureType.analysis:
        return Icons.analytics_rounded;
      case FeatureType.exchange:
        return Icons.currency_exchange_rounded;
      case FeatureType.holiday:
        return Icons.flight_takeoff_rounded;
      case FeatureType.sharing:
        return Icons.ios_share_rounded;
      case FeatureType.cashBook:
        return Icons.book_rounded;
      case FeatureType.invoices:
        return Icons.description_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }
}
