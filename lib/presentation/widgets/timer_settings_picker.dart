import 'dart:async';

import 'package:basic_flutter_helper/basic_flutter_helper.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

enum _TimePickerType {
  minutes,
  seconds,
  rounds,
}

enum PicketType {
  time,
  rounds,
}

class TimerSettingsPicker extends StatefulWidget {
  const TimerSettingsPicker._({
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
    Duration? initialDuration,
    Function(Duration duration)? onDurationChanged,
    Function(int rounds)? onRoundsChanged,
    int maxMinutes = 60,
    int maxRounds = 2,
    Color? buttonsColor,
  }) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: TimerSettingsPicker._(
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

  final Function(Duration duration)? onDurationChanged;
  final Function(int rounds)? onRoundsChanged;
  final Duration initialDuration;
  final int maxMinutes;
  final int rounds;
  final Color? buttonsColor;
  final PicketType picketType;

  @override
  State<TimerSettingsPicker> createState() => _TimerSettingsPickerState();
}

class _TimerSettingsPickerState extends State<TimerSettingsPicker> {
  Timer? _timer;
  int minutes = 0;
  int seconds = 0;
  int rounds = 0;

  @override
  void initState() {
    final durationInSeconds = widget.initialDuration.inSeconds;
    minutes = durationInSeconds ~/ 60;
    seconds = durationInSeconds - (minutes * 60);
    rounds = widget.rounds;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).copyWith().size.height / 3,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            color: widget.buttonsColor?.withValues(alpha: 0.5),
            child: Center(
              child: switch (widget.picketType) {
                PicketType.time => _buildTimePicker(),
                PicketType.rounds => _buildRoundPicker(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundPicker() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          rounds.toString(),
          style: const TextStyle(fontSize: 80),
        ),
        const Gap(20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              increasing: true,
              timePickerType: _TimePickerType.rounds,
              iconData: Icons.add,
            ),
            const Gap(10),
            _buildActionButton(
              increasing: false,
              timePickerType: _TimePickerType.rounds,
              iconData: Icons.remove,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          Duration(minutes: minutes, seconds: seconds).asMinutesAndSeconds,
          style: const TextStyle(fontSize: 90),
        ),
        const Gap(20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              increasing: true,
              timePickerType: _TimePickerType.minutes,
              iconData: Icons.add,
            ),
            const Gap(10),
            _buildActionButton(
              increasing: false,
              timePickerType: _TimePickerType.minutes,
              iconData: Icons.remove,
            ),
            const Gap(10),
            _buildActionButton(
              increasing: true,
              timePickerType: _TimePickerType.seconds,
              iconData: Icons.add,
            ),
            const Gap(10),
            _buildActionButton(
              increasing: false,
              timePickerType: _TimePickerType.seconds,
              iconData: Icons.remove,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required bool increasing,
    required _TimePickerType timePickerType,
    required IconData iconData,
  }) {
    return GestureDetector(
      onLongPress: () => _startTimer(
        increasing: increasing,
        timePickerType: timePickerType,
      ),
      onLongPressEnd: (_) => _stopTimer(),
      child: SizedBox.square(
        dimension: 50,
        child: FloatingActionButton(
          onPressed: () => _toggleValue(
            increasing: increasing,
            timePickerType: timePickerType,
          ),
          backgroundColor: widget.buttonsColor,
          child: Icon(iconData),
        ),
      ),
    );
  }

  void _startTimer({
    required bool increasing,
    required _TimePickerType timePickerType,
  }) {
    setState(() {
      _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        _toggleValue(increasing: increasing, timePickerType: timePickerType);
      });
    });
  }

  void _stopTimer() {
    setState(() {
      _timer?.cancel();
    });
  }

  void _toggleValue({
    required bool increasing,
    required _TimePickerType timePickerType,
  }) {
    setState(() {
      switch (timePickerType) {
        case _TimePickerType.minutes:
          minutes = (minutes + (increasing ? 1 : -1) + widget.maxMinutes) %
              widget.maxMinutes;
          widget.onDurationChanged
              ?.call(Duration(minutes: minutes, seconds: seconds));
          break;
        case _TimePickerType.seconds:
          seconds = (seconds + (increasing ? 1 : -1) + 60) % 60;
          widget.onDurationChanged
              ?.call(Duration(minutes: minutes, seconds: seconds));
          break;
        case _TimePickerType.rounds:
          setState(() {
            rounds = (rounds + (increasing ? 1 : -1) + 13) % 13;
            if (rounds == 0) {
              rounds = increasing ? 1 : 12;
            }
            widget.onRoundsChanged?.call(rounds);
          });
      }
    });
  }
}
