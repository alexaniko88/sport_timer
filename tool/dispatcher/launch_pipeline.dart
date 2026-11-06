import 'dart:io';

import 'command_runner.dart';
import 'extensions/repo_url.dart';
import 'extensions/text_case.dart';
import 'git_publisher.dart';
import 'pr_description.dart';
import 'review_gate.dart';
import 'role_models.dart';
import 'run_workspace.dart';
import 'stage_report.dart';
import 'stage_runner.dart';
import 'task.dart';
import 'task_archiver.dart';

typedef LogLine = void Function(String line);

/// How a task run ended.
enum RunOutcome {
  pullRequest,
  blocked,
  failed,
}

/// The final answer of a run, printed by the `launch` command as JSON.
class RunResult {
  final String taskId;
  final RunOutcome outcome;
  final String? prUrl;
  final String? message;
  final String? tail;

  /// Set only when the clone was kept because its work could not be pushed.
  final String? keptWorkspace;

  const RunResult({
    required this.taskId,
    required this.outcome,
    this.prUrl,
    this.message,
    this.tail,
    this.keptWorkspace,
  });

  Map<String, Object?> toJson() => {
        'taskId': taskId,
        'outcome': outcome.name,
        'prUrl': prUrl,
        'message': message,
        'tail': tail,
        'keptWorkspace': keptWorkspace,
      };
}

class _Stop {
  final RunOutcome outcome;
  final String message;
  final String? tail;

  const _Stop(this.outcome, this.message, {this.tail});
}

class _Session {
  final Task task;
  final RunWorkspace workspace;
  final GitPublisher publisher;
  final Map<Role, RoleModel> models = {};
  StageReport? implementer;
  StageReport? tests;
  List<ReviewFinding> reviewNotes = const [];
  String checkResult = '';

  /// Commands the tool refused to run. They no longer stop the run: the stage
  /// goes on with another way, and the list is shown in the PR or the notes.
  final Set<String> deniedCommands = {};

  _Session({required this.task, required this.workspace, required this.publisher});
}

typedef _StageStep = ({_Stop? stop, String message});

/// Runs one task from a clean clone to an open PR: implementer, tests, the
/// project checks, review rounds, closing the task, and the push. Every stage
/// is a separate run of the chosen tool with its own model. Anything that
/// cannot go on ends as a `wip:` commit on the task branch and a question.
class LaunchPipeline {
  final Tool tool;
  final Map<Role, String> overrides;
  final List<String> extraAllowed;
  final StageRunner stages;
  final RunCommand run;
  final String originUrl;
  final String email;
  final String name;
  final String baseDirectory;
  final bool skipFlutterSetup;
  final LogLine log;

  const LaunchPipeline({
    required this.tool,
    required this.stages,
    required this.run,
    required this.originUrl,
    required this.email,
    required this.name,
    required this.baseDirectory,
    required this.log,
    this.overrides = const {},
    this.extraAllowed = const [],
    this.skipFlutterSetup = false,
  });

  Future<RunResult> launch(Task task) async {
    final RunWorkspace workspace;
    try {
      workspace = await RunWorkspace.prepare(
        run: run,
        task: task,
        originUrl: originUrl,
        email: email,
        name: name,
        tool: tool.name,
        baseDirectory: baseDirectory,
        skipFlutterSetup: skipFlutterSetup,
      );
    } on StateError catch (error) {
      return RunResult(taskId: task.id, outcome: RunOutcome.failed, message: error.message);
    } catch (error, stack) {
      log('$stack');
      return RunResult(taskId: task.id, outcome: RunOutcome.failed, message: 'Could not prepare the clone: $error');
    }
    final session = _Session(
      task: task,
      workspace: workspace,
      publisher: GitPublisher(workspace: workspace.directory, run: run),
    );
    final _Stop? stop;
    try {
      stop = await _work(session);
    } catch (error, stack) {
      log('$stack');
      return _safeAbandon(session, _Stop(RunOutcome.failed, 'Unexpected error: $error'));
    }
    if (stop != null) return _safeAbandon(session, stop);
    try {
      return await _publish(session);
    } catch (error, stack) {
      log('$stack');
      return _keep(session, 'Unexpected error: $error');
    }
  }

  /// Like [_abandon], but keeps the clone when abandoning itself fails.
  Future<RunResult> _safeAbandon(_Session session, _Stop stop) async {
    try {
      return await _abandon(session, stop);
    } catch (error, stack) {
      log('$stack');
      return _keep(session, '${stop.message} (Unexpected error: $error)');
    }
  }

  Future<_Stop?> _work(_Session session) async {
    var step = await _stage(session, Role.implementer);
    if (step.stop case final stop?) return stop;
    final implementer = StageReport.parse(step.message);
    if (implementer.isBlocked) return _Stop(RunOutcome.blocked, implementer.blocked);
    session.implementer = implementer;
    if (await _commit(session, implementer, Role.implementer) case final stop?) return stop;

    step = await _stage(session, Role.tests);
    if (step.stop case final stop?) return stop;
    final tests = StageReport.parse(step.message);
    if (tests.isBlocked) return _Stop(RunOutcome.blocked, tests.blocked);
    session.tests = tests;
    if (await _commit(session, tests, Role.tests) case final stop?) return stop;

    if (await _fixChecks(session) case final stop?) return stop;

    for (var round = 1;; round++) {
      step = await _stage(session, Role.reviewer, extra: 'Review the diff of this branch against master.');
      if (step.stop case final stop?) return stop;
      final findings = ReviewGate.parse(step.message);
      if (findings == null) {
        return const _Stop(RunOutcome.failed, 'The reviewer did not return a findings block.');
      }
      switch (ReviewGate.decide(round: round, findings: findings)) {
        case ReviewDecision.pass:
          session.reviewNotes = ReviewGate.notes(findings);
          return null;
        case ReviewDecision.blocked:
          final list = findings
              .where((finding) => finding.severity != Severity.minor)
              .map((finding) => '- ${finding.location}: ${finding.summary}');
          return _Stop(RunOutcome.blocked, 'Review still has findings after $round rounds:\n${list.join('\n')}');
        case ReviewDecision.fix:
          final list = findings
              .where((finding) => finding.severity != Severity.minor)
              .map((finding) => '- ${finding.location}: ${finding.summary} Fix: ${finding.fix}');
          final fix =
              await _stage(session, Role.implementer, extra: 'Fix only these review findings:\n${list.join('\n')}');
          if (fix.stop case final stop?) return stop;
          final report = StageReport.parse(fix.message);
          if (report.isBlocked) return _Stop(RunOutcome.blocked, report.blocked);
          if (await _commit(session, report, Role.implementer) case final stop?) return stop;
          if (await _fixChecks(session) case final stop?) return stop;
      }
    }
  }

  Future<_StageStep> _stage(_Session session, Role role, {String extra = ''}) async {
    final model = RoleModels.of(tool: tool, role: role, overrides: overrides);
    session.models[role] = model;
    log('stage ${role.name}: ${model.model}');
    session.workspace.writeState(taskId: session.task.id, tool: tool.name, stage: role.name);
    final result = await stages.runStage(
      tool: tool,
      role: role,
      model: model,
      workspace: session.workspace.directory,
      prompt: StageRunner.prompt(role: role, taskPath: session.task.indexPath, extra: extra),
      lastMessageFile: '${session.workspace.runnerDirectory}/${role.name}-last.txt',
      extraAllowed: extraAllowed,
    );
    session.deniedCommands.addAll(result.deniedCommands);
    if (result.timedOut) {
      return (stop: _Stop(RunOutcome.failed, 'The ${role.name} stage timed out.', tail: result.tail), message: '');
    }
    if (!result.ok) {
      return (stop: _Stop(RunOutcome.failed, 'The ${role.name} stage failed.', tail: result.tail), message: '');
    }
    return (stop: null, message: result.message);
  }

  Future<_Stop?> _commit(_Session session, StageReport report, Role role) async {
    final problem = CommitMessage.problem(report.commit);
    if (problem != null) return _Stop(RunOutcome.failed, problem);
    final trailer = 'Co-Authored-By: ${session.models[role]?.attribution(tool) ?? tool.label}';
    final error = await session.publisher.commitAll(subject: report.commit, trailer: trailer);
    return error == null ? null : _Stop(RunOutcome.failed, error);
  }

  /// Runs the project checks. When they fail, the implementer gets one chance
  /// to fix them.
  Future<_Stop?> _fixChecks(_Session session) async {
    var result = await _check(session);
    if (result.ok) {
      session.checkResult = 'All checks passed (`fvm dart tool/agent_check.dart`).';
      return null;
    }
    final fix = await _stage(
      session,
      Role.implementer,
      extra: 'The project checks failed. Fix them without changing what the task asks:\n${_tail(result)}',
    );
    if (fix.stop case final stop?) return stop;
    final report = StageReport.parse(fix.message);
    if (report.isBlocked) return _Stop(RunOutcome.blocked, report.blocked);
    if (await _commit(session, report, Role.implementer) case final stop?) return stop;
    result = await _check(session);
    if (result.ok) {
      session.checkResult = 'All checks passed (`fvm dart tool/agent_check.dart`), after one fix.';
      return null;
    }
    return _Stop(RunOutcome.failed, 'The project checks still fail.', tail: _tail(result));
  }

  Future<CommandResult> _check(_Session session) {
    return run('fvm', ['dart', 'tool/agent_check.dart', '--skip-build'], workingDirectory: session.workspace.directory);
  }

  String _tail(CommandResult result) {
    final lines = '${result.stdout}\n${result.stderr}'.trim().split('\n');
    return lines.skip(lines.length > 40 ? lines.length - 40 : 0).join('\n');
  }

  /// Archives the task, scans for private data, pushes and opens the PR.
  Future<RunResult> _publish(_Session session) async {
    final task = session.task;
    session.workspace.writeState(taskId: task.id, tool: tool.name, stage: 'publish');
    final String archived;
    try {
      archived = await TaskArchiver(workspace: session.workspace.directory, run: run).archive(
        task,
        notes: _notes(session),
      );
    } on StateError catch (error) {
      return _safeAbandon(session, _Stop(RunOutcome.failed, error.message));
    }
    final closing = await session.publisher.commitAll(
      subject: 'docs: close task ${task.id.toLowerCase()}',
      trailer: 'Co-Authored-By: ${session.models[Role.implementer]?.attribution(tool) ?? tool.label}',
    );
    if (closing != null) return _safeAbandon(session, _Stop(RunOutcome.failed, closing));

    final leaks = DiffScanner.scan(await session.publisher.addedLinesDiff());
    if (leaks.isNotEmpty) {
      return _keep(
        session,
        'Private data found, nothing was pushed: ${leaks.join('; ')}',
        outcome: RunOutcome.blocked,
      );
    }

    final pushError = await session.publisher.push(task.branch);
    if (pushError != null) return _keep(session, pushError);

    final slug = originUrl.githubSlug;
    if (slug == null) return _keep(session, 'The origin URL is not a GitHub URL.');
    final body = PrDescription.build(
      task: task,
      implementer: session.implementer ?? StageReport.parse(''),
      tests: session.tests ?? StageReport.parse(''),
      reviewNotes: session.reviewNotes,
      goldens: await session.publisher.changedGoldens(),
      slug: slug,
      baseSha: await session.publisher.baseSha(),
      headSha: await session.publisher.headSha(),
      checkResult: session.checkResult,
      deniedCommands: session.deniedCommands.toList(),
      taskPath: '$archived/index.md',
    );
    final bodyFile = '${session.workspace.runnerDirectory}/pr-body.md';
    final url = await _writeBodyAndOpen(session, body: body, bodyFile: bodyFile);
    if (url.startsWith('error:')) return _keep(session, url);
    session.workspace.cleanup();
    return RunResult(taskId: task.id, outcome: RunOutcome.pullRequest, prUrl: url);
  }

  Future<String> _writeBodyAndOpen(_Session session, {required String body, required String bodyFile}) async {
    await File(bodyFile).writeAsString(body);
    return session.publisher.openPullRequest(
      branch: session.task.branch,
      title: '${session.task.type}: ${session.task.title.lowerFirst}',
      bodyFile: bodyFile,
    );
  }

  /// Keeps the work as a `wip:` commit on the task branch, with the reason in
  /// the task notes, and deletes the clone once it is pushed.
  Future<RunResult> _abandon(_Session session, _Stop original) async {
    final stop = session.deniedCommands.isEmpty
        ? original
        : _Stop(
            original.outcome,
            '${original.message} Commands the tool was not allowed to run: ${_commandList(session)}. '
            'If one was needed, relaunch with --allow="Bash(<program>:*)".',
            tail: original.tail,
          );
    final task = session.task;
    final workspace = session.workspace.directory;
    // The archiver may already have moved the task into its `done/` folder.
    final oldFolder = '$workspace/${task.directory}';
    final folder = Directory(oldFolder).existsSync() ? oldFolder : '$workspace/${task.doneDirectory}';
    await File('$folder/notes.md').writeAsString('\n## Blocked\n\n${stop.message}\n', mode: FileMode.append);
    final error = await session.publisher.commitAll(
      subject: 'wip: ${task.id.toLowerCase()} stopped',
      trailer: 'Co-Authored-By: ${session.models[Role.implementer]?.attribution(tool) ?? tool.label}',
    );
    final leaks = error == null ? DiffScanner.scan(await session.publisher.addedLinesDiff()) : <String>[];
    if (leaks.isNotEmpty) {
      return _keep(
        session,
        '${stop.message} Private data found, nothing was pushed: ${leaks.join('; ')}',
        outcome: RunOutcome.blocked,
      );
    }
    final pushError = error ?? await session.publisher.push(task.branch);
    if (pushError != null) return _keep(session, '${stop.message} ($pushError)');
    session.workspace.cleanup();
    return RunResult(taskId: task.id, outcome: stop.outcome, message: stop.message, tail: stop.tail);
  }

  RunResult _keep(_Session session, String message, {RunOutcome outcome = RunOutcome.failed}) {
    return RunResult(
      taskId: session.task.id,
      outcome: outcome,
      message: message,
      keptWorkspace: session.workspace.directory,
    );
  }

  String _commandList(_Session session) => session.deniedCommands.map((command) => '`$command`').join(', ');

  String _notes(_Session session) {
    final implementer = session.implementer;
    final tests = session.tests;
    final models =
        session.models.entries.map((entry) => '${entry.key.name}: ${entry.value.attribution(tool)}').join('; ');
    return [
      '## Summary',
      '',
      implementer?.summary ?? '',
      '',
      '## Evidence',
      '',
      tests?.evidence ?? '',
      '',
      '## Review notes',
      '',
      if (session.reviewNotes.isEmpty)
        'None.'
      else
        ...session.reviewNotes.map((finding) => '- ${finding.location}: ${finding.summary}'),
      '',
      '## Run',
      '',
      models,
      if (session.deniedCommands.isNotEmpty) ...[
        '',
        '## Commands denied',
        '',
        ...session.deniedCommands.map((command) => '- `$command`'),
      ],
    ].join('\n');
  }
}
