import 'package:flutter/material.dart';
import 'sidebar_menu.dart';
import 'top_header.dart';
import '../../theme/app_theme.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final String title;

  const MainLayout({
    super.key,
    required this.body,
    this.title = 'Dashboard',
  });

  @override
  Widget build(BuildContext context) {
    // We use a GlobalKey to control the Scaffold drawer from the custom header
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppTheme.getBackgroundColor(context),
      drawer: const SidebarMenu(),
      body: Column(
        children: [
          // Custom Top Header
          TopHeader(
            onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
            title: title,
          ),
          // Scrollable Body Content
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }
}
