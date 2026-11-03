import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sport_timer/shared/presentation/extensions/text_theme_extension.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/widgets/app_surface.dart';

class TimerSettingCard extends StatelessWidget {
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

  static TextStyle? _labelStyle(ThemeData theme) => theme.textTheme.emphasizedLabel.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      );

  static TextStyle? _valueStyle(ThemeData theme) => theme.textTheme.tileValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      button: true,
      label: label,
      value: value,
      hint: semanticHint,
      onTap: onPressed,
      excludeSemantics: true,
      child: AppSurface(
        onTap: onPressed,
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
        final textWidth = math.max(0.0, columnWidth - 2 * (AppSurface.defaultPadding + AppBorderWidth.thin));

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
              2 * (AppSurface.defaultPadding + AppBorderWidth.thin) +
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
