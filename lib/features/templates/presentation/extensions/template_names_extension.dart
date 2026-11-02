import 'package:sport_timer/features/templates/domain/workout_template.dart';
import 'package:sport_timer/l10n/app_localizations.dart';

extension TemplateNames on AppLocalizations {
  String templateName(TemplateId id) => switch (id) {
        TemplateId.standard => templateDefaultName,
        TemplateId.fullAbs => templateAbsName,
        TemplateId.hyrox => templateHyroxName,
        TemplateId.stretching => templateStretchingName,
        TemplateId.strength => templateStrengthName,
      };
}
