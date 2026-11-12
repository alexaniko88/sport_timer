import 'package:sport_timer/features/templates/domain/custom_template.dart';

extension CustomTemplateListIds on List<CustomTemplate> {
  static const String _prefix = 'custom-';

  /// `custom-<n>`, where n is 1 plus the highest number among the ids that parse.
  String get nextId {
    var highest = 0;
    for (final template in this) {
      if (!template.id.startsWith(_prefix)) continue;
      final number = int.tryParse(template.id.substring(_prefix.length));
      if (number != null && number > highest) highest = number;
    }
    return '$_prefix${highest + 1}';
  }
}
