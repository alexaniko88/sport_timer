import 'package:flutter/material.dart';
import 'package:sport_timer/theme/app_spacing.dart';

enum _AppButtonVariant { primary, secondary, icon, option }

class AppButton extends StatelessWidget {
  static const double _borderWidth = 1;
  static const double _loaderStroke = 2;
  // Material 3 state layer opacities.
  static const double _hoverOpacity = 0.08;
  static const double _focusOpacity = 0.1;
  static const double _pressedOpacity = 0.1;

  final _AppButtonVariant _variant;
  final String label;
  final String? value;
  final String? semanticHint;
  final Widget? icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? foregroundColor;
  final bool isExpanded;
  final bool isLoading;

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.foregroundColor,
    this.isExpanded = false,
  })  : _variant = _AppButtonVariant.primary,
        value = null,
        semanticHint = null,
        tooltip = null,
        isLoading = false;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.isExpanded = false,
  })  : _variant = _AppButtonVariant.secondary,
        value = null,
        semanticHint = null,
        foregroundColor = null,
        tooltip = null,
        isLoading = false;

  const AppButton.icon({
    super.key,
    required Widget this.icon,
    required this.onPressed,
    required String this.tooltip,
    this.color,
    this.isLoading = false,
  })  : _variant = _AppButtonVariant.icon,
        label = '',
        value = null,
        semanticHint = null,
        foregroundColor = null,
        isExpanded = false;

  const AppButton.option({
    super.key,
    required this.label,
    required String this.value,
    required Color this.color,
    required Widget this.icon,
    required String this.semanticHint,
    required this.onPressed,
  })  : _variant = _AppButtonVariant.option,
        tooltip = null,
        foregroundColor = null,
        isExpanded = true,
        isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final outline = colorScheme.outline;
    final icon = this.icon;

    final button = switch (_variant) {
      _AppButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: foregroundColor,
          ),
          child: _AppButtonContent(label: label, icon: icon),
        ),
      _AppButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(width: _borderWidth, color: color ?? outline),
          ),
          child: _AppButtonContent(label: label, icon: icon),
        ),
      _AppButtonVariant.icon => FloatingActionButton.large(
          onPressed: isLoading ? null : onPressed,
          tooltip: tooltip,
          backgroundColor: color,
          child: isLoading
              ? const SizedBox.square(
                  dimension: AppSpacing.s24,
                  child: CircularProgressIndicator(strokeWidth: _loaderStroke),
                )
              : icon,
        ),
      _AppButtonVariant.option => _AppOptionTile(
          label: label,
          value: value ?? '',
          color: color ?? colorScheme.primary,
          icon: icon ?? const SizedBox.shrink(),
          semanticHint: semanticHint ?? '',
          onPressed: onPressed,
          hoverOpacity: _hoverOpacity,
          focusOpacity: _focusOpacity,
          pressedOpacity: _pressedOpacity,
        ),
    };

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

class _AppOptionTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Widget icon;
  final String semanticHint;
  final VoidCallback? onPressed;
  final double hoverOpacity;
  final double focusOpacity;
  final double pressedOpacity;

  const _AppOptionTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.semanticHint,
    required this.onPressed,
    required this.hoverOpacity,
    required this.focusOpacity,
    required this.pressedOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = ColorScheme.fromSeed(seedColor: color, brightness: theme.brightness);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(color: scheme.onPrimaryContainer);
    final radius = BorderRadius.circular(AppRadius.r12);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      hint: semanticHint,
      child: MergeSemantics(
        child: Material(
          elevation: 0,
          color: scheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: radius),
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            splashColor: scheme.onPrimaryContainer.withValues(alpha: pressedOpacity),
            hoverColor: scheme.onPrimaryContainer.withValues(alpha: hoverOpacity),
            focusColor: scheme.onPrimaryContainer.withValues(alpha: focusOpacity),
            highlightColor: scheme.onPrimaryContainer.withValues(alpha: pressedOpacity),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Row(
                children: [
                  Container(
                    width: AppSpacing.s40,
                    height: AppSpacing.s40,
                    decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                    child: IconTheme(
                      data: IconThemeData(color: scheme.onPrimary, size: AppSpacing.s24),
                      child: icon,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(child: Text(label, style: titleStyle)),
                  Text(value, style: titleStyle),
                  const SizedBox(width: AppSpacing.s8),
                  ExcludeSemantics(
                    child: Icon(Icons.unfold_more, color: scheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
