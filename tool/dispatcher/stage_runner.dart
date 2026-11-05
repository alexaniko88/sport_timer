import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'role_models.dart';
import 'tool_command.dart';

/// The raw outcome of one tool process.
class ProcessOutcome {
  final int exitCode;
  final String stdout;
  final String stderr;
  final bool timedOut;

  const ProcessOutcome({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.timedOut = false,
  });
}

/// Starts one tool process. Tests pass a fake.
typedef RunProcess = Future<ProcessOutcome> Function(
  ToolInvocation invocation, {
  required String workingDirectory,
  required Duration timeout,
});

Future<ProcessOutcome> runToolProcess(
  ToolInvocation invocation, {
  required String workingDirectory,
  required Duration timeout,
}) async {
  final process = await Process.start(
    invocation.executable,
    invocation.args,
    workingDirectory: workingDirectory,
  );
  final out = StringBuffer();
  final err = StringBuffer();
  final done = Future.wait([
    process.stdout.transform(utf8.decoder).forEach(out.write),
    process.stderr.transform(utf8.decoder).forEach(err.write),
  ]);
  var timedOut = false;
  final timer = Timer(timeout, () {
    timedOut = true;
    process.kill();
  });
  final code = await process.exitCode;
  timer.cancel();
  await done;
  return ProcessOutcome(exitCode: code, stdout: '$out', stderr: '$err', timedOut: timedOut);
}

/// What one stage returned.
class StageResult {
  final bool ok;
  final String message;
  final List<String> deniedCommands;
  final String tail;
  final bool timedOut;

  const StageResult({
    required this.ok,
    required this.message,
    required this.deniedCommands,
    required this.tail,
    required this.timedOut,
  });
}

/// Runs one stage of a task (a role with its model) and reads its final answer.
class StageRunner {
  final RunProcess run;
  final Duration timeout;

  const StageRunner({this.run = runToolProcess, this.timeout = const Duration(minutes: 45)});

  /// The fixed brief of every stage: the role file tells what to read and do.
  static String prompt({
    required Role role,
    required String taskPath,
    String extra = '',
  }) {
    final roleFile = '.agents/skills/skill-dispatcher/roles/${role.name}.md';
    final lines = [
      'Read $roleFile and follow it exactly.',
      'The task is $taskPath.',
      if (extra.isNotEmpty) extra,
      'Your final message is your report, in the format the role file asks for.',
    ];
    return lines.join(' ');
  }

  Future<StageResult> runStage({
    required Tool tool,
    required Role role,
    required RoleModel model,
    required String workspace,
    required String prompt,
    required String lastMessageFile,
    List<String> extraAllowed = const [],
  }) async {
    final invocation = ToolCommand.build(
      tool: tool,
      role: role,
      model: model,
      prompt: prompt,
      lastMessageFile: lastMessageFile,
      extraAllowed: extraAllowed,
    );
    final outcome = await run(invocation, workingDirectory: workspace, timeout: timeout);
    final message = _finalMessage(tool: tool, invocation: invocation, outcome: outcome);
    return StageResult(
      ok: outcome.exitCode == 0 && !outcome.timedOut,
      message: message,
      deniedCommands: tool == Tool.claude ? _claudeDenials(outcome.stdout) : const [],
      tail: _tail('${outcome.stdout}\n${outcome.stderr}'),
      timedOut: outcome.timedOut,
    );
  }

  static String _finalMessage({
    required Tool tool,
    required ToolInvocation invocation,
    required ProcessOutcome outcome,
  }) {
    switch (tool) {
      case Tool.claude:
        try {
          if (jsonDecode(outcome.stdout) case {'result': final String result}) return result;
        } on FormatException {
          return '';
        }
        return '';
      case Tool.codex:
        final file = invocation.lastMessageFile;
        if (file != null && File(file).existsSync()) return File(file).readAsStringSync();
        return '';
      case Tool.antigravity:
        return outcome.stdout;
    }
  }

  static List<String> _claudeDenials(String stdout) {
    try {
      if (jsonDecode(stdout) case {'permission_denials': final List<Object?> denials}) {
        return [
          for (final denial in denials)
            if (denial case {'tool_input': {'command': final String command}}) command,
        ];
      }
    } on FormatException {
      return const [];
    }
    return const [];
  }

  static String _tail(String text) {
    final lines = text.trim().split('\n');
    return lines.skip(lines.length > 50 ? lines.length - 50 : 0).join('\n');
  }
}
