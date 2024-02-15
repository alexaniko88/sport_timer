import 'dart:async';

import 'package:flutter/material.dart';

class RoundsPicker extends StatefulWidget {
  const RoundsPicker._({
    required this.onRoundsChanged,
    required this.rounds,
    required this.buttonsColor,
  });

  static void show({
    required BuildContext context,
    required Function(int rounds) onRoundsChanged,
    required int rounds,
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
        child: RoundsPicker._(
          onRoundsChanged: onRoundsChanged,
          rounds: rounds,
          buttonsColor: buttonsColor,
        ),
      ),
    );
  }

  final Function(int rounds) onRoundsChanged;
  final int rounds;
  final Color? buttonsColor;

  @override
  State<RoundsPicker> createState() => _RoundsPickerState();
}

class _RoundsPickerState extends State<RoundsPicker> {
  Timer? _timer;
  int rounds = 0;

  @override
  void initState() {
    rounds = widget.rounds;
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
                  _buildActionButton(
                    increasing: true,
                    iconData: Icons.arrow_upward,
                  ),
                  Text(
                    rounds.toString(),
                    style: const TextStyle(fontSize: 50),
                  ),
                  _buildActionButton(
                    increasing: false,
                    iconData: Icons.arrow_downward,
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
    required IconData iconData,
  }) {
    return GestureDetector(
      onLongPress: () => _startTimer(increasing: increasing),
      onLongPressEnd: (_) => _stopTimer(),
      child: SizedBox.square(
        dimension: 50,
        child: FloatingActionButton(
          onPressed: () => _toggleTimeValue(increasing: increasing),
          backgroundColor: widget.buttonsColor,
          child: Icon(iconData),
        ),
      ),
    );
  }

  void _startTimer({required bool increasing}) {
    setState(() {
      _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        _toggleTimeValue(increasing: increasing);
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
  }) {
    setState(() {
      rounds = (rounds + (increasing ? 1 : -1) + 13) % 13;
      if (rounds == 0) {
        rounds = increasing ? 1 : 12;
      }
      widget.onRoundsChanged(rounds);
    });
  }
}
