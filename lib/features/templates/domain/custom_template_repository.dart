import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/templates/domain/custom_template.dart';

abstract interface class CustomTemplateRepository {
  Future<Result<List<CustomTemplate>>> getTemplates();

  /// Replaces the whole stored list, in order.
  Future<Result<void>> saveTemplates(List<CustomTemplate> templates);
}
