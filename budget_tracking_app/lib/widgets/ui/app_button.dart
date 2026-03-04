import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine the actual interaction state
    final bool canPress = !isLoading && !isDisabled && onPressed != null;

    // Resolve colors based on variant
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = colorScheme.secondary;
        foregroundColor = colorScheme.onSecondary;
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = colorScheme.primary;
        borderSide = BorderSide(color: colorScheme.primary);
        break;
    }

    if (!canPress) {
      backgroundColor = colorScheme.outline.withOpacity(0.12);
      foregroundColor = colorScheme.onSurface.withOpacity(0.38);
      if (variant == AppButtonVariant.outline) {
        borderSide = BorderSide(color: colorScheme.outline.withOpacity(0.12));
      }
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      side: borderSide,
      elevation: variant == AppButtonVariant.outline ? 0 : null,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
      ),
      disabledBackgroundColor: backgroundColor,
      disabledForegroundColor: foregroundColor,
    );

    return ElevatedButton(
      onPressed: canPress ? onPressed : null,
      style: buttonStyle,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
              ),
            )
          : Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: foregroundColor,
              ),
            ),
    );
  }
}
