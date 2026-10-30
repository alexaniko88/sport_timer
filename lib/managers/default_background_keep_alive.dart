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
  String _text = '';
  bool _isWanted = false;
  bool _hasAskedPermission = false;

  // The keep-alive is only needed where the OS suspends the app.
  bool get _isSupported =>
      defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> start({
    required String notificationTitle,
    required String notificationText,
    required VoidCallback onPause,
    required VoidCallback onResume,
  }) async {
    if (!_isSupported) return;
    _isWanted = true;
    _text = notificationText;
    // Not awaited, so the dialog does not delay the silent loop.
    unawaited(_requestNotificationPermission());
    try {
      final handler = _handler ??= await (_handlerFuture ??= _createHandler());
      // A stop that came while the handler was being created wins.
      if (!_isWanted) return;
      // Read after the awaits, so an update that came meanwhile is not lost.
      await handler.startSilence(
        title: notificationTitle,
        text: _text,
        onPause: onPause,
        onResume: onResume,
      );
    } catch (error) {
      // The timer must keep working when the background session cannot start.
      // A failed init is retried on the next start, a finished one never is.
      if (_handler == null) _handlerFuture = null;
      debugPrint('$runtimeType:: start failed: $error');
    }
  }

  @override
  Future<void> updateText({required String text}) async {
    _text = text;
    if (!_isWanted) return;
    try {
      await _handler?.updateText(text);
    } catch (error) {
      debugPrint('$runtimeType:: update text failed: $error');
    }
  }

  @override
  Future<void> setPaused({required bool isPaused}) async {
    if (!_isWanted) return;
    try {
      await _handler?.setPaused(isPaused);
    } catch (error) {
      debugPrint('$runtimeType:: set paused failed: $error');
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
/// the media notification with a pause or play button.
class _SilentAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  // Start and stop run one after the other, so a stop during a start always wins.
  Future<void> _queue = Future.value();
  VoidCallback? _onPause;
  VoidCallback? _onResume;
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

  Future<void> startSilence({
    required String title,
    required String text,
    required VoidCallback onPause,
    required VoidCallback onResume,
  }) =>
      _enqueue(() async {
        _onPause = onPause;
        _onResume = onResume;
        mediaItem.add(MediaItem(id: 'workout', title: title, artist: text));
        playbackState.add(_playbackStateFor(isPaused: false));
        await _player.play(AssetSource('audio/silence.mp3'));
        _isActive = true;
      });

  Future<void> updateText(String text) => _enqueue(() async {
        final current = mediaItem.value;
        if (!_isActive || current == null || current.artist == text) return;
        mediaItem.add(current.copyWith(artist: text));
      });

  // The silent loop keeps playing while paused, only the notification state changes.
  Future<void> setPaused(bool isPaused) => _enqueue(() async {
        if (!_isActive) return;
        playbackState.add(_playbackStateFor(isPaused: isPaused));
      });

  PlaybackState _playbackStateFor({required bool isPaused}) => PlaybackState(
        processingState: AudioProcessingState.ready,
        playing: !isPaused,
        controls: [isPaused ? MediaControl.play : MediaControl.pause],
        systemActions: const {MediaAction.play, MediaAction.pause},
        androidCompactActionIndices: const [0],
      );

  Future<void> stopSilence() => _enqueue(() async {
        _isActive = false;
        _onPause = null;
        _onResume = null;
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

  @override
  Future<void> pause() async => _onPause?.call();

  @override
  Future<void> play() async => _onResume?.call();

  // The handler is a singleton, so it must stay usable for the next workout.
  @override
  Future<void> stop() => stopSilence();
}
