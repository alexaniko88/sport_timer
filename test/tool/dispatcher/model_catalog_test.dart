// Checks how the model lists of Codex and Antigravity are read.
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/dispatcher/model_catalog.dart';
import '../../../tool/dispatcher/role_models.dart';

const _codex = '''
{"models": [
  {"slug": "gpt-6.1-sol", "visibility": "list"},
  {"slug": "gpt-6-astra", "visibility": "list"},
  {"slug": "gpt-6.1-terra", "visibility": "list"},
  {"slug": "gpt-6-sol", "visibility": "list"},
  {"slug": "gpt-reserve", "visibility": "hide"},
  {"slug": "gpt-5.6-terra", "visibility": "list"},
  {"slug": "gpt-6-luna", "visibility": "list"}
]}
''';

const _agy = '''
Fetching available models...
gemini-4-argon-medium\tGemini 4 Argon (Medium)
gemini-4-argon-high\tGemini 4 Argon (High)
gemini-3.8-flash-high\tGemini 3.8 Flash (High)
claude-opus-5-5-low\tClaude Opus 5.5 (Low)
claude-opus-5-5-medium\tClaude Opus 5.5 (Medium)
claude-opus-4-6-medium\tClaude Opus 4.6 (Medium)
gpt-oss-120b-medium\tGPT-OSS 120B (Medium)
''';

void main() {
  group('ModelCatalog', () {
    test('keeps the visible Codex models and the newest of each family', () {
      final models = ModelCatalog.parseCodex(_codex);
      final latest = ModelCatalog.latestPerFamily(models).map((model) => model.id);

      expect(models.length, 6);
      expect(latest, unorderedEquals(['gpt-6.1-sol', 'gpt-6-astra', 'gpt-6.1-terra', 'gpt-6-luna']));
    });

    test('keeps every effort of the newest Antigravity version', () {
      final latest = ModelCatalog.latestPerFamily(ModelCatalog.parseAntigravity(_agy)).map((model) => model.id);

      expect(
        latest,
        unorderedEquals([
          'gemini-4-argon-medium',
          'gemini-4-argon-high',
          'gemini-3.8-flash-high',
          'claude-opus-5-5-low',
          'claude-opus-5-5-medium',
        ]),
      );
    });

    test('a broken Codex answer gives no models', () {
      expect(ModelCatalog.parseCodex('not json'), isEmpty);
    });

    test('the fixed models are current in the sample catalogs', () {
      expect(ModelCatalog.staleModels(tool: Tool.codex, models: ModelCatalog.parseCodex(_codex)), isEmpty);
      expect(ModelCatalog.staleModels(tool: Tool.antigravity, models: ModelCatalog.parseAntigravity(_agy)), isEmpty);
    });

    test('a fixed model with a newer version in the catalog is reported', () {
      final models = ModelCatalog.parseCodex('{"models":[{"slug":"gpt-6.2-terra","visibility":"list"},'
          '{"slug":"gpt-6.1-terra","visibility":"list"},{"slug":"gpt-6.1-sol","visibility":"list"}]}');

      expect(
        ModelCatalog.staleModels(tool: Tool.codex, models: models),
        ['implementer: gpt-6.1-terra', 'tests: gpt-6.1-terra'],
      );
    });

    test('Claude has no catalog and is never reported', () {
      expect(ModelCatalog.staleModels(tool: Tool.claude, models: const []), isEmpty);
    });
  });

  group('RoleModels', () {
    test('uses the fixed table and the attribution names the tool and model', () {
      final reviewer = RoleModels.of(tool: Tool.claude, role: Role.reviewer);

      expect(reviewer.model, 'opus');
      expect(reviewer.attribution(Tool.claude), 'Claude Opus 5.5');
    });

    test('a command line override replaces one role only', () {
      final overrides = {Role.tests: 'gpt-6-luna'};

      expect(RoleModels.of(tool: Tool.codex, role: Role.tests, overrides: overrides).model, 'gpt-6-luna');
      expect(RoleModels.of(tool: Tool.codex, role: Role.implementer, overrides: overrides).model, 'gpt-6.1-terra');
    });
  });
}
