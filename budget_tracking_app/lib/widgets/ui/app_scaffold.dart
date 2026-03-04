import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/home/presentation/pages/main_shell.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool useSafeArea;
  final EdgeInsetsGeometry? padding;
  final bool withTealHeader;
  final Widget? heroContent;
  final Widget? drawer;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.useSafeArea = true,
    this.padding,
    this.withTealHeader = true,
    this.heroContent,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Apply padding if provided, otherwise default to AppSpacing.screenPadding
    Widget bodyContent = Padding(
      padding: padding ?? AppSpacing.screenPadding,
      child: body,
    );

    // Render within SafeArea if requested
    if (useSafeArea) {
      bodyContent = SafeArea(bottom: false, child: bodyContent);
    }

    // Auto-inject bottom nav from MainShellScope if it exists and wasn't explicitly overridden
    final shellScope = MainShellScope.of(context);
    final effectiveBottomNavBar =
        bottomNavigationBar ?? shellScope?.bottomNavBar;

    if (withTealHeader) {
      return Scaffold(
        key: key,
        backgroundColor: AppTheme.primaryColor,
        appBar: appBar,
        drawer: drawer,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: effectiveBottomNavBar,
        body: Column(
          children: [
            if (heroContent != null) heroContent!,
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: backgroundColor ?? theme.scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(40)),
                  child: bodyContent,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: key,
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      appBar: appBar,
      drawer: drawer,
      body: bodyContent,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: effectiveBottomNavBar,
    );
  }
}
