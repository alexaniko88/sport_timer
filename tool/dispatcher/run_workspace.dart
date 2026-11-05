import 'dart:convert';
import 'dart:io';

import 'command_runner.dart';
import 'task.dart';

/// The temporary clone one task run works in. It lives in the system temp
/// folder and is deleted when the task ends.
class RunWorkspace {
  /// The folder of the run: `<temp>/sport-timer-runs/<task id>`.
  final String root;

  const RunWorkspace(this.root);

  /// The clone itself.
  String get directory => '$root/repo';

  /// Reports and scratch files; excluded from git.
  String get runnerDirectory => '$directory/.runner';

  String get stateFile => '$root/state.json';

  /// Where every run lives.
  static String baseDirectory() => '${Directory.systemTemp.path}/sport-timer-runs';

  /// Clones `master`, creates (or continues) the task branch and prepares the
  /// clone for work. Throws a [StateError] with a readable message on failure.
  static Future<RunWorkspace> prepare({
    required RunCommand run,
    required Task task,
    required String originUrl,
    required String email,
    required String name,
    required String baseDirectory,
    bool skipPubGet = false,
  }) async {
    if (!email.endsWith('@users.noreply.github.com')) {
      throw StateError('The git email "$email" is not the repo noreply email.');
    }
    final workspace = RunWorkspace('$baseDirectory/${task.id}');
    if (Directory(workspace.root).existsSync()) {
      throw StateError('A run for ${task.id} already exists at ${workspace.root}.');
    }
    Directory(workspace.root).createSync(recursive: true);

    Future<void> step(String executable, List<String> args, {String? inside}) async {
      final result = await run(executable, args, workingDirectory: inside ?? workspace.root);
      if (!result.ok) {
        throw StateError('"$executable ${args.join(' ')}" failed: ${result.stderr.trim()}');
      }
    }

    try {
      await step('git', ['clone', '--quiet', '--depth', '1', '--branch', 'master', originUrl, 'repo']);
      final remote =
          await run('git', ['ls-remote', '--heads', 'origin', task.branch], workingDirectory: workspace.directory);
      if (remote.ok && remote.stdout.trim().isNotEmpty) {
        await step('git', ['fetch', '--quiet', '--depth', '1', 'origin', task.branch], inside: workspace.directory);
        await step('git', ['checkout', '--quiet', '-b', task.branch, 'FETCH_HEAD'], inside: workspace.directory);
      } else {
        await step('git', ['checkout', '--quiet', '-b', task.branch], inside: workspace.directory);
      }
      await step('git', ['config', 'user.email', email], inside: workspace.directory);
      await step('git', ['config', 'user.name', name], inside: workspace.directory);
      File('${workspace.directory}/.git/info/exclude').writeAsStringSync('.runner/\n', mode: FileMode.append);
      Directory(workspace.runnerDirectory).createSync();
      if (!skipPubGet) await step('fvm', ['flutter', 'pub', 'get'], inside: workspace.directory);
    } on StateError {
      workspace.cleanup();
      rethrow;
    }
    return workspace;
  }

  /// Records which stage is running, for the `status` command.
  void writeState({required String taskId, required String tool, required String stage}) {
    File(stateFile).writeAsStringSync(
      jsonEncode({
        'taskId': taskId,
        'tool': tool,
        'stage': stage,
        'pid': pid,
        'updated': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// Deletes the clone and its state.
  void cleanup() {
    final folder = Directory(root);
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  }
}
