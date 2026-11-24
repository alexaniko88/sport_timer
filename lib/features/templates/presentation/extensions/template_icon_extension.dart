import 'package:flutter/material.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';

extension TemplateIcon on TemplateId {
  IconData get icon => switch (this) {
        TemplateId.standard => Icons.assignment,
        TemplateId.fullAbs => Icons.sports_gymnastics,
        TemplateId.hyrox => Icons.directions_run,
        TemplateId.stretching => Icons.self_improvement,
        TemplateId.strength => Icons.fitness_center,
      };
}
