import 'package:flutter/material.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';

class AppSurface extends StatelessWidget {
  static const double defaultPadding = AppSpacing.s12;

  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool excludeFromSemantics;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final Key? surfaceKey;

  const AppSurface({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.excludeFromSemantics = false,
    this.padding = const EdgeInsets.all(defaultPadding),
    this.color,
    this.borderColor,
    this.surfaceKey,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.r12);
    final borderWidth = isSelected ? AppBorderWidth.thick : AppBorderWidth.thin;
    final fill = color ?? (isSelected ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainer);
    final border = isSelected ? colorScheme.primary : borderColor ?? colorScheme.outlineVariant;
    // The selected border is thicker, so the padding shrinks by the same amount to keep the size.
    final innerPadding = (padding - EdgeInsets.all(borderWidth - AppBorderWidth.thin)).clamp(
      EdgeInsets.zero,
      EdgeInsetsGeometry.infinity,
    );

    return Material(
      color: Colors.transparent,
      child: Ink(
        key: surfaceKey,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: borderRadius,
          border: Border.all(color: border, width: borderWidth),
        ),
        child: onTap == null
            ? Padding(padding: innerPadding, child: child)
            : InkWell(
                borderRadius: borderRadius,
                onTap: onTap,
                excludeFromSemantics: excludeFromSemantics,
                child: Padding(padding: innerPadding, child: child),
              ),
      ),
    );
  }
}
