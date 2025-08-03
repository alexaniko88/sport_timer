import 'package:flutter/material.dart';

enum PicketType {
  time,
  rounds,
}

class TimerSettingsPickerWheel extends StatefulWidget {
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
    Function(Duration duration)? onDurationChanged,
    Function(int rounds)? onRoundsChanged,
    int maxMinutes = 60,
    int maxRounds = 2,
  }) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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

  final Function(Duration duration)? onDurationChanged;
  final Function(int rounds)? onRoundsChanged;
  final Duration initialDuration;
  final int maxMinutes;
  final int rounds;
  final Color buttonsColor;
  final PicketType picketType;

  @override
  State<TimerSettingsPickerWheel> createState() => _TimerSettingsPickerWheelState();
}

class _TimerSettingsPickerWheelState extends State<TimerSettingsPickerWheel> {
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
      height: MediaQuery.of(context).copyWith().size.height / 3,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                "Rounds",
                style: TextStyle(fontSize: 22),
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
                      height: 300,
                      width: MediaQuery.of(context).size.width / 2,
                      child: ListWheelScrollView.useDelegate(
                        controller: _roundsController,
                        itemExtent: 60,
                        perspective: 0.003,
                        diameterRatio: 0.8,
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
                                color: isSelected ? widget.buttonsColor.withValues(alpha: 0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: widget.buttonsColor,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: Text(
                                value.toString(),
                                style: TextStyle(
                                  fontSize: isSelected ? 35 : 20,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.black : Colors.grey[600],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      "Minutes",
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 300,
                      child: ListWheelScrollView.useDelegate(
                        controller: _minutesController,
                        itemExtent: 60,
                        perspective: 0.003,
                        diameterRatio: 0.8,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            minutes = index;
                            widget.onDurationChanged?.call(Duration(minutes: minutes, seconds: seconds));
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: widget.maxMinutes,
                          builder: (context, index) {
                            final isSelected = index == minutes;
                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? widget.buttonsColor.withValues(alpha: 0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: widget.buttonsColor,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isSelected ? 32 : 24,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.black : Colors.grey[600],
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
            width: 40,
            height: 200,
            child: Center(
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: widget.buttonsColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      "Seconds",
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 300,
                      child: ListWheelScrollView.useDelegate(
                        controller: _secondsController,
                        itemExtent: 60,
                        perspective: 0.003,
                        diameterRatio: 0.8,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            seconds = index;
                            widget.onDurationChanged?.call(Duration(minutes: minutes, seconds: seconds));
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 60,
                          builder: (context, index) {
                            final isSelected = index == seconds;
                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? widget.buttonsColor.withValues(alpha: 0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: widget.buttonsColor,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isSelected ? 32 : 24,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.black : Colors.grey[600],
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
