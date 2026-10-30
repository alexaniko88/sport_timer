import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_timer/managers/background_keep_alive.dart';

typedef AsyncAction = Future<void> Function();

class DefaultBackgroundKeepAlive extends BackgroundKeepAlive {
  _SilentAudioHandler? _handler;
  Future<_SilentAudioHandler>? _handlerFuture;
  bool _isWanted = false;
  bool _hasAskedPermission = false;

  // The keep-alive is only needed where the OS suspends the app.
  bool get _isSupported =>
      defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> start({required String notificationTitle}) async {
    if (!_isSupported) return;
    _isWanted = true;
    // Not awaited, so the dialog does not delay the silent loop.
    unawaited(_requestNotificationPermission());
    try {
      final handler = _handler ??= await (_handlerFuture ??= _createHandler());
      // A stop that came while the handler was being created wins.
      if (!_isWanted) return;
      await handler.startSilence(notificationTitle);
    } catch (error) {
      // The timer must keep working when the background session cannot start.
      // A failed init is retried on the next start, a finished one never is.
      if (_handler == null) _handlerFuture = null;
      debugPrint('$runtimeType:: start failed: $error');
    }
  }

  @override
  Future<void> stop() async {
    _isWanted = false;
    try {
      await _handler?.stopSilence();
    } catch (error) {
      debugPrint('$runtimeType:: stop failed: $error');
    }
  }

  Future<_SilentAudioHandler> _createHandler() => AudioService.init(
        builder: _SilentAudioHandler.new,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'sport_timer.workout',
          androidNotificationChannelName: 'Workout',
          // The service stays in the foreground while paused, so it is never restarted from the background.
          androidStopForegroundOnPause: false,
        ),
      );

  // Asked once, on the first start. The foreground service works when this is
  // denied, only the notification is hidden. iOS needs no permission here.
  Future<void> _requestNotificationPermission() async {
    if (_hasAskedPermission || defaultTargetPlatform != TargetPlatform.android) return;
    _hasAskedPermission = true;
    try {
      await Permission.notification.request();
    } catch (error) {
      debugPrint('$runtimeType:: notification permission failed: $error');
    }
  }
}

/// Loops a silent track so the OS treats the app as playing audio, and shows
/// the media notification. It has no lock screen controls.
class _SilentAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  // Start and stop run one after the other, so a stop during a start always wins.
  Future<void> _queue = Future.value();
  bool _isActive = false;

  _SilentAudioHandler() {
    // It must not take audio focus, or the beeps and other apps would be ducked.
    _player
        .setAudioContext(
          AudioContext(
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: {AVAudioSessionOptions.mixWithOthers},
            ),
            android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
          ),
        )
        .catchError((Object error) => debugPrint('$runtimeType:: audio context failed: $error'));
    _player.setReleaseMode(ReleaseMode.loop);
    _player.onPlayerStateChanged.listen(_onPlayerStateChanged);
  }

  Future<void> startSilence(String notificationTitle) => _enqueue(() async {
        mediaItem.add(MediaItem(id: 'workout', title: notificationTitle));
        playbackState.add(
          PlaybackState(
            processingState: AudioProcessingState.ready,
            playing: true,
          ),
        );
        await _player.play(AssetSource('audio/silence.mp3'));
        _isActive = true;
      });

  Future<void> stopSilence() => _enqueue(() async {
        _isActive = false;
        await _player.stop();
        playbackState.add(PlaybackState());
      });

  Future<void> _enqueue(AsyncAction action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  // An interruption such as a phone call stops the loop, so it starts again.
  void _onPlayerStateChanged(PlayerState state) {
    if (_isActive && (state == PlayerState.paused || state == PlayerState.stopped)) {
      _player.resume();
    }
  }

  // The activity can be gone while this handler lives on, so the loop must end.
  @override
  Future<void> onTaskRemoved() => stopSilence();

  // The handler is a singleton, so it must stay usable for the next workout.
  @override
  Future<void> stop() => stopSilence();
}
