import 'role_models.dart';

/// A command line to run, and where to find the final answer of the run.
class ToolInvocation {
  final String executable;
  final List<String> args;

  /// A file the tool writes its last message to, or null when the answer is
  /// printed (Claude prints JSON, Antigravity prints text).
  final String? lastMessageFile;

  const ToolInvocation({required this.executable, required this.args, this.lastMessageFile});
}

/// Builds the command of one stage for each tool. Every tool runs in its own
/// sandbox with the user settings off, edits files and runs checks, but never
/// writes to git: the script does that.
class ToolCommand {
  static const _readOnlyShell = [
    'Bash(git status:*)',
    'Bash(git diff:*)',
    'Bash(git log:*)',
    'Bash(git show:*)',
    'Bash(ls:*)',
    'Bash(cat:*)',
    'Bash(grep:*)',
    'Bash(rg:*)',
  ];

  /// Harmless helpers that only touch files inside the clone. `git` writes and
  /// `python3` stay out on purpose: the script owns the git work, and a script
  /// interpreter can run anything. They remain available through `--allow`.
  static const _fileShell = [
    'Bash(head:*)',
    'Bash(tail:*)',
    'Bash(wc:*)',
    'Bash(sort:*)',
    'Bash(diff:*)',
    'Bash(mkdir:*)',
  ];

  static const _checkShell = [
    'Bash(fvm dart format:*)',
    'Bash(fvm flutter analyze:*)',
    'Bash(fvm flutter test:*)',
    'Bash(fvm flutter gen-l10n:*)',
    'Bash(fvm flutter pub get:*)',
    'Bash(fvm dart tool/agent_check.dart:*)',
  ];

  static ToolInvocation build({
    required Tool tool,
    required Role role,
    required RoleModel model,
    required String prompt,
    required String lastMessageFile,
    List<String> extraAllowed = const [],
    String timeout = '45m',
  }) {
    final isReadOnly = role == Role.reviewer;
    return switch (tool) {
      Tool.claude => ToolInvocation(
          executable: 'claude',
          args: [
            '-p',
            '--model',
            model.model,
            '--effort',
            model.effort,
            '--setting-sources',
            'project',
            '--permission-prompts',
            'none',
            '--no-session-persistence',
            '--permission-mode',
            isReadOnly ? 'plan' : 'acceptEdits',
            '--allowedTools',
            ..._readOnlyShell,
            if (!isReadOnly) ..._checkShell,
            if (!isReadOnly) ..._fileShell,
            ...extraAllowed,
            '--output-format',
            'json',
            '--',
            prompt,
          ],
        ),
      Tool.codex => ToolInvocation(
          executable: 'codex',
          args: [
            'exec',
            '--ignore-user-config',
            '--ephemeral',
            '-s',
            isReadOnly ? 'read-only' : 'workspace-write',
            '-m',
            model.model,
            '-c',
            'model_reasoning_effort="${model.effort}"',
            '-o',
            lastMessageFile,
            prompt,
          ],
          lastMessageFile: lastMessageFile,
        ),
      Tool.antigravity => ToolInvocation(
          executable: 'agy',
          args: [
            '--sandbox',
            '--mode',
            isReadOnly ? 'plan' : 'accept-edits',
            '--model',
            model.model,
            '--print-timeout',
            timeout,
            '-p=$prompt',
          ],
        ),
    };
  }
}
