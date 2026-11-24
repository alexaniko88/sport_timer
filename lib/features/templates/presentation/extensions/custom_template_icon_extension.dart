import 'package:flutter/material.dart';
import 'package:sport_timer/features/templates/domain/custom_template_icon.dart';

extension CustomTemplateIconData on CustomTemplateIcon {
  IconData get iconData => switch (this) {
        CustomTemplateIcon.weights => Icons.fitness_center,
        CustomTemplateIcon.running => Icons.directions_run,
        CustomTemplateIcon.cycling => Icons.directions_bike,
        CustomTemplateIcon.swimming => Icons.pool,
        CustomTemplateIcon.martialArts => Icons.sports_martial_arts,
        CustomTemplateIcon.gymnastics => Icons.sports_gymnastics,
        CustomTemplateIcon.yoga => Icons.self_improvement,
        CustomTemplateIcon.timer => Icons.timer,
      };
}
