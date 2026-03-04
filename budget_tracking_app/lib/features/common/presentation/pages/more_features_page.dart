import '../../../../widgets/ui/app_app_bar.dart';
import '../../../../widgets/ui/app_scaffold.dart';
import 'package:budget_tracking_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../../../features/wages_calculator/presentation/pages/wages_calculator_page.dart';
import '../../../../features/exchange/presentation/pages/currency_converter_page.dart';
import '../../../../features/holidays/presentation/pages/holiday_list_page.dart';
import '../../../../features/cash_book/presentation/pages/cash_book_page.dart';
import '../../../../features/sharing/presentation/pages/sharing_overview_page.dart';
import '../../../../features/invoices/presentation/pages/invoice_list_page.dart';
import '../../../../features/data_management/presentation/pages/data_management_page.dart';
import 'package:budget_tracking_app/core/theme/app_spacing.dart';

class MoreFeaturesPage extends StatelessWidget {
  const MoreFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureItem(
        title: 'Holidays',
        icon: Icons.beach_access,
        color: Colors.orange,
        page: const HolidayListPage(),
      ),
      _FeatureItem(
        title: 'Cash Book',
        icon: Icons.library_books,
        color: Colors.blue,
        page: const CashBookPage(),
      ),
      _FeatureItem(
        title: 'Sharing',
        icon: Icons.share,
        color: Colors.purple,
        page: const SharingOverviewPage(),
      ),
      _FeatureItem(
        title: 'Invoices',
        icon: Icons.receipt,
        color: Colors.teal,
        page: const InvoiceListPage(),
      ),
      _FeatureItem(
        title: 'Exchange',
        icon: Icons.currency_exchange,
        color: Colors.green,
        page: const CurrencyConverterPage(),
      ),
      _FeatureItem(
        title: 'Wages',
        icon: Icons.calculate,
        color: Colors.indigo,
        page: const WagesCalculatorPage(),
      ),
      _FeatureItem(
        title: 'Data',
        icon: Icons.storage,
        color: AppTheme.getTextColor(context, isSecondary: true),
        page: const DataManagementPage(),
      ),
    ];

    return AppScaffold(
      appBar: AppAppBar(title: const Text('More Features')),
      body: GridView.builder(
        padding: AppSpacing.cardPadding,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final item = features[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => item.page),
              );
            },
            borderRadius: BorderRadius.circular(AppSpacing.r24),
            child: Container(
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.r24),
                border: Border.all(color: item.color.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 32, color: item.color),
                  AppSpacing.gapMd,
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;

  _FeatureItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.page,
  });
}
