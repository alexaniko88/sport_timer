import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/timer/domain/audio_manager.dart';
import 'package:sport_timer/features/timer/domain/background_keep_alive.dart';
import 'package:sport_timer/features/timer/domain/timer_activity_recorder.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/features/timer/presentation/timer_page.dart';
import 'package:sport_timer/features/timer/presentation/widgets/ring_timer_view.dart';
import 'package:sport_timer/l10n/app_localizations.dart';

class _Audio implements AudioManager {
  @override
  Future<void> dispose() async {}
  @override
  void playPreparationSound() {}
  @override
  void playRoundFinishSound() {}
  @override
  void playRoundStartSound() {}
  @override
  void playWorkoutDoneSound() {}
}

class _KeepAlive implements BackgroundKeepAlive {
  @override
  Future<void> start({
    required String notificationTitle,
    required String notificationText,
    required VoidCallback onPause,
    required VoidCallback onResume,
  }) async {}
  @override
  Future<void> setPaused({required bool isPaused}) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> updateText({required String text}) async {}
}

class _Recorder implements TimerActivityRecorder {
  final run = _Run();
  int starts = 0;
  bool fail = false;

  @override
  Result<TimerActivityRun> start(TimerParams params) {
    starts++;
    if (fail) return Failure(Exception('No signed-in account'));
    return Success(run);
  }

  @override
  Stream<Exception> get failures => const Stream.empty();
  @override
  void retryPendingWrites() {}
}

class _Run implements TimerActivityRun {
  int reconciliations = 0;
  int ends = 0;

  @override
  void reconcile(Duration elapsed) => reconciliations++;
  @override
  void pause(Duration elapsed) {}
  @override
  void resume() {}
  @override
  void end(Duration elapsed) => ends++;
}

void main() {
  const channel = 'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';
  const params = TimerParams(
    preparationTime: Duration.zero,
    roundTime: Duration(minutes: 1),
    restTime: Duration.zero,
    rounds: 1,
    style: TimerStyle.ring,
  );

  testWidgets('injects the recorder, reconciles on resume and stops observing on disposal', (tester) async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler(channel, (_) async => const StandardMessageCodec().encodeMessage([null]));
    addTearDown(() => messenger.setMockMessageHandler(channel, null));
    final recorder = _Recorder();
    getIt.registerSingleton<AudioManager>(_Audio());
    getIt.registerSingleton<BackgroundKeepAlive>(_KeepAlive());
    getIt.registerSingleton<TimerActivityRecorder>(recorder);
    addTearDown(getIt.reset);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TimerPage(params: params),
      ),
    );
    expect(recorder.starts, 1);
    final beforeResume = recorder.run.reconciliations;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(recorder.run.reconciliations, beforeResume + 1);

    await tester.pumpWidget(const SizedBox());
    expect(recorder.run.ends, 1);
    final afterDispose = recorder.run.reconciliations;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(recorder.run.reconciliations, afterDispose);
  });

  testWidgets('runs the timer and shows a dismissible notice when recording cannot start', (tester) async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler(channel, (_) async => const StandardMessageCodec().encodeMessage([null]));
    addTearDown(() => messenger.setMockMessageHandler(channel, null));
    final recorder = _Recorder()..fail = true;
    getIt.registerSingleton<AudioManager>(_Audio());
    getIt.registerSingleton<BackgroundKeepAlive>(_KeepAlive());
    getIt.registerSingleton<TimerActivityRecorder>(recorder);
    addTearDown(getIt.reset);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TimerPage(params: params),
      ),
    );
    await tester.pump();
    await tester.pump();
    const notice = 'Could not save this workout to your statistics.';
    expect(find.text(notice), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byType(RingTimerView), findsOneWidget);
    expect(recorder.starts, 1);

    // The 3 seconds start once the entrance animation is done.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(notice), findsNothing);

    await tester.pumpWidget(const SizedBox());
    expect(recorder.run.ends, 0);
  });
}
