// Picks project tasks and runs them with an AI tool, one clean clone per task.
//
//   fvm dart tool/dispatcher.dart next [--skip=ID,ID]
//   fvm dart tool/dispatcher.dart models
//   fvm dart tool/dispatcher.dart launch <ID> --tool=claude|codex|antigravity
//       [--implementer=MODEL] [--tests=MODEL] [--reviewer=MODEL] [--allow=PATTERN,PATTERN]
//   fvm dart tool/dispatcher.dart status
//
// The rules of each part live in tool/dispatcher/ and are unit tested there.
// `launch` runs until the task ends (PR opened, blocked or failed) and prints
// one line `RESULT {json}` at the end.
import 'dart:convert';
import 'dart:io';

import 'dispatcher/command_runner.dart';
import 'dispatcher/extensions/command_options.dart';
import 'dispatcher/launch_pipeline.dart';
import 'dispatcher/model_catalog.dart';
import 'dispatcher/role_models.dart';
import 'dispatcher/run_workspace.dart';
import 'dispatcher/stage_runner.dart';
import 'dispatcher/task.dart';
import 'dispatcher/task_loader.dart';
import 'dispatcher/task_selector.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _usage();
    exit(64);
  }
  final rest = args.skip(1).toList();
  final code = switch (args.first) {
    'next' => await _next(rest),
    'models' => await _models(),
    'launch' => await _launch(rest),
    'status' => await _status(),
    _ => _usage(),
  };
  exit(code);
}

int _usage() {
  stderr.writeln('Usage: fvm dart tool/dispatcher.dart next | models | launch <ID> --tool=<tool> | status');
  return 64;
}

Future<String> _output(String executable, List<String> args) async {
  final result = await runSystemCommand(executable, args);
  return result.ok ? result.stdout.trim() : '';
}

Future<List<Task>> _tasksOnMaster() async {
  await runSystemCommand('git', ['fetch', 'origin', 'master', '--quiet']);
  return TaskLoader.fromGit(ref: 'origin/master', run: runSystemCommand).load();
}

/// The branches on the remote and the heads of the open PRs.
Future<List<String>> _branchNames() async {
  final remote = await _output('git', ['ls-remote', '--heads', 'origin']);
  final names = [
    for (final line in remote.split('\n'))
      if (line.contains('refs/heads/')) line.split('refs/heads/').last.trim(),
  ];
  final pulls =
      await _output('gh', ['pr', 'list', '--state', 'open', '--json', 'headRefName', '--jq', '.[].headRefName']);
  return [...names, ...pulls.split('\n').where((name) => name.isNotEmpty)];
}

Map<String, Object?> _taskJson(Task task) => {
      'id': task.id,
      'title': task.title,
      'path': task.indexPath,
      'type': task.type,
      'complexity': task.complexity,
      'dependsOn': task.dependsOn,
      'touches': task.touches,
      'skills': task.skills,
      'branch': task.branch,
    };

Future<int> _next(List<String> args) async {
  final tasks = await _tasksOnMaster();
  final busy = {
    ...TaskSelector.busyIdsFromBranches(tasks: tasks, branches: await _branchNames()),
    for (final run in await _runs())
      if (run['running'] == true && run['taskId'] is String) run['taskId'] as String,
  };
  final selector = TaskSelector(tasks: tasks, busyIds: busy);
  final skipped = (args.options['skip'] ?? '').split(',').where((id) => id.isNotEmpty).toSet();
  final candidates = selector.candidates(skipped: skipped);
  final waiting = {
    for (final task in tasks)
      if (task.isReady && !candidates.contains(task)) task.id: selector.blockReason(task, skipped: skipped),
  };
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'next': candidates.isEmpty ? null : _taskJson(candidates.first),
      'alsoReady': [for (final task in candidates.skip(1)) task.id],
      'waiting': waiting,
    }),
  );
  return 0;
}

Future<int> _models() async {
  final catalogs = {
    Tool.codex: ModelCatalog.parseCodex(await _output('codex', ['debug', 'models'])),
    Tool.antigravity: ModelCatalog.parseAntigravity(await _output('agy', ['models'])),
  };
  for (final tool in Tool.values) {
    stdout.writeln('\n${tool.label}');
    final models = catalogs[tool];
    if (models == null) {
      stdout.writeln('  aliases: sonnet, opus (always the newest model of that family)');
    } else {
      for (final model in ModelCatalog.latestPerFamily(models)) {
        stdout.writeln('  newest: ${model.id}');
      }
      for (final stale in ModelCatalog.staleModels(tool: tool, models: models)) {
        stdout.writeln('  WARNING: fixed model is missing or old: $stale');
      }
    }
    for (final role in Role.values) {
      final model = RoleModels.of(tool: tool, role: role);
      stdout.writeln('  ${role.name}: ${model.model} (${model.effort})');
    }
  }
  return 0;
}

Future<int> _launch(List<String> args) async {
  final options = args.options;
  final ids = args.positional;
  final tool = Tool.fromName(options['tool'] ?? '');
  if (ids.length != 1 || tool == null) return _usage();

  final tasks = await _tasksOnMaster();
  final task = tasks.where((candidate) => candidate.id == ids.first).firstOrNull;
  if (task == null || !task.isReady) {
    stderr.writeln('${ids.first} is not a ready task on origin/master.');
    return 1;
  }
  final pipeline = LaunchPipeline(
    tool: tool,
    stages: const StageRunner(),
    run: runSystemCommand,
    originUrl: await _output('git', ['remote', 'get-url', 'origin']),
    email: await _output('git', ['config', 'user.email']),
    name: await _output('git', ['config', 'user.name']),
    baseDirectory: RunWorkspace.baseDirectory(),
    overrides: {
      for (final role in Role.values)
        if (options[role.name] case final model?) role: model,
    },
    extraAllowed: (options['allow'] ?? '').split(',').where((pattern) => pattern.isNotEmpty).toList(),
    log: (line) => stdout.writeln('[${DateTime.now().toIso8601String()}] $line'),
  );
  final result = await pipeline.launch(task);
  stdout.writeln('RESULT ${jsonEncode(result.toJson())}');
  return switch (result.outcome) {
    RunOutcome.pullRequest => 0,
    RunOutcome.blocked => 2,
    RunOutcome.failed => 1,
  };
}

/// The runs that left a state file, and whether their process is alive.
Future<List<Map<String, Object?>>> _runs() async {
  final runs = <Map<String, Object?>>[];
  final base = Directory(RunWorkspace.baseDirectory());
  if (!base.existsSync()) return runs;
  for (final entity in base.listSync()) {
    final state = File('${entity.path}/state.json');
    if (!state.existsSync()) continue;
    if (jsonDecode(state.readAsStringSync()) case {'pid': final int pid} && final Map<String, Object?> data) {
      final alive = (await runSystemCommand('kill', ['-0', '$pid'])).ok;
      runs.add({...data, 'running': alive, 'workspace': '${entity.path}/repo'});
    }
  }
  return runs;
}

Future<int> _status() async {
  stdout.writeln(const JsonEncoder.withIndent('  ').convert({'runs': await _runs()}));
  return 0;
}
