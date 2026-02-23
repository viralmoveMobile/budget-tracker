import 'package:flutter/material.dart';

enum FeatureType {
  expenses,
  wages,
  accounts,
  analysis,
  exchange,
  holiday,
  sharing,
  cashBook,
  invoices,
  defaults,
}

class AppTheme {
  // ==================== PROFESSIONAL COLOR PALETTE ====================

  // Primary Brand Colors
  static const Color primaryColor = Color(0xFF5E5CE6); // Deep Indigo
  static const Color primaryLight = Color(0xFF8B89F7); // Light Indigo
  static const Color primaryDark = Color(0xFF4845B4); // Dark Indigo

  // Semantic Colors (iOS-inspired)
  static const Color successColor = Color(0xFF34C759); // Green
  static const Color warningColor = Color(0xFFFF9500); // Orange
  static const Color dangerColor = Color(0xFFFF3B30); // Red
  static const Color infoColor = Color(0xFF007AFF); // Blue

  // Neutral Palette (Light Theme)
  static const Color backgroundLight = Color(0xFFF5F5F7); // Off-white
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white
  static const Color borderLight = Color(0xFFE5E5EA); // Light gray border
  static const Color textPrimary = Color(0xFF1C1C1E); // Near black
  static const Color textSecondary = Color(0xFF8E8E93); // Medium gray
  static const Color textTertiary = Color(0xFFC7C7CC); // Light gray

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);

  // Legacy Feature Colors (kept for backward compatibility but unified)
  static const Color expensesColor = dangerColor;
  static const Color wagesColor = warningColor;
  static const Color accountsColor = successColor;
  static const Color analysisColor = primaryColor;
  static const Color exchangeColor = infoColor;
  static const Color holidayColor = Color(0xFF34C759);
  static const Color sharingColor = warningColor;
  static const Color cashBookColor = successColor;
  static const Color invoiceColor = Color(0xFFFF2D55);

  // Chart Colors (Accessible palette)
  static const List<Color> chartColors = [
    primaryColor, // Indigo
    warningColor, // Orange
    successColor, // Green
    dangerColor, // Red
    infoColor, // Blue
    Color(0xFFAF52DE), // Purple
  ];

  // ==================== TYPOGRAPHY SYSTEM ====================

  static const TextStyle displayStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  static const TextStyle h1Style = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle h2Style = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle h3Style = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  static const TextStyle smallStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  // ==================== SPACING SYSTEM ====================

  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2xl = 48.0;

  // ==================== BORDER RADIUS ====================

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // ==================== METHODS ====================

  static Color getFeatureColor(FeatureType type) {
    // Unified theme: All features use the Primary Brand Color
    return primaryColor;
  }

  // ==================== THEME DATA ====================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryLight,
        surface: surfaceLight,
        error: dangerColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      cardTheme: CardTheme(
        color: surfaceLight,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: h2Style.copyWith(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: displayStyle,
        headlineLarge: h1Style,
        headlineMedium: h2Style,
        headlineSmall: h3Style,
        bodyLarge: bodyStyle,
        bodyMedium: captionStyle,
        bodySmall: smallStyle,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.dark(
        primary: primaryLight,
        secondary: primaryLight,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  // ==================== REUSABLE DECORATIONS ====================

  static BoxDecoration cardDecoration({
    Color? color,
    double? borderRadius,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? surfaceLight,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusLg),
      border:
          borderColor != null ? Border.all(color: borderColor, width: 1) : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static BoxDecoration elevatedCardDecoration({
    Color? color,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? surfaceLight,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusLg),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration gradientDecoration({
    required List<Color> colors,
    double? borderRadius,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius ?? radiusLg),
    );
  }

  static BoxDecoration glassDecoration({
    Color? color,
    double opacity = 0.1,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius ?? radiusLg),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ================= THEME-AWARE COLOR HELPERS =================

  /// Get text color based on theme brightness
  static Color getTextColor(
    BuildContext context, {
    double opacity = 1.0,
    bool isSecondary = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isSecondary) {
      return isDark
          ? Colors.white.withOpacity(0.6 * opacity)
          : textSecondary.withOpacity(opacity);
    }
    return isDark
        ? Colors.white.withOpacity(opacity)
        : textPrimary.withOpacity(opacity);
  }

  /// Get background color based on theme
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  /// Get surface/card color based on theme
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  /// Get divider color based on theme
  static Color getDividerColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);
  }

  /// Get border color based on theme
  static Color getBorderColor(BuildContext context, {double opacity = 0.2}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withOpacity(0.1 * opacity)
        : Colors.grey.withOpacity(opacity);
  }
}
