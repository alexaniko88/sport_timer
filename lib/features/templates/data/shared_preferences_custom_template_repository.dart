import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/templates/domain/custom_template.dart';
import 'package:sport_timer/features/templates/domain/custom_template_icon.dart';
import 'package:sport_timer/features/templates/domain/custom_template_repository.dart';

class SharedPreferencesCustomTemplateRepository implements CustomTemplateRepository {
  static const String _templatesKey = 'custom_templates';

  bool _hasFailedWrite = false;

  @override
  Future<Result<List<CustomTemplate>>> getTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // A failed platform write can still change the shared in-memory cache.
      await prefs.reload();
      final raw = prefs.getString(_templatesKey);
      if (raw == null) return const Success([]);
      final entries = jsonDecode(raw) as List<dynamic>;
      return Success([for (final entry in entries) _decode(entry as Map<String, dynamic>)]);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveTemplates(List<CustomTemplate> templates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final encoded = jsonEncode([for (final template in templates) _encode(template)]);
      if (!_hasFailedWrite && prefs.getString(_templatesKey) == encoded) {
        return const Success(null);
      }
      _hasFailedWrite = true;
      if (!await prefs.setString(_templatesKey, encoded)) {
        return Failure(Exception('Could not save custom templates'));
      }
      _hasFailedWrite = false;
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  CustomTemplate _decode(Map<String, dynamic> data) {
    return CustomTemplate(
      id: data['id'] as String,
      name: data['name'] as String,
      // An unknown icon name falls back to the default icon.
      icon: CustomTemplateIcon.values.asNameMap()[data['icon']] ?? CustomTemplateIcon.weights,
      settings: TimerSettings(
        preparationTime: Duration(seconds: data['preparation'] as int),
        roundTime: Duration(seconds: data['round'] as int),
        restTime: Duration(seconds: data['rest'] as int),
        rounds: (data['rounds'] as int).clamp(1, TimerSettings.maxRounds),
      ),
    );
  }

  Map<String, dynamic> _encode(CustomTemplate template) {
    final settings = template.settings;
    return {
      'id': template.id,
      'name': template.name,
      'icon': template.icon.name,
      'preparation': settings.preparationTime.inSeconds,
      'round': settings.roundTime.inSeconds,
      'rest': settings.restTime.inSeconds,
      'rounds': settings.rounds,
    };
  }
}
