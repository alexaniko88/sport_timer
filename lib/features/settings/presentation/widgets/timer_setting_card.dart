import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';

class TimerSettingCard extends StatelessWidget {
  static const double _borderWidth = 1;

  final String label;
  final String value;
  final String semanticHint;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const TimerSettingCard({
    super.key,
    required this.label,
    required this.value,
    required this.semanticHint,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  static TextStyle? _labelStyle(ThemeData theme) => theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      );

  static TextStyle? _valueStyle(ThemeData theme) =>
      theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.r12);

    return Semantics(
      container: true,
      button: true,
      label: label,
      value: value,
      hint: semanticHint,
      onTap: onPressed,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: radius,
            border: Border.all(color: colors.outlineVariant, width: _borderWidth),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: iconColor, size: AppSpacing.s40),
                  const Gap(AppSpacing.s8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _labelStyle(theme),
                  ),
                  const Gap(AppSpacing.s8),
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _valueStyle(theme),
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

class TimerSettingGrid extends StatelessWidget {
  static const double _minimumColumnWidth = 140;

  final List<TimerSettingCard> children;

  const TimerSettingGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final theme = Theme.of(context);
    final defaultStyle = DefaultTextStyle.of(context).style;
    final direction = Directionality.of(context);
    final locale = Localizations.maybeLocaleOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumnWidth = (constraints.maxWidth - AppSpacing.s16) / 2;
        final columns = twoColumnWidth < _minimumColumnWidth * textScaler.scale(1) ? 1 : 2;
        final columnWidth = (constraints.maxWidth - (columns - 1) * AppSpacing.s16) / columns;
        final textWidth = math.max(0.0, columnWidth - 2 * (AppSpacing.s12 + TimerSettingCard._borderWidth));

        double textHeight({required String text, required TextStyle? style}) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: defaultStyle.merge(style)),
            textDirection: direction,
            textScaler: textScaler,
            locale: locale,
            maxLines: 1,
            ellipsis: '\u2026',
          )..layout(maxWidth: textWidth);
          final height = painter.height;
          painter.dispose();
          return height;
        }

        var cardHeight = columnWidth;
        for (final card in children) {
          final contentHeight = AppSpacing.s40 +
              2 * AppSpacing.s8 +
              2 * (AppSpacing.s12 + TimerSettingCard._borderWidth) +
              textHeight(text: card.label, style: TimerSettingCard._labelStyle(theme)) +
              textHeight(text: card.value, style: TimerSettingCard._valueStyle(theme));
          cardHeight = math.max(cardHeight, contentHeight);
        }

        return GridView.count(
          crossAxisCount: columns,
          padding: EdgeInsets.zero,
          crossAxisSpacing: AppSpacing.s16,
          mainAxisSpacing: AppSpacing.s16,
          mainAxisExtent: cardHeight,
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}
