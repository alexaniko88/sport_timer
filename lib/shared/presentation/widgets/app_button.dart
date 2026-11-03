import 'package:flutter/material.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';

enum _AppButtonVariant { primary, secondary }

class AppButton extends StatelessWidget {
  final _AppButtonVariant _variant;
  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? foregroundColor;
  final bool isExpanded;

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.foregroundColor,
    this.isExpanded = false,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.isExpanded = false,
  })  : _variant = _AppButtonVariant.secondary,
        foregroundColor = null;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    final content = _AppButtonContent(label: label, icon: icon);

    final Widget button = _variant == _AppButtonVariant.primary
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: foregroundColor,
            ),
            child: content,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(width: AppBorderWidth.thin, color: color ?? outline),
            ),
            child: content,
          );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class _AppButtonContent extends StatelessWidget {
  final String label;
  final Widget? icon;

  const _AppButtonContent({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    if (icon == null) {
      return Text(label);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: AppSpacing.s8),
        Flexible(child: Text(label)),
      ],
    );
  }
}
