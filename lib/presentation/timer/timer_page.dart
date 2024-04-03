part of 'timer.dart';

class TimerPage extends StatelessWidget {
  const TimerPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final timerStyle = Theme.of(context).extension<TimerStyle>()!;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            BlocBuilder<TimeCountdownCubit, TimeCountdownState>(
              builder: (context, state) {
                return AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: _getBackgroundColorByStatus(
                    timerStatus: state.timerStatus,
                    style: timerStyle,
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Align(
                alignment: Alignment.topCenter,
                child: Stopwatch(),
              ),
            ),
            BlocBuilder<TimeCountdownCubit, TimeCountdownState>(
              builder: (context, state) {
                return Visibility(
                  visible: state.timerStatus == TimerStatus.round,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Lottie.asset(
                      'assets/animation/round_animation.lottie',
                      decoder: _customDecoder,
                      height: 300,
                    ),
                  ),
                );
              },
            ),
            BlocBuilder<TimeCountdownCubit, TimeCountdownState>(
              builder: (context, state) {
                return Visibility(
                  visible: state.timerStatus == TimerStatus.preparation || state.timerStatus == TimerStatus.rest,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Lottie.asset(
                      'assets/animation/prepare_animation.lottie',
                      decoder: _customDecoder,
                      height: 300,
                    ),
                  ),
                );
              },
            ),
            BlocBuilder<TimeCountdownCubit, TimeCountdownState>(
              builder: (context, state) {
                return Visibility(
                  visible: state.timerStatus == TimerStatus.finished,
                  child: Align(
                    alignment: Alignment.center,
                    child: Lottie.asset(
                      'assets/animation/finish_animation.lottie',
                      decoder: _customDecoder,
                    ),
                  ),
                );
              },
            ),
            BlocBuilder<TimeCountdownCubit, TimeCountdownState>(
              builder: (context, state) {
                final progress =
                    1 - state.totalSeconds / (state.totalDuration.inSeconds == 0 ? 1 : state.totalDuration.inSeconds);
                return Visibility(
                  visible: state.timerStatus != TimerStatus.finished,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(
                      value: progress,
                      color: _getProgressColor(progress: progress, timerStyle: timerStyle),
                      backgroundColor: Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                      minHeight: 40,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColorByStatus({
    required TimerStyle style,
    required TimerStatus timerStatus,
  }) {
    switch (timerStatus) {
      case TimerStatus.preparation:
        return style.preparationColor.withOpacity(0.2);
      case TimerStatus.round:
        return style.roundColor.withOpacity(0.2);
      case TimerStatus.rest:
        return style.restColor.withOpacity(0.2);
      case TimerStatus.finished:
        return style.finishColor.withOpacity(0.8);
    }
  }

  Future<LottieComposition?> _customDecoder(List<int> bytes) {
    return LottieComposition.decodeZip(bytes, filePicker: (files) {
      return files.firstWhereOrNull((f) => f.name.startsWith('animations/') && f.name.endsWith('.json'));
    });
  }

  Color _getProgressColor({
    required double progress,
    required TimerStyle timerStyle,
  }) {
    if (progress <= 0.70) {
      return Color.lerp(timerStyle.progressTimer1Color, timerStyle.progressTimer3Color, progress / 0.70)!;
    } else if (progress <= 0.80) {
      return Color.lerp(timerStyle.progressTimer3Color, timerStyle.progressTimer3Color, (progress - 0.70) / 0.10)!;
    } else if (progress <= 0.90) {
      return Color.lerp(timerStyle.progressTimer3Color, timerStyle.progressTimer4Color, (progress - 0.80) / 0.10)!;
    } else {
      return timerStyle.progressTimer4Color;
    }
  }
}
