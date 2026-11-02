import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/settings/settings_state.dart';
import 'package:sport_timer/features/settings/settings_view_model.dart';
import 'package:sport_timer/features/settings/timer_style.dart';
import 'package:sport_timer/features/templates/built_in_templates.dart';
import 'package:sport_timer/features/templates/templates_state.dart';
import 'package:sport_timer/features/templates/templates_view_model.dart';
import 'package:sport_timer/features/templates/workout_template.dart';

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

  TimerSettings storedSettings = builtInTemplates.first.settings;
  final List<TimerSettings> savedSettings = [];
  Completer<void>? readGate;
  Completer<void>? saveGate;
  bool failSave = false;

  @override
  Future<Result<TimerSettings>> getTimerSettings() async {
    await readGate?.future;
    return Success(storedSettings);
  }

  @override
  Future<Result<void>> saveTimerSettings(TimerSettings settings) async {
    savedSettings.add(settings);
    await saveGate?.future;
    if (failSave) return Failure(Exception('save failed'));
    storedSettings = settings;
    return const Success(null);
  }

  @override
  Future<Result<TimerStyle>> getTimerStyle() async => const Success(TimerStyle.ring);

  @override
  Future<Result<void>> saveTimerStyle(TimerStyle style) async => const Success(null);
}

void main() {
  late _FakeSettingsRepository repository;
  late SettingsViewModel settings;
  late TemplatesViewModel templates;

  setUp(() {
    repository = _FakeSettingsRepository();
    settings = SettingsViewModel(repository);
    templates = TemplatesViewModel(settings);
  });

  tearDown(() {
    templates.dispose();
    settings.dispose();
  });

  group('TemplatesViewModel', () {
    test('starts with the matching default template', () {
      expect(templates.state.value.selectedTemplateId, TemplateId.standard);
      expect(templates.state.value.timerSettings, builtInTemplates.first.settings);
    });

    for (final template in builtInTemplates) {
      test('matches ${template.id.name} when settings are already loaded', () async {
        templates.dispose();
        repository.storedSettings = template.settings;
        await settings.loadSettings();
        templates = TemplatesViewModel(settings);

        expect(templates.state.value.selectedTemplateId, template.id);
        expect(templates.state.value.timerSettings, template.settings);
      });
    }

    test('tracks each changed field and matches again when restored', () async {
      await settings.loadSettings();
      final initial = builtInTemplates.first.settings;
      final changes = <TimerSettings>[
        initial.copyWith(preparationTime: initial.preparationTime + const Duration(seconds: 1)),
        initial.copyWith(roundTime: initial.roundTime + const Duration(seconds: 1)),
        initial.copyWith(restTime: initial.restTime + const Duration(seconds: 1)),
        initial.copyWith(rounds: initial.rounds + 1),
      ];

      for (final changed in changes) {
        await settings.saveSettings(changed);
        expect(templates.state.value.selectedTemplateId, isNull);
        expect(templates.state.value.timerSettings, changed);

        await settings.saveSettings(initial);
        expect(templates.state.value.selectedTemplateId, TemplateId.standard);
        expect(templates.state.value.timerSettings, initial);
      }
    });

    test('updates when a pending settings load finishes', () async {
      final gate = Completer<void>();
      repository.readGate = gate;
      repository.storedSettings = builtInTemplates[2].settings;
      final notifications = <TemplatesState>[];
      templates.state.addListener(() => notifications.add(templates.state.value));

      final loading = settings.loadSettings();
      expect(templates.state.value.selectedTemplateId, TemplateId.standard);
      gate.complete();
      await loading;

      expect(templates.state.value.selectedTemplateId, TemplateId.hyrox);
      expect(templates.state.value.timerSettings, repository.storedSettings);
      expect(notifications.map((state) => state.selectedTemplateId), [TemplateId.hyrox]);
    });

    test('updates immediately for a live settings edit', () async {
      await settings.loadSettings();
      settings.updateRounds(7);

      expect(templates.state.value.selectedTemplateId, isNull);
      expect(templates.state.value.timerSettings.rounds, 7);
    });

    test('applies and persists a template through shared settings', () async {
      await settings.loadSettings();
      final template = builtInTemplates[1];
      await templates.applyTemplate(template);

      expect(templates.state.value.selectedTemplateId, template.id);
      expect(settings.state.value.timerSettings, template.settings);
      expect(repository.savedSettings, [template.settings]);
      expect(repository.storedSettings, template.settings);
    });

    test('keeps current selection and exposes shared settings error on save failure', () async {
      await settings.loadSettings();
      repository.failSave = true;
      final template = builtInTemplates[1];
      await templates.applyTemplate(template);

      expect(templates.state.value.selectedTemplateId, template.id);
      expect(settings.state.value.status, SettingsStatus.error);
      expect(repository.storedSettings, builtInTemplates.first.settings);
      repository.failSave = false;
    });

    test('dispose stops listening without disposing shared settings', () async {
      await settings.loadSettings();
      var notifications = 0;
      templates.state.addListener(() => notifications++);
      templates.dispose();
      settings.updateRounds(7);
      await templates.applyTemplate(builtInTemplates[1]);

      expect(notifications, 0);
      expect(settings.state.value.timerSettings.rounds, 7);
      expect(repository.savedSettings, isEmpty);
    });

    test('pending load completes safely after disposal', () async {
      final gate = Completer<void>();
      repository.readGate = gate;
      repository.storedSettings = builtInTemplates[2].settings;
      var notifications = 0;
      templates.state.addListener(() => notifications++);
      final loading = settings.loadSettings();
      templates.dispose();
      gate.complete();
      await loading;

      expect(notifications, 0);
      expect(settings.state.value.timerSettings, builtInTemplates[2].settings);
    });

    test('pending apply completes safely after disposal', () async {
      await settings.loadSettings();
      final gate = Completer<void>();
      repository.saveGate = gate;
      var notifications = 0;
      templates.state.addListener(() => notifications++);
      final saving = templates.applyTemplate(builtInTemplates[1]);
      expect(notifications, 1);
      templates.dispose();
      gate.complete();
      await saving;

      expect(notifications, 1);
      expect(repository.storedSettings, builtInTemplates[1].settings);
      expect(settings.state.value.status, SettingsStatus.saved);
    });
  });

  test('TemplatesState equality and copyWith support clearing selection', () {
    final initial = TemplatesState(
      timerSettings: builtInTemplates.first.settings,
      selectedTemplateId: TemplateId.standard,
    );
    final same = initial.copyWith();
    final custom = initial.copyWith(selectedTemplateId: () => null);

    expect(same, initial);
    expect(same.hashCode, initial.hashCode);
    expect(custom.selectedTemplateId, isNull);
    expect(custom.timerSettings, initial.timerSettings);
    expect(custom, isNot(initial));
  });
}
