import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/domain/settings_repository.dart';
import 'package:sport_timer/features/settings/domain/timer_configuration.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/settings/presentation/settings_state.dart';
import 'package:sport_timer/features/settings/presentation/settings_view_model.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/templates/domain/built_in_templates.dart';
import 'package:sport_timer/features/templates/domain/custom_template.dart';
import 'package:sport_timer/features/templates/domain/custom_template_icon.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';
import '../../templates/fake_custom_template_repository.dart';

class _FakeSettingsRepository implements SettingsRepository {
  String? selectedTemplateId;
  @override
  Future<Result<TimerConfiguration>> getTimerConfiguration() async {
    final result = await getTimerSettings();
    return switch (result) {
      Success(:final value) => Success(TimerConfiguration(value, selectedTemplateId)),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> saveTimerConfiguration(TimerConfiguration configuration) async {
    final result = await saveTimerSettings(configuration.settings);
    if (result is Success<void>) selectedTemplateId = configuration.selectedTemplateId;
    return result;
  }

  final List<TimerStyle> savedStyles = [];
  final List<TimerSettings> savedSettings = [];
  TimerSettings storedSettings = const TimerSettings(
    preparationTime: Duration(seconds: 10),
    roundTime: Duration(seconds: 90),
    restTime: Duration(seconds: 15),
    rounds: 3,
  );
  bool failSettingsSave = false;
  Completer<void>? settingsReadGate;
  Completer<void>? settingsSaveGate;
  TimerStyle storedStyle = TimerStyle.ring;
  bool failStyleRead = false;
  bool failStyleSave = false;
  bool failSettingsRead = false;
  Completer<void>? styleReadGate;

  @override
  Future<Result<TimerSettings>> getTimerSettings() async {
    await settingsReadGate?.future;
    if (failSettingsRead) return Failure(Exception('settings failed'));
    return Success(storedSettings);
  }

  @override
  Future<Result<void>> saveTimerSettings(TimerSettings settings) async {
    savedSettings.add(settings);
    await settingsSaveGate?.future;
    if (failSettingsSave) return Failure(Exception('save settings failed'));
    storedSettings = settings;
    return const Success(null);
  }

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
  late FakeCustomTemplateRepository templates;
  late SettingsViewModel viewModel;

  setUp(() {
    repository = _FakeSettingsRepository();
    templates = FakeCustomTemplateRepository();
    viewModel = SettingsViewModel(repository, templates);
  });

  tearDown(() => viewModel.dispose());

  test('initial settings match the default template', () {
    expect(viewModel.state.value.timerSettings, builtInTemplates.first.settings);
  });

  group('explicit template selection', () {
    final template = builtInTemplates.first;

    test('matching settings do not imply selection; same-value selection persists', () async {
      repository.storedSettings = template.settings;
      await viewModel.loadSettings();
      expect(viewModel.state.value.selectedTemplateId, isNull);
      await viewModel.selectTemplate(template);
      expect(viewModel.state.value.selectedTemplateId, template.id);
      expect(repository.selectedTemplateId, template.id.name);
      final restarted = SettingsViewModel(repository, templates);
      await restarted.loadSettings();
      expect(restarted.state.value.selectedTemplateId, template.id);
      restarted.dispose();
    });

    test('each divergent field clears selection permanently, including after flush', () async {
      await viewModel.loadSettings();
      for (var field = 0; field < 4; field++) {
        await viewModel.selectTemplate(template);
        switch (field) {
          case 0:
            viewModel.updatePreparationTime(const Duration(seconds: 21));
          case 1:
            viewModel.updateRoundTime(const Duration(seconds: 61));
          case 2:
            viewModel.updateRestTime(const Duration(seconds: 31));
          case 3:
            viewModel.updateRounds(6);
        }
        expect(viewModel.state.value.selectedTemplateId, isNull);
        switch (field) {
          case 0:
            viewModel.updatePreparationTime(template.settings.preparationTime);
          case 1:
            viewModel.updateRoundTime(template.settings.roundTime);
          case 2:
            viewModel.updateRestTime(template.settings.restTime);
          case 3:
            viewModel.updateRounds(template.settings.rounds);
        }
        expect(viewModel.state.value.selectedTemplateId, isNull);
        await viewModel.flushSettings();
        final restarted = SettingsViewModel(repository, templates);
        await restarted.loadSettings();
        expect(restarted.state.value.selectedTemplateId, isNull);
        restarted.dispose();
      }
    });

    test('unchanged fields and style preserve selection', () async {
      await viewModel.loadSettings();
      await viewModel.selectTemplate(template);
      viewModel.updatePreparationTime(template.settings.preparationTime);
      viewModel.updateRoundTime(template.settings.roundTime);
      viewModel.updateRestTime(template.settings.restTime);
      viewModel.updateRounds(template.settings.rounds);
      await viewModel.selectTimerStyle(TimerStyle.fullColor);
      await viewModel.flushSettings();
      expect(viewModel.state.value.selectedTemplateId, template.id);
      expect(repository.selectedTemplateId, template.id.name);
    });

    for (final id in ['unknown', TemplateId.hyrox.name]) {
      test('does not restore unknown or mismatched ID $id', () async {
        repository.storedSettings = template.settings;
        repository.selectedTemplateId = id;
        await viewModel.loadSettings();
        expect(viewModel.state.value.selectedTemplateId, isNull);
      });
    }

    test('selection and subsequent field edit survive a delayed load', () async {
      repository.settingsReadGate = Completer<void>();
      final loading = viewModel.loadSettings();
      final selecting = viewModel.selectTemplate(builtInTemplates[1]);
      viewModel.updateRounds(19);
      final flushing = viewModel.flushSettings();
      repository.settingsReadGate!.complete();
      await Future.wait([loading, selecting, flushing]);
      expect(viewModel.state.value.timerSettings.rounds, 19);
      expect(viewModel.state.value.selectedTemplateId, isNull);
      expect(repository.storedSettings.rounds, 19);
      expect(repository.selectedTemplateId, isNull);
    });

    test('pending save cannot restore an older selection over a newer one', () async {
      await viewModel.loadSettings();
      repository.settingsSaveGate = Completer<void>();
      final first = viewModel.selectTemplate(builtInTemplates[1]);
      final second = viewModel.selectTemplate(builtInTemplates[2]);
      repository.settingsSaveGate!.complete();
      await Future.wait([first, second]);
      expect(viewModel.state.value.selectedTemplateId, TemplateId.hyrox);
      expect(repository.selectedTemplateId, TemplateId.hyrox.name);
      expect(repository.storedSettings, builtInTemplates[2].settings);
    });
  });

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

  group('SettingsViewModel timer settings persistence', () {
    test('changes memory while scrolling and saves only when flushed', () async {
      await viewModel.loadSettings();
      viewModel.updatePreparationTime(const Duration(seconds: 25));
      viewModel.updateRoundTime(const Duration(seconds: 120));
      viewModel.updateRestTime(const Duration(seconds: 40));
      viewModel.updateRounds(8);
      viewModel.updateRounds(9);

      expect(repository.savedSettings, isEmpty);
      expect(viewModel.state.value.timerSettings.rounds, 9);
      await viewModel.flushSettings();

      expect(repository.savedSettings, [viewModel.state.value.timerSettings]);
      final nextSession = SettingsViewModel(repository, templates);
      await nextSession.loadSettings();
      expect(nextSession.state.value.timerSettings, viewModel.state.value.timerSettings);
      nextSession.dispose();
    });

    test('does not write unchanged settings or values changed back', () async {
      await viewModel.loadSettings();
      viewModel.updateRounds(3);
      await viewModel.flushSettings();
      viewModel.updateRounds(9);
      viewModel.updateRounds(3);
      await viewModel.flushSettings();

      expect(repository.savedSettings, isEmpty);
    });

    test('a flush after an immediate no-op drain still saves the latest edit', () async {
      await viewModel.loadSettings();
      viewModel.updateRounds(4);
      viewModel.updateRounds(3);
      final first = viewModel.flushSettings();
      viewModel.updateRounds(5);
      final second = viewModel.flushSettings();
      await Future.wait([first, second]);

      expect(repository.savedSettings.map((settings) => settings.rounds), [5]);
      expect(repository.storedSettings.rounds, 5);
    });

    test('serializes overlapping flushes and keeps the newest snapshot', () async {
      await viewModel.loadSettings();
      final gate = Completer<void>();
      repository.settingsSaveGate = gate;
      viewModel.updateRounds(8);
      final first = viewModel.flushSettings();
      viewModel.updateRounds(9);
      final second = viewModel.flushSettings();
      viewModel.updateRounds(10);
      final third = viewModel.flushSettings();
      expect(repository.savedSettings.map((settings) => settings.rounds), [8]);

      gate.complete();
      await Future.wait([first, second, third]);

      expect(repository.savedSettings.map((settings) => settings.rounds), [8, 10]);
      expect(viewModel.state.value.timerSettings.rounds, 10);
      expect(repository.storedSettings.rounds, 10);
    });

    test('a save completion keeps newer uncommitted wheel edits in memory', () async {
      await viewModel.loadSettings();
      final gate = Completer<void>();
      repository.settingsSaveGate = gate;
      viewModel.updateRounds(8);
      final saving = viewModel.flushSettings();
      viewModel.updateRounds(9);
      gate.complete();
      await saving;

      expect(viewModel.state.value.timerSettings.rounds, 9);
      expect(repository.savedSettings.map((settings) => settings.rounds), [8]);
      await viewModel.flushSettings();
      expect(repository.storedSettings.rounds, 9);
    });

    test('merges edits with untouched stored fields before a slow load completes', () async {
      final gate = Completer<void>();
      repository.settingsReadGate = gate;
      final loading = viewModel.loadSettings();
      viewModel.updateRounds(5);
      final saving = viewModel.flushSettings();
      expect(repository.savedSettings, isEmpty);
      gate.complete();
      await loading;
      await saving;

      expect(repository.storedSettings.rounds, 5);
      expect(repository.storedSettings.roundTime, const Duration(seconds: 90));
      expect(repository.storedSettings.preparationTime, const Duration(seconds: 10));
      expect(repository.storedSettings.restTime, const Duration(seconds: 15));
    });

    test('an explicit default template wins over a slow initial load', () async {
      final gate = Completer<void>();
      repository.settingsReadGate = gate;
      final loading = viewModel.loadSettings();
      final defaults = viewModel.state.value.timerSettings;
      final saving = viewModel.saveSettings(defaults);
      gate.complete();
      await loading;
      await saving;

      expect(repository.storedSettings, defaults);
      expect(viewModel.state.value.timerSettings, defaults);
    });

    test('failed writes can be retried without changing the selection again', () async {
      await viewModel.loadSettings();
      repository.failSettingsSave = true;
      viewModel.updateRounds(8);
      await viewModel.flushSettings();
      expect(viewModel.state.value.status, SettingsStatus.error);
      expect(viewModel.state.value.timerSettings.rounds, 8);

      repository.failSettingsSave = false;
      await viewModel.flushSettings();
      expect(repository.storedSettings.rounds, 8);
      expect(repository.savedSettings, hasLength(2));
    });

    test('reverting after a partial failed write still saves the original values', () async {
      await viewModel.loadSettings();
      repository.failSettingsSave = true;
      viewModel.updateRounds(8);
      await viewModel.flushSettings();
      // Simulate the platform accepting part of a failed multi-field save.
      repository.storedSettings = repository.storedSettings.copyWith(rounds: 8);
      viewModel.updateRounds(3);
      repository.failSettingsSave = false;
      await viewModel.flushSettings();

      expect(repository.savedSettings.map((settings) => settings.rounds), [8, 3]);
      expect(repository.storedSettings.rounds, 3);
    });

    test('a failed initial read keeps edits for a later safe retry', () async {
      repository.failSettingsRead = true;
      await viewModel.loadSettings();
      viewModel.updateRounds(8);
      await viewModel.flushSettings();
      expect(repository.savedSettings, isEmpty);
      repository.failSettingsRead = false;
      await viewModel.flushSettings();

      expect(repository.storedSettings.rounds, 8);
      expect(repository.storedSettings.roundTime, const Duration(seconds: 90));
    });

    test('explicit template saves update state immediately and use the same queue', () async {
      await viewModel.loadSettings();
      final template = repository.storedSettings.copyWith(rounds: 20);
      await viewModel.saveSettings(template);

      expect(viewModel.state.value.timerSettings, template);
      expect(repository.storedSettings, template);
    });

    test('dispose flushes dirty settings without notifying disposed state', () async {
      final model = SettingsViewModel(repository, templates);
      await model.loadSettings();
      final gate = Completer<void>();
      repository.settingsSaveGate = gate;
      model.updateRounds(8);
      model.dispose();
      final saving = model.flushSettings();
      gate.complete();
      await saving;

      expect(repository.storedSettings.rounds, 8);
    });

    test('dispose during loading preserves edits and untouched stored fields', () async {
      final model = SettingsViewModel(repository, templates);
      final gate = Completer<void>();
      repository.settingsReadGate = gate;
      final loading = model.loadSettings();
      model.updateRounds(8);
      model.dispose();
      final saving = model.flushSettings();
      gate.complete();
      await loading;
      await saving;

      expect(repository.storedSettings.rounds, 8);
      expect(repository.storedSettings.roundTime, const Duration(seconds: 90));
    });
  });

  group('own templates', () {
    CustomTemplate own(String id, {String name = 'Mine', int rounds = 7}) => CustomTemplate(
          id: id,
          name: name,
          icon: CustomTemplateIcon.values.first,
          settings: repository.storedSettings.copyWith(rounds: rounds),
        );

    test('loads own templates with the settings', () async {
      templates.stored = [own('custom-2'), own('custom-1')];
      await viewModel.loadSettings();
      expect(viewModel.state.value.customTemplates, templates.stored);
    });

    test('own template load failure keeps settings', () async {
      templates.failLoad = true;
      await viewModel.loadSettings();
      expect(viewModel.state.value.customTemplates, isEmpty);
      expect(viewModel.state.value.status, SettingsStatus.loaded);
      expect(viewModel.state.value.timerSettings, repository.storedSettings);
    });

    test('restores a valid own selection only', () async {
      final template = own('custom-1');
      templates.stored = [template];
      repository.storedSettings = template.settings;
      repository.selectedTemplateId = 'custom-1';
      await viewModel.loadSettings();
      expect(viewModel.state.value.selectedCustomTemplate, template);
      expect(viewModel.state.value.selectedTemplateId, isNull);

      final different = SettingsViewModel(repository, templates);
      repository.storedSettings = template.settings.copyWith(rounds: 2);
      await different.loadSettings();
      expect(different.state.value.selectedCustomTemplate, isNull);
      expect(different.state.value.selectedTemplateId, isNull);
      different.dispose();

      final unknown = SettingsViewModel(repository, templates);
      repository.storedSettings = template.settings;
      repository.selectedTemplateId = 'custom-9';
      await unknown.loadSettings();
      expect(unknown.state.value.selectedCustomTemplate, isNull);
      expect(unknown.state.value.selectedTemplateId, isNull);
      unknown.dispose();
    });

    test('built-in selection still restores', () async {
      final builtIn = builtInTemplates.first;
      templates.stored = [own('custom-1')];
      repository.storedSettings = builtIn.settings;
      repository.selectedTemplateId = builtIn.id.name;
      await viewModel.loadSettings();
      expect(viewModel.state.value.selectedTemplateId, builtIn.id);
      expect(viewModel.state.value.selectedCustomTemplate, isNull);
    });

    test('selecting an own template saves its id', () async {
      final template = own('custom-1');
      templates.stored = [template];
      await viewModel.loadSettings();
      await viewModel.selectCustomTemplate(template);
      expect(viewModel.state.value.timerSettings, template.settings);
      expect(viewModel.state.value.selectedCustomTemplate, template);
      expect(repository.selectedTemplateId, 'custom-1');
      expect(repository.storedSettings, template.settings);
    });

    test('editing a setting clears the own selection', () async {
      final template = own('custom-1');
      templates.stored = [template];
      await viewModel.loadSettings();
      await viewModel.selectCustomTemplate(template);
      viewModel.updateRounds(template.settings.rounds + 1);
      await viewModel.flushSettings();
      expect(viewModel.state.value.selectedCustomTemplate, isNull);
      expect(repository.selectedTemplateId, isNull);
    });

    test('saving a new template appends it', () async {
      templates.stored = [own('custom-1')];
      await viewModel.loadSettings();
      final settingsBefore = viewModel.state.value.timerSettings;
      final added = own('custom-2');
      expect(await viewModel.saveCustomTemplate(added), isTrue);
      expect(viewModel.state.value.customTemplates.last, added);
      expect(viewModel.state.value.customTemplates, hasLength(2));
      expect(templates.stored, hasLength(2));
      expect(viewModel.state.value.timerSettings, settingsBefore);
    });

    test('editing keeps the position', () async {
      templates.stored = [own('custom-1'), own('custom-2')];
      await viewModel.loadSettings();
      final renamed = own('custom-1', name: 'Renamed');
      expect(await viewModel.saveCustomTemplate(renamed), isTrue);
      expect(viewModel.state.value.customTemplates, [renamed, templates.stored.last]);
      expect(templates.stored.first, renamed);
    });

    test('the 21st template is refused', () async {
      templates.stored = [for (var i = 0; i < CustomTemplate.maxCount; i++) own('custom-$i')];
      await viewModel.loadSettings();
      expect(await viewModel.saveCustomTemplate(own('custom-99')), isFalse);
      expect(templates.saveCalls, 0);
      expect(viewModel.state.value.customTemplates, hasLength(CustomTemplate.maxCount));
    });

    test('editing the selected template updates or clears the selection', () async {
      final template = own('custom-1');
      templates.stored = [template];
      await viewModel.loadSettings();
      await viewModel.selectCustomTemplate(template);

      final renamed = template.copyWith(name: 'New name');
      expect(await viewModel.saveCustomTemplate(renamed), isTrue);
      expect(viewModel.state.value.selectedCustomTemplate, renamed);

      final changed = renamed.copyWith(settings: renamed.settings.copyWith(rounds: 12));
      expect(await viewModel.saveCustomTemplate(changed), isTrue);
      expect(viewModel.state.value.selectedCustomTemplate, isNull);
      expect(viewModel.state.value.timerSettings, template.settings);
      expect(repository.selectedTemplateId, isNull);
    });

    test('deleting the selected template clears the selection', () async {
      final template = own('custom-1');
      templates.stored = [template];
      await viewModel.loadSettings();
      await viewModel.selectCustomTemplate(template);
      expect(await viewModel.deleteCustomTemplate('custom-1'), isTrue);
      expect(viewModel.state.value.customTemplates, isEmpty);
      expect(viewModel.state.value.selectedCustomTemplate, isNull);
      expect(viewModel.state.value.timerSettings, template.settings);
      expect(repository.selectedTemplateId, isNull);
      expect(await viewModel.deleteCustomTemplate('custom-404'), isTrue);
    });

    test('failed template write keeps the state', () async {
      final template = own('custom-1');
      templates.stored = [template];
      await viewModel.loadSettings();
      templates.failSave = true;
      expect(await viewModel.saveCustomTemplate(own('custom-2')), isFalse);
      expect(await viewModel.deleteCustomTemplate('custom-1'), isFalse);
      expect(viewModel.state.value.customTemplates, [template]);
    });

    test('no write after a failed load', () async {
      final template = own('custom-1');
      templates.stored = [template];
      templates.failLoad = true;
      await viewModel.loadSettings();
      expect(await viewModel.saveCustomTemplate(own('custom-2')), isFalse);
      expect(templates.saveCalls, 0);

      templates.failLoad = false;
      final added = own('custom-2');
      expect(await viewModel.saveCustomTemplate(added), isTrue);
      expect(templates.stored, [template, added]);
      expect(viewModel.state.value.customTemplates, [template, added]);
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
      final model = SettingsViewModel(repository, templates);
      final future = model.selectTimerStyle(TimerStyle.fullColor);
      model.dispose();

      await future;

      expect(repository.savedStyles, [TimerStyle.fullColor]);
    });
  });
}
