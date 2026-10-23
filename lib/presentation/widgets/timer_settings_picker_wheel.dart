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
  final int maxMinutes;
  final int rounds;
  final Color buttonsColor;
  final PicketType picketType;

  const TimerSettingsPickerWheel._({
    required this.initialDuration,
    required this.maxMinutes,
    required this.rounds,
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
    int maxMinutes = 60,
    int maxRounds = 2,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
        child: TimerSettingsPickerWheel._(
          onDurationChanged: onDurationChanged,
          onRoundsChanged: onRoundsChanged,
          initialDuration: initialDuration ?? Duration.zero,
          maxMinutes: maxMinutes,
          rounds: maxRounds,
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
  static const double _sheetHeightFraction = 1 / 3;
  static const double _wheelHeight = 300;
  static const double _itemExtent = 60;
  static const double _perspective = 0.003;
  static const double _diameterRatio = 0.8;
  static const double _selectedBorderWidth = 3;
  static const double _unselectedBorderWidth = 1;
  static const double _separatorWidth = 40;
  static const double _separatorHeight = 200;

  late FixedExtentScrollController _minutesController;
  late FixedExtentScrollController _secondsController;
  late FixedExtentScrollController _roundsController;

  int minutes = 0;
  int seconds = 0;
  int rounds = 0;

  @override
  void initState() {
    super.initState();
    final durationInSeconds = widget.initialDuration.inSeconds;
    minutes = durationInSeconds ~/ 60;
    seconds = durationInSeconds - (minutes * 60);
    rounds = widget.rounds;

    _minutesController = FixedExtentScrollController(initialItem: minutes);
    _secondsController = FixedExtentScrollController(initialItem: seconds);
    _roundsController = FixedExtentScrollController(initialItem: rounds - 1);
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
    return SizedBox(
      height: MediaQuery.of(context).copyWith().size.height * _sheetHeightFraction,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Container(
            color: widget.buttonsColor.withValues(alpha: 0.2),
            child: Column(
              children: [
                Expanded(
                  child: switch (widget.picketType) {
                    PicketType.time => _buildTimePicker(),
                    PicketType.rounds => _buildRoundPicker(),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundPicker() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s16),
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                context.l10n.commonRounds,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: _wheelHeight,
                      width: MediaQuery.of(context).size.width / 2,
                      child: ListWheelScrollView.useDelegate(
                        controller: _roundsController,
                        itemExtent: _itemExtent,
                        perspective: _perspective,
                        diameterRatio: _diameterRatio,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            rounds = index + 1;
                            widget.onRoundsChanged?.call(rounds);
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 100,
                          builder: (context, index) {
                            final value = index + 1;
                            final isSelected = value == rounds;
                            return Container(
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
                                style: (isSelected
                                        ? AppTextStyles.pickerRoundsSelected
                                        : AppTextStyles.pickerRoundsUnselected)
                                    .copyWith(
                                  color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
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
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(l10n.pickerMinutes, style: theme.textTheme.titleLarge),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: _wheelHeight,
                      child: ListWheelScrollView.useDelegate(
                        controller: _minutesController,
                        itemExtent: _itemExtent,
                        perspective: _perspective,
                        diameterRatio: _diameterRatio,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            minutes = index;
                            widget.onDurationChanged?.call(
                              Duration(minutes: minutes, seconds: seconds),
                            );
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: widget.maxMinutes,
                          builder: (context, index) {
                            final isSelected = index == minutes;
                            return Container(
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
                                    (isSelected ? AppTextStyles.pickerTimeSelected : AppTextStyles.pickerTimeUnselected)
                                        .copyWith(
                                  color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: _separatorWidth,
            height: _separatorHeight,
            child: Center(
              child: Text(
                ':',
                style: AppTextStyles.pickerSeparator.copyWith(color: widget.buttonsColor),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      l10n.pickerSeconds,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: _wheelHeight,
                      child: ListWheelScrollView.useDelegate(
                        controller: _secondsController,
                        itemExtent: _itemExtent,
                        perspective: _perspective,
                        diameterRatio: _diameterRatio,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            seconds = index;
                            widget.onDurationChanged?.call(
                              Duration(minutes: minutes, seconds: seconds),
                            );
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 60,
                          builder: (context, index) {
                            final isSelected = index == seconds;
                            return Container(
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
                                    (isSelected ? AppTextStyles.pickerTimeSelected : AppTextStyles.pickerTimeUnselected)
                                        .copyWith(
                                  color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
