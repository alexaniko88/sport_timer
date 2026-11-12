import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/templates/domain/custom_template.dart';
import 'package:sport_timer/features/templates/domain/custom_template_repository.dart';

class FakeCustomTemplateRepository implements CustomTemplateRepository {
  List<CustomTemplate> stored;
  bool failLoad;
  bool failSave;
  int saveCalls = 0;

  FakeCustomTemplateRepository({
    this.stored = const [],
    this.failLoad = false,
    this.failSave = false,
  });

  @override
  Future<Result<List<CustomTemplate>>> getTemplates() async {
    if (failLoad) return Failure(Exception('load failed'));
    return Success(List.of(stored));
  }

  @override
  Future<Result<void>> saveTemplates(List<CustomTemplate> templates) async {
    saveCalls++;
    if (failSave) return Failure(Exception('save failed'));
    stored = List.of(templates);
    return const Success(null);
  }
}
