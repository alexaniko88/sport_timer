import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';

class AppTag extends StatelessWidget {
  static const double _verticalPadding = 4;
  static const double _iconSize = 16;

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const AppTag({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.r8);

    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: colorScheme.outlineVariant, width: AppBorderWidth.thin),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: _verticalPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: _iconSize,
              color: colorScheme.primary,
            ),
            const Gap(AppSpacing.s8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      if (semanticLabel == null) return box;
      return Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: box,
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      onTap: onTap,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: Center(widthFactor: 1, child: box),
          ),
        ),
      ),
    );
  }
}
