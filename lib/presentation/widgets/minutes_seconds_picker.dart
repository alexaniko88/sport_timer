import 'dart:async';

import 'package:basic_flutter_helper/basic_flutter_helper.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

enum TimePickerType {
  minutes,
  seconds,
}

class MinutesSecondsPicker extends StatefulWidget {
  const MinutesSecondsPicker._({
    required this.onDurationChanged,
    required this.initialDuration,
    required this.maxMinutes,
    required this.buttonsColor,
  });

  static void show({
    required BuildContext context,
    required Function(Duration duration) onDurationChanged,
    required Duration initialDuration,
    int maxMinutes = 60,
    Color? buttonsColor,
  }) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: MinutesSecondsPicker._(
          onDurationChanged: onDurationChanged,
          initialDuration: initialDuration,
          maxMinutes: maxMinutes,
          buttonsColor: buttonsColor,
        ),
      ),
    );
  }

  final Function(Duration duration) onDurationChanged;
  final Duration initialDuration;
  final int maxMinutes;
  final Color? buttonsColor;

  @override
  State<MinutesSecondsPicker> createState() => _MinutesSecondsPickerState();
}

class _MinutesSecondsPickerState extends State<MinutesSecondsPicker> {
  Timer? _timer;
  int minutes = 0;
  int seconds = 0;

  @override
  void initState() {
    final durationInSeconds = widget.initialDuration.inSeconds;
    minutes = durationInSeconds ~/ 60;
    seconds = durationInSeconds - (minutes * 60);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).copyWith().size.height / 4,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            color: widget.buttonsColor?.withOpacity(0.2),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        increasing: true,
                        timePickerType: TimePickerType.minutes,
                        iconData: Icons.arrow_upward,
                      ),
                      const Gap(20),
                      _buildActionButton(
                        increasing: true,
                        timePickerType: TimePickerType.seconds,
                        iconData: Icons.arrow_upward,
                      ),
                    ],
                  ),
                  Text(
                    Duration(minutes: minutes, seconds: seconds).asMinutesAndSeconds,
                    style: const TextStyle(fontSize: 50),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        increasing: false,
                        timePickerType: TimePickerType.minutes,
                        iconData: Icons.arrow_downward,
                      ),
                      const Gap(20),
                      _buildActionButton(
                        increasing: false,
                        timePickerType: TimePickerType.seconds,
                        iconData: Icons.arrow_downward,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required bool increasing,
    required TimePickerType timePickerType,
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
          onPressed: () => _toggleTimeValue(
            increasing: increasing,
            timePickerType: timePickerType,
          ),
          backgroundColor: widget.buttonsColor,
          child: Icon(iconData),
        ),
      ),
    );
  }

  void _startTimer({required bool increasing, required TimePickerType timePickerType}) {
    setState(() {
      _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        _toggleTimeValue(increasing: increasing, timePickerType: timePickerType);
      });
    });
  }

  void _stopTimer() {
    setState(() {
      _timer?.cancel();
    });
  }

  void _toggleTimeValue({
    required bool increasing,
    required TimePickerType timePickerType,
  }) {
    setState(() {
      switch (timePickerType) {
        case TimePickerType.minutes:
          minutes = (minutes + (increasing ? 1 : -1) + widget.maxMinutes) % widget.maxMinutes;
          break;
        case TimePickerType.seconds:
          seconds = (seconds + (increasing ? 1 : -1) + 60) % 60;
          break;
      }
      widget.onDurationChanged(Duration(minutes: minutes, seconds: seconds));
    });
  }
}
