part of '../timer.dart';

class Stopwatch extends StatelessWidget {
  const Stopwatch({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TimeCountdownCubit, TimeCountdownState>(
      listener: (context, state) {
        switch (state.status) {
          case TimeCountdownStatus.initial:
            break;
          case TimeCountdownStatus.getTime:
            break;
          case TimeCountdownStatus.finished:
            getIt<AudioManager>().playRoundFinishSound();
            break;
          case TimeCountdownStatus.paused:
            break;
          case TimeCountdownStatus.resumed:
            break;
          case TimeCountdownStatus.almostFinishing:
            getIt<AudioManager>().playPreparationSound();
            break;
          case TimeCountdownStatus.counterDone:
            printLog("Counter done!");
            break;
          case TimeCountdownStatus.next:
            break;
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () => context.read<TimeCountdownCubit>().togglePauseResume(),
          child: SizedBox(
            width: MediaQuery.of(context).size.width / 1.15,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange,
                                width: 3,
                              )),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "${state.currentRound}",
                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 45.0),
                      child: Text(
                        Duration(seconds: state.currentSeconds).asMinutesAndSeconds,
                        style: const TextStyle(fontSize: 120),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 200),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue,
                                width: 5,
                              )),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              Duration(seconds: state.totalSeconds).asMinutesAndSeconds,
                              style: const TextStyle(fontSize: 25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
