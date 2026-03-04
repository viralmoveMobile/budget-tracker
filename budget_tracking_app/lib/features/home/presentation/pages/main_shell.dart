import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../expenses/presentation/pages/expense_list_screen.dart';
import '../../../accounts/presentation/pages/accounts_overview_page.dart';
import '../../../analytics/presentation/pages/analytics_dashboard_page.dart';
import '../../../common/presentation/pages/more_features_page.dart';
import 'home_page.dart';

/// Provides the bottom navigation bar to descendant widgets.
class MainShellScope extends InheritedWidget {
  final Widget bottomNavBar;
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const MainShellScope({
    super.key,
    required this.bottomNavBar,
    required this.currentIndex,
    required this.onTabChanged,
    required super.child,
  });

  static MainShellScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final navBar = _buildBottomNavBar(context);

    const pages = [
      HomePage(),
      ExpenseListPage(),
      AccountsOverviewPage(),
      AnalyticsDashboardPage(),
      MoreFeaturesPage(),
    ];

    return MainShellScope(
      bottomNavBar: navBar,
      currentIndex: _currentIndex,
      onTabChanged: (i) => setState(() => _currentIndex = i),
      child: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    // Note: since we changed from 5 to 4 items in the nav bar UI,
    // we need to map the 4 UI buttons to the 5 pages we have.
    // Wait, the screenshot only has 4 items. Let's map them to:
    // 0: Home -> HomePage
    // 1: Chart -> AnalyticsDashboardPage
    // 2: Sync -> AccountsOverviewPage (or something similar, earlier it was SharingOverviewPage)
    // 3: Grid -> MoreFeaturesPage
    // However, I don't want to break the IndexedStack mapping for existing pages.
    // The user had 5 tabs earlier, but the screenshot only has 4.
    // I will use 5 items to match the 5 pages, just styled correctly.
    final actualItems = [
      const _NavItem(Icons.home_rounded),
      const _NavItem(Icons.receipt_long_rounded),
      const _NavItem(Icons.account_balance_wallet_rounded),
      const _NavItem(Icons.insert_chart_rounded),
      const _NavItem(Icons.grid_view_rounded),
    ];

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(actualItems.length, (index) {
                final isActive = _currentIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isActive ? AppTheme.primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      actualItems[index].icon,
                      size: 28,
                      color: isActive
                          ? Colors.white
                          : AppTheme.getTextColor(context, isSecondary: true),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  const _NavItem(this.icon);
}
