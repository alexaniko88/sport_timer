import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/settings/settings_state.dart';
import 'package:sport_timer/features/settings/settings_view_model.dart';
import 'package:sport_timer/features/settings/timer_style.dart';

class _FakeSettingsRepository implements SettingsRepository {
  final List<TimerStyle> savedStyles = [];
  TimerStyle storedStyle = TimerStyle.ring;
  bool failStyleRead = false;
  bool failStyleSave = false;
  bool failSettingsRead = false;
  Completer<void>? styleReadGate;

  @override
  Future<Result<TimerSettings>> getTimerSettings() async {
    if (failSettingsRead) return Failure(Exception('settings failed'));
    return const Success(
      TimerSettings(
        preparationTime: Duration(seconds: 10),
        roundTime: Duration(seconds: 90),
        restTime: Duration(seconds: 15),
        rounds: 3,
      ),
    );
  }

  @override
  Future<Result<void>> saveTimerSettings(TimerSettings settings) async => const Success(null);

  @override
  Future<Result<TimerStyle>> getTimerStyle() async {
    await styleReadGate?.future;
    if (failStyleRead) return Failure(Exception('read failed'));
    return Success(storedStyle);
  }

  @override
  Future<Result<void>> saveTimerStyle(TimerStyle style) async {
    if (failStyleSave) return Failure(Exception('save failed'));
    savedStyles.add(style);
    return const Success(null);
  }
}

void main() {
  late _FakeSettingsRepository repository;
  late SettingsViewModel viewModel;

  setUp(() {
    repository = _FakeSettingsRepository();
    viewModel = SettingsViewModel(repository);
  });

  tearDown(() => viewModel.dispose());

  group('SettingsViewModel.loadSettings', () {
    test('starts with the ring style', () {
      expect(viewModel.state.value.timerStyle, TimerStyle.ring);
    });

    test('loads the saved timer style', () async {
      repository.storedStyle = TimerStyle.fullColor;

      await viewModel.loadSettings();

      expect(viewModel.state.value.status, SettingsStatus.loaded);
      expect(viewModel.state.value.timerStyle, TimerStyle.fullColor);
      expect(viewModel.state.value.timerSettings.rounds, 3);
    });

    test('keeps the loaded times and the ring style when the style read fails', () async {
      repository.failStyleRead = true;

      await viewModel.loadSettings();

      expect(viewModel.state.value.status, SettingsStatus.loaded);
      expect(viewModel.state.value.timerStyle, TimerStyle.ring);
      expect(viewModel.state.value.timerSettings.rounds, 3);
    });
  });

  group('SettingsViewModel.loadSettings with a style', () {
    test('keeps the loaded style when the settings read fails', () async {
      repository.failSettingsRead = true;
      repository.storedStyle = TimerStyle.fullColor;

      await viewModel.loadSettings();

      expect(viewModel.state.value.status, SettingsStatus.error);
      expect(viewModel.state.value.timerStyle, TimerStyle.fullColor);
    });

    test('does not overwrite a style picked while loading', () async {
      repository.storedStyle = TimerStyle.fullColor;
      repository.styleReadGate = Completer<void>();

      final loading = viewModel.loadSettings();
      await viewModel.selectTimerStyle(TimerStyle.roundsStrip);
      repository.styleReadGate!.complete();
      await loading;

      expect(viewModel.state.value.timerStyle, TimerStyle.roundsStrip);
    });
  });

  group('SettingsViewModel.selectTimerStyle', () {
    test('updates the state at once and saves the style', () async {
      final future = viewModel.selectTimerStyle(TimerStyle.roundsStrip);
      expect(viewModel.state.value.timerStyle, TimerStyle.roundsStrip);
      await future;

      expect(repository.savedStyles, [TimerStyle.roundsStrip]);
      expect(viewModel.state.value.status, isNot(SettingsStatus.saving));
    });

    test('sets the error status and message when the save fails', () async {
      repository.failStyleSave = true;

      await viewModel.selectTimerStyle(TimerStyle.fullColor);

      expect(viewModel.state.value.status, SettingsStatus.error);
      expect(viewModel.state.value.errorMessage, contains('save failed'));
      expect(viewModel.state.value.timerStyle, TimerStyle.ring);
      expect(viewModel.state.value.status, isNot(SettingsStatus.saving));
    });

    test('changes no state after dispose', () async {
      // A separate model, because tearDown disposes the shared one.
      final model = SettingsViewModel(repository);
      final future = model.selectTimerStyle(TimerStyle.fullColor);
      model.dispose();

      await future;

      expect(repository.savedStyles, [TimerStyle.fullColor]);
    });
  });
}
