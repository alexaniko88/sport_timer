/// The AI tools a runner can use.
enum Tool {
  claude('Claude'),
  codex('Codex'),
  antigravity('Antigravity');

  final String label;

  const Tool(this.label);

  static Tool? fromName(String name) => Tool.values.asNameMap()[name];
}

/// The stages of one task run, each with its own model.
enum Role {
  implementer,
  tests,
  reviewer,
}

/// A model and effort for one role.
class RoleModel {
  final String model;
  final String effort;
  final String displayName;

  const RoleModel({required this.model, required this.effort, required this.displayName});

  /// A model given on the command line, with the default effort.
  factory RoleModel.custom(String model) => RoleModel(model: model, effort: 'medium', displayName: model);

  /// The text after `Co-Authored-By:` in a commit made by [tool] with this model.
  String attribution(Tool tool) => '${tool.label} $displayName';
}

/// The fixed model of every role, per tool. Claude uses aliases, which always
/// point to the newest model of that family.
class RoleModels {
  static const _claudeWork = RoleModel(model: 'sonnet', effort: 'medium', displayName: 'Sonnet 5.5');
  static const _codexWork = RoleModel(model: 'gpt-6.1-terra', effort: 'medium', displayName: 'GPT-6.1 Terra');
  static const _antigravityWork = RoleModel(
    model: 'gemini-4-argon-medium',
    effort: 'medium',
    displayName: 'Gemini 4 Argon',
  );

  static const Map<Tool, Map<Role, RoleModel>> table = {
    Tool.claude: {
      Role.implementer: _claudeWork,
      Role.tests: _claudeWork,
      Role.reviewer: RoleModel(model: 'opus', effort: 'medium', displayName: 'Opus 5.5'),
    },
    Tool.codex: {
      Role.implementer: _codexWork,
      Role.tests: _codexWork,
      Role.reviewer: RoleModel(model: 'gpt-6.1-sol', effort: 'medium', displayName: 'GPT-6.1 Sol'),
    },
    Tool.antigravity: {
      Role.implementer: _antigravityWork,
      Role.tests: _antigravityWork,
      Role.reviewer: RoleModel(model: 'gemini-4-argon-high', effort: 'high', displayName: 'Gemini 4 Argon'),
    },
  };

  /// The model of [role] for [tool], unless [overrides] gives another.
  static RoleModel of({
    required Tool tool,
    required Role role,
    Map<Role, String> overrides = const {},
  }) {
    if (overrides[role] case final model?) return RoleModel.custom(model);
    return table[tool]?[role] ?? _claudeWork;
  }
}
