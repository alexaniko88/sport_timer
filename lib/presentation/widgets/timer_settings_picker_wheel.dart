import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sport_timer/core/l10n_context.dart';
import 'package:sport_timer/theme/app_palette.dart';
import 'package:sport_timer/theme/app_spacing.dart';
import 'package:sport_timer/theme/app_text_styles.dart';

enum PicketType {
  time,
  rounds,
}

class TimerSettingsPickerWheel extends StatefulWidget {
  final ValueChanged<Duration>? onDurationChanged;
  final ValueChanged<int>? onRoundsChanged;
  final Duration initialDuration;
  final Duration minDuration;
  final int maxMinutes;
  final int rounds;
  final int maxRounds;
  final Color buttonsColor;
  final PicketType picketType;

  const TimerSettingsPickerWheel._({
    required this.initialDuration,
    required this.minDuration,
    required this.maxMinutes,
    required this.rounds,
    required this.maxRounds,
    required this.buttonsColor,
    required this.picketType,
    this.onDurationChanged,
    this.onRoundsChanged,
  });

  static void show({
    required BuildContext context,
    required PicketType picketType,
    required Color buttonsColor,
    Duration? initialDuration,
    ValueChanged<Duration>? onDurationChanged,
    ValueChanged<int>? onRoundsChanged,
    Duration minDuration = Duration.zero,
    int maxMinutes = 60,
    int rounds = 2,
    int maxRounds = 100,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
        child: TimerSettingsPickerWheel._(
          onDurationChanged: onDurationChanged,
          onRoundsChanged: onRoundsChanged,
          initialDuration: initialDuration ?? Duration.zero,
          minDuration: minDuration,
          maxMinutes: maxMinutes,
          rounds: rounds,
          maxRounds: maxRounds,
          buttonsColor: buttonsColor,
          picketType: picketType,
        ),
      ),
    );
  }

  @override
  State<TimerSettingsPickerWheel> createState() => _TimerSettingsPickerWheelState();
}

class _TimerSettingsPickerWheelState extends State<TimerSettingsPickerWheel> {
  static const double _sheetHeightFraction = 0.4;
  static const double _sheetMinHeight = 320;
  static const EdgeInsets _contentPadding = EdgeInsets.only(
    left: AppSpacing.s20,
    right: AppSpacing.s20,
    bottom: AppSpacing.s20,
  );
  static const double _itemExtent = 60;
  static const double _perspective = 0.003;
  static const double _diameterRatio = 2;
  static const double _nearOpacity = 0.6;
  static const double _farOpacity = 0.3;
  static const double _selectedBorderWidth = 3;
  static const double _unselectedBorderWidth = 1;
  static const double _separatorWidth = 40;

  late FixedExtentScrollController _minutesController;
  late FixedExtentScrollController _secondsController;
  late FixedExtentScrollController _roundsController;

  int minutes = 0;
  int seconds = 0;
  int rounds = 0;

  @override
  void initState() {
    super.initState();
    final initialDuration = _clampDuration(widget.initialDuration);
    minutes = initialDuration.inMinutes;
    seconds = initialDuration.inSeconds % 60;
    rounds = widget.rounds.clamp(1, widget.maxRounds);

    _minutesController = FixedExtentScrollController(initialItem: minutes);
    _secondsController = FixedExtentScrollController(initialItem: seconds);
    _roundsController = FixedExtentScrollController(initialItem: rounds - 1);
  }

  // Items fade out the further they are from the selected one.
  double _opacityForDistance(int distance) => switch (distance) {
        0 => 1,
        1 => _nearOpacity,
        _ => _farOpacity,
      };

  Duration _clampDuration(Duration duration) {
    final maxDuration = Duration(minutes: widget.maxMinutes);
    return switch (duration) {
      _ when duration < widget.minDuration => widget.minDuration,
      _ when duration > maxDuration => maxDuration,
      _ => duration,
    };
  }

  void _onTimeChanged({required int newMinutes, required int newSeconds}) {
    final picked = Duration(minutes: newMinutes, seconds: newSeconds);
    final clamped = _clampDuration(picked);
    setState(() {
      minutes = clamped.inMinutes;
      seconds = clamped.inSeconds % 60;
    });
    // Move the wheels back when the pick is outside the allowed range.
    if (clamped != picked) {
      _minutesController.jumpToItem(minutes);
      _secondsController.jumpToItem(seconds);
    }
    widget.onDurationChanged?.call(clamped);
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _roundsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = max(
      MediaQuery.sizeOf(context).height * _sheetHeightFraction,
      _sheetMinHeight,
    );
    return Container(
      height: sheetHeight,
      color: widget.buttonsColor.withValues(alpha: 0.2),
      // Keeps the wheel above the system navigation bar; the color still fills under it.
      child: SafeArea(
        top: false,
        child: switch (widget.picketType) {
          PicketType.time => _buildTimePicker(),
          PicketType.rounds => _buildRoundPicker(),
        },
      ),
    );
  }

  Widget _buildRoundPicker() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: _contentPadding,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: Text(
              context.l10n.commonRounds,
              style: theme.textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width / 2,
                child: ListWheelScrollView.useDelegate(
                  controller: _roundsController,
                  itemExtent: _itemExtent,
                  perspective: _perspective,
                  diameterRatio: _diameterRatio,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() => rounds = index + 1);
                    widget.onRoundsChanged?.call(rounds);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: widget.maxRounds,
                    builder: (context, index) {
                      final value = index + 1;
                      final isSelected = value == rounds;
                      return Opacity(
                        opacity: _opacityForDistance((value - rounds).abs()),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? widget.buttonsColor.withValues(alpha: 0.2) : AppPalette.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.r8),
                            border: Border.all(
                              color: widget.buttonsColor,
                              width: isSelected ? _selectedBorderWidth : _unselectedBorderWidth,
                            ),
                          ),
                          child: Text(
                            value.toString(),
                            style:
                                (isSelected ? AppTextStyles.pickerSelected : AppTextStyles.pickerUnselected).copyWith(
                              color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: _contentPadding,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.pickerMinutes,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: _separatorWidth),
                Expanded(
                  child: Text(
                    l10n.pickerSeconds,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: _minutesController,
                    itemExtent: _itemExtent,
                    perspective: _perspective,
                    diameterRatio: _diameterRatio,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      _onTimeChanged(newMinutes: index, newSeconds: seconds);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.maxMinutes + 1,
                      builder: (context, index) {
                        final isSelected = index == minutes;
                        return Opacity(
                          opacity: _opacityForDistance((index - minutes).abs()),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? widget.buttonsColor.withValues(alpha: 0.2) : AppPalette.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.r8),
                              border: Border.all(
                                color: widget.buttonsColor,
                                width: isSelected ? _selectedBorderWidth : _unselectedBorderWidth,
                              ),
                            ),
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style:
                                  (isSelected ? AppTextStyles.pickerSelected : AppTextStyles.pickerUnselected).copyWith(
                                color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: _separatorWidth,
                  child: Center(
                    child: Text(
                      ':',
                      style: AppTextStyles.pickerSeparator.copyWith(color: widget.buttonsColor),
                    ),
                  ),
                ),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: _secondsController,
                    itemExtent: _itemExtent,
                    perspective: _perspective,
                    diameterRatio: _diameterRatio,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      _onTimeChanged(newMinutes: minutes, newSeconds: index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 60,
                      builder: (context, index) {
                        final isSelected = index == seconds;
                        return Opacity(
                          opacity: _opacityForDistance((index - seconds).abs()),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? widget.buttonsColor.withValues(alpha: 0.2) : AppPalette.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.r8),
                              border: Border.all(
                                color: widget.buttonsColor,
                                width: isSelected ? _selectedBorderWidth : _unselectedBorderWidth,
                              ),
                            ),
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style:
                                  (isSelected ? AppTextStyles.pickerSelected : AppTextStyles.pickerUnselected).copyWith(
                                color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
