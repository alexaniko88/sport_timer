// Runs the whole pipeline of one task against a temporary origin repo, with a
// fake AI tool and a fake `gh`. Git is real; nothing touches the network.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/dispatcher/command_runner.dart';
import '../../../tool/dispatcher/git_publisher.dart';
import '../../../tool/dispatcher/launch_pipeline.dart';
import '../../../tool/dispatcher/role_models.dart';
import '../../../tool/dispatcher/run_workspace.dart';
import '../../../tool/dispatcher/stage_runner.dart';
import '../../../tool/dispatcher/task.dart';
import '../../../tool/dispatcher/tool_command.dart';

const _taskDirectory = 'project-tasks/tst/stories/01-s/01-do-thing';
const _branch = 'feat/tst-01-01-do-thing';

String _git(String directory, List<String> args) {
  final result = Process.runSync('git', args, workingDirectory: directory);
  if (result.exitCode != 0) fail('git ${args.join(' ')} failed: ${result.stderr}');
  return (result.stdout as String).trim();
}

String _message({String commit = 'feat: add x', String blocked = 'None', String extra = ''}) {
  return '## Commit\n\n$commit\n\n## Summary\n\n- did it\n\n## Evidence\n\n- passed\n\n## Open notes\n\nNone\n\n## Blocked\n\n$blocked\n$extra';
}

String _review(String findings) => 'Reviewed.\n\n```json\n{"findings": $findings}\n```\n';

class _Fixture {
  final Directory root;
  final String origin;
  final List<List<String>> ghCalls = [];

  _Fixture(this.root, this.origin);

  String get runs => '${root.path}/runs';

  Future<CommandResult> run(String executable, List<String> args, {String? workingDirectory}) async {
    if (executable == 'fvm') return const CommandResult(exitCode: 0, stdout: 'ok', stderr: '');
    if (executable == 'gh') {
      ghCalls.add(args);
      return const CommandResult(exitCode: 0, stdout: 'https://github.com/owner/repo/pull/1\n', stderr: '');
    }
    return runSystemCommand(executable, args, workingDirectory: workingDirectory);
  }

  String originLog(String branch) => _git(origin, ['log', '--format=%s', branch]);

  bool originHas(String branch) =>
      Process.runSync('git', ['rev-parse', '--verify', branch], workingDirectory: origin).exitCode == 0;
}

_Fixture _fixture() {
  final root = Directory.systemTemp.createTempSync('dispatcher_pipeline_test_');
  addTearDown(() => root.deleteSync(recursive: true));
  final origin = '${root.path}/github.com/owner/repo.git';
  Directory(origin).createSync(recursive: true);
  _git(origin, ['init', '-q', '--bare', '-b', 'master']);

  final seed = '${root.path}/seed';
  Directory('$seed/$_taskDirectory').createSync(recursive: true);
  File('$seed/$_taskDirectory/index.md').writeAsStringSync(
    '---\nid: TST-01-01\nstatus: ready\ntype: feat\ndepends-on: []\ntouches: [lib/x.dart]\n---\n\n# Do thing\n\n## Acceptance\n\n- [ ] When x, then y. Check: test.\n',
  );
  _git(seed, ['init', '-q', '-b', 'master']);
  _git(seed, ['config', 'user.email', 'seed@users.noreply.github.com']);
  _git(seed, ['config', 'user.name', 'Seed']);
  _git(seed, ['add', '-A']);
  _git(seed, ['commit', '-q', '-m', 'seed']);
  _git(seed, ['remote', 'add', 'origin', origin]);
  _git(seed, ['push', '-q', 'origin', 'master']);
  return _Fixture(root, origin);
}

/// A fake tool: [work] decides what each role does and answers with its final message.
LaunchPipeline _pipeline(
  _Fixture fixture,
  String Function(Role role, String workspace) work, {
  RunCommand? run,
  List<String> denied = const [],
}) {
  Future<ProcessOutcome> process(
    ToolInvocation invocation, {
    required String workingDirectory,
    required Duration timeout,
  }) async {
    final prompt = invocation.args.last;
    final role = Role.values.firstWhere((role) => prompt.contains('roles/${role.name}.md'));
    return ProcessOutcome(
      exitCode: 0,
      stdout: jsonEncode({
        'result': work(role, workingDirectory),
        'permission_denials': [
          for (final command in denied)
            {
              'tool_name': 'Bash',
              'tool_input': {'command': command},
            },
        ],
      }),
      stderr: '',
    );
  }

  return LaunchPipeline(
    tool: Tool.claude,
    stages: StageRunner(run: process),
    run: run ?? fixture.run,
    originUrl: fixture.origin,
    email: 'dev@users.noreply.github.com',
    name: 'Dev',
    baseDirectory: fixture.runs,
    skipFlutterSetup: true,
    log: (_) {},
  );
}

Task _task(_Fixture fixture) {
  final text = File('${fixture.root.path}/seed/$_taskDirectory/index.md').readAsStringSync();
  return Task.tryParse(path: '$_taskDirectory/index.md', text: text) ??
      (throw StateError('The sample task did not parse.'));
}

void _write(String workspace, String path, String text) {
  File('$workspace/$path')
    ..createSync(recursive: true)
    ..writeAsStringSync(text);
}

void main() {
  test('a clean run ends as a PR with one commit per stage and the task in done/', () async {
    final fixture = _fixture();
    final pipeline = _pipeline(fixture, (role, workspace) {
      switch (role) {
        case Role.implementer:
          _write(workspace, 'lib/x.dart', 'const x = 1;\n');
          return _message();
        case Role.tests:
          _write(workspace, 'test/x_test.dart', 'void main() {}\n');
          return _message(commit: 'test: add x tests');
        case Role.reviewer:
          return _review(
            '[{"severity": "minor", "file": "lib/x.dart", "line": 1, "summary": "Name it better", "fix": ""}]',
          );
      }
    });

    final result = await pipeline.launch(_task(fixture));

    expect(result.outcome, RunOutcome.pullRequest);
    expect(result.prUrl, 'https://github.com/owner/repo/pull/1');
    expect(
      fixture.originLog(_branch).split('\n'),
      ['docs: close task tst-01-01', 'test: add x tests', 'feat: add x', 'seed'],
    );
    expect(_git(fixture.origin, ['log', '-1', '--format=%B', _branch]), contains('Co-Authored-By: Claude Sonnet 5.5'));
    final files = _git(fixture.origin, ['ls-tree', '-r', '--name-only', _branch]);
    expect(files, contains('project-tasks/tst/stories/01-s/done/01-do-thing/index.md'));
    expect(files, contains('project-tasks/tst/stories/01-s/done/01-do-thing/notes.md'));
    expect(files, isNot(contains('$_taskDirectory/index.md')));
    expect(fixture.ghCalls.single, containsAllInOrder(['--head', _branch, '--title', 'feat: do thing']));
    expect(Directory('${fixture.runs}/TST-01-01').existsSync(), isFalse);
  });

  test('a stage that asks a question stops with a wip commit and no PR', () async {
    final fixture = _fixture();
    final pipeline = _pipeline(fixture, (role, workspace) {
      _write(workspace, 'lib/x.dart', 'const x = 1;\n');
      return _message(blocked: 'Which storage should I use?');
    });

    final result = await pipeline.launch(_task(fixture));

    expect(result.outcome, RunOutcome.blocked);
    expect(result.message, 'Which storage should I use?');
    expect(fixture.originLog(_branch).split('\n').first, 'wip: tst-01-01 stopped');
    expect(
      _git(fixture.origin, ['show', '$_branch:$_taskDirectory/notes.md']),
      contains('Which storage should I use?'),
    );
    expect(fixture.ghCalls, isEmpty);
    expect(Directory('${fixture.runs}/TST-01-01').existsSync(), isFalse);
  });

  test('findings that stay after the second review block the task', () async {
    final fixture = _fixture();
    var reviews = 0;
    final pipeline = _pipeline(fixture, (role, workspace) {
      switch (role) {
        case Role.implementer:
          _write(workspace, 'lib/x.dart', 'const x = ${reviews + 1};\n');
          return _message(commit: reviews == 0 ? 'feat: add x' : 'fix: address review findings');
        case Role.tests:
          return _message(commit: 'test: add x tests');
        case Role.reviewer:
          reviews++;
          return _review(
            '[{"severity": "general", "file": "lib/x.dart", "line": 1, "summary": "Wrong layer", "fix": "Move it"}]',
          );
      }
    });

    final result = await pipeline.launch(_task(fixture));

    expect(result.outcome, RunOutcome.blocked);
    expect(reviews, 2);
    expect(result.message, contains('Wrong layer'));
    expect(fixture.originLog(_branch).split('\n').first, 'wip: tst-01-01 stopped');
    expect(fixture.ghCalls, isEmpty);
  });

  test('private data is never pushed and the clone is kept', () async {
    final fixture = _fixture();
    final home = ['', 'Us' 'ers', 'someone', 'x'].join('/');
    final pipeline = _pipeline(fixture, (role, workspace) {
      switch (role) {
        case Role.implementer:
          _write(workspace, 'lib/x.dart', 'const path = "$home";\n');
          return _message();
        case Role.tests:
          return _message(commit: 'test: add x tests');
        case Role.reviewer:
          return _review('[]');
      }
    });

    final result = await pipeline.launch(_task(fixture));

    expect(result.outcome, RunOutcome.blocked);
    expect(result.message, contains('Private data found'));
    expect(result.keptWorkspace, isNotNull);
    expect(fixture.originHas(_branch), isFalse);
    expect(fixture.ghCalls, isEmpty);
  });

  test('a denied command does not stop a run whose stages still deliver, and is listed in the notes', () async {
    final fixture = _fixture();
    final pipeline = _pipeline(
      fixture,
      (role, workspace) {
        switch (role) {
          case Role.implementer:
            _write(workspace, 'lib/x.dart', 'const x = 1;\n');
            return _message();
          case Role.tests:
            _write(workspace, 'test/x_test.dart', 'void main() {}\n');
            return _message(commit: 'test: add x tests');
          case Role.reviewer:
            return _review('[]');
        }
      },
      denied: ['python3 script.py'],
    );

    final result = await pipeline.launch(_task(fixture));

    expect(result.outcome, RunOutcome.pullRequest);
    final notes = _git(
      fixture.origin,
      ['show', '$_branch:project-tasks/tst/stories/01-s/done/01-do-thing/notes.md'],
    );
    expect(notes, contains('## Commands denied'));
    expect(notes, contains('- `python3 script.py`'));
  });

  test('a denied command is named in the block message when the stage asks a question', () async {
    final fixture = _fixture();
    final pipeline = _pipeline(
      fixture,
      (role, workspace) {
        _write(workspace, 'lib/x.dart', 'const x = 1;\n');
        return _message(blocked: 'I need to run curl.');
      },
      denied: ['curl https://example.com'],
    );

    final result = await pipeline.launch(_task(fixture));

    expect(result.outcome, RunOutcome.blocked);
    expect(result.message, contains('I need to run curl.'));
    expect(result.message, contains('`curl https://example.com`'));
    expect(result.message, contains('--allow='));
  });

  test('a denied command is named when the stage gives no usable report', () async {
    final fixture = _fixture();
    final pipeline = _pipeline(fixture, (role, workspace) => 'could not', denied: ['curl https://example.com']);

    final result = await pipeline.launch(_task(fixture));

    expect(result.outcome, RunOutcome.failed);
    expect(result.message, contains('`curl https://example.com`'));
  });

  test('a git email that is not the noreply one is refused before anything runs', () async {
    final fixture = _fixture();
    final pipeline = LaunchPipeline(
      tool: Tool.claude,
      stages: const StageRunner(),
      run: fixture.run,
      originUrl: fixture.origin,
      email: 'me@company.com',
      name: 'Dev',
      baseDirectory: fixture.runs,
      skipFlutterSetup: true,
      log: (_) {},
    );

    final result = await pipeline.launch(_task(fixture));

    expect(result.outcome, RunOutcome.failed);
    expect(result.message, contains('noreply'));
    expect(Directory('${fixture.runs}/TST-01-01').existsSync(), isFalse);
  });

  group('RunWorkspace.prepare', () {
    Future<RunWorkspace> prepare(
      _Fixture fixture, {
      RunCommand? run,
      bool skipFlutterSetup = true,
    }) {
      return RunWorkspace.prepare(
        run: run ?? fixture.run,
        task: _task(fixture),
        originUrl: fixture.origin,
        email: 'dev@users.noreply.github.com',
        name: 'Dev',
        tool: 'claude',
        baseDirectory: fixture.runs,
        skipFlutterSetup: skipFlutterSetup,
      );
    }

    test('a relaunch checks out the wip branch and diffs only the branch lines after master moved', () async {
      final fixture = _fixture();
      final seed = '${fixture.root.path}/seed';
      _git(seed, ['checkout', '-q', '-b', _branch]);
      File('$seed/branch.txt').writeAsStringSync('from the branch\n');
      _git(seed, ['add', '-A']);
      _git(seed, ['commit', '-q', '-m', 'wip: tst-01-01 stopped']);
      _git(seed, ['push', '-q', 'origin', _branch]);
      _git(seed, ['checkout', '-q', 'master']);
      File('$seed/master.txt').writeAsStringSync('newer on master\n');
      _git(seed, ['add', '-A']);
      _git(seed, ['commit', '-q', '-m', 'newer master']);
      _git(seed, ['push', '-q', 'origin', 'master']);

      final workspace = await prepare(fixture);

      expect(_git(workspace.directory, ['rev-parse', '--abbrev-ref', 'HEAD']), _branch);
      expect(_git(workspace.directory, ['merge-base', 'HEAD', 'origin/master']), isNotEmpty);
      final diff = await GitPublisher(workspace: workspace.directory, run: fixture.run).addedLinesDiff();
      expect(diff, contains('from the branch'));
      expect(diff, isNot(contains('newer on master')));
    });

    test('state.json says "prepare" with the tool name before the clone runs', () async {
      final fixture = _fixture();
      String? state;
      Future<CommandResult> run(String executable, List<String> args, {String? workingDirectory}) async {
        if (executable == 'git' && args.contains('clone')) {
          state = File('${fixture.runs}/TST-01-01/state.json').readAsStringSync();
          return const CommandResult(exitCode: 1, stdout: '', stderr: 'stop here');
        }
        return fixture.run(executable, args, workingDirectory: workingDirectory);
      }

      await expectLater(prepare(fixture, run: run), throwsStateError);

      expect(jsonDecode(state ?? '{}'), containsPair('stage', 'prepare'));
      expect(jsonDecode(state ?? '{}'), containsPair('tool', 'claude'));
    });

    test('the run folder is deleted when a command throws something other than a StateError', () async {
      final fixture = _fixture();
      Future<CommandResult> run(String executable, List<String> args, {String? workingDirectory}) {
        throw const ProcessException('git', ['clone'], 'not installed');
      }

      await expectLater(prepare(fixture, run: run), throwsA(isA<ProcessException>()));

      expect(Directory('${fixture.runs}/TST-01-01').existsSync(), isFalse);
    });

    test('the Flutter setup runs install, pub get and analyze in order', () async {
      final fixture = _fixture();
      final fvmCalls = <String>[];
      Future<CommandResult> run(String executable, List<String> args, {String? workingDirectory}) {
        if (executable == 'fvm') fvmCalls.add(args.join(' '));
        return fixture.run(executable, args, workingDirectory: workingDirectory);
      }

      await prepare(fixture, run: run, skipFlutterSetup: false);

      expect(fvmCalls, ['install --skip-pub-get', 'flutter pub get', 'flutter analyze --no-pub']);
    });

    test('a failing baseline analyze throws with the analyzer output and cleans up', () async {
      final fixture = _fixture();
      Future<CommandResult> run(String executable, List<String> args, {String? workingDirectory}) async {
        if (executable == 'fvm' && args.contains('analyze')) {
          return const CommandResult(exitCode: 1, stdout: 'error • lib/a.dart:1 • broken', stderr: '');
        }
        return fixture.run(executable, args, workingDirectory: workingDirectory);
      }

      await expectLater(
        prepare(fixture, run: run, skipFlutterSetup: false),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(contains('fvm flutter analyze'), contains('lib/a.dart:1 • broken')),
          ),
        ),
      );

      expect(Directory('${fixture.runs}/TST-01-01').existsSync(), isFalse);
    });
  });

  group('launch never throws once the clone exists', () {
    test('a stage process that throws ends as failed, pushed as wip, with the clone deleted', () async {
      final fixture = _fixture();
      Future<ProcessOutcome> process(
        ToolInvocation invocation, {
        required String workingDirectory,
        required Duration timeout,
      }) {
        throw const ProcessException('claude', [], 'not installed');
      }

      final pipeline = LaunchPipeline(
        tool: Tool.claude,
        stages: StageRunner(run: process),
        run: fixture.run,
        originUrl: fixture.origin,
        email: 'dev@users.noreply.github.com',
        name: 'Dev',
        baseDirectory: fixture.runs,
        skipFlutterSetup: true,
        log: (_) {},
      );

      final result = await pipeline.launch(_task(fixture));

      expect(result.outcome, RunOutcome.failed);
      expect(result.message, contains('Unexpected error'));
      expect(fixture.originLog(_branch).split('\n').first, 'wip: tst-01-01 stopped');
      expect(Directory('${fixture.runs}/TST-01-01').existsSync(), isFalse);
    });

    test('a failed closing commit still writes the Blocked note into the archived done/ folder', () async {
      final fixture = _fixture();
      Future<CommandResult> run(String executable, List<String> args, {String? workingDirectory}) async {
        if (executable == 'git' && args.contains('commit') && args.any((arg) => arg.startsWith('docs: close task'))) {
          return const CommandResult(exitCode: 1, stdout: '', stderr: 'commit refused');
        }
        return fixture.run(executable, args, workingDirectory: workingDirectory);
      }

      final pipeline = _pipeline(
        fixture,
        (role, workspace) {
          switch (role) {
            case Role.implementer:
              _write(workspace, 'lib/x.dart', 'const x = 1;\n');
              return _message();
            case Role.tests:
              return _message(commit: 'test: add x tests');
            case Role.reviewer:
              return _review('[]');
          }
        },
        run: run,
      );

      final result = await pipeline.launch(_task(fixture));

      expect(result.outcome, RunOutcome.failed);
      expect(result.message, contains('commit refused'));
      final notes = _git(fixture.origin, ['show', '$_branch:project-tasks/tst/stories/01-s/done/01-do-thing/notes.md']);
      expect(notes, contains('## Blocked'));
      expect(notes, contains('commit refused'));
    });

    test('a failing abandon keeps the clone', () async {
      final fixture = _fixture();
      Future<CommandResult> run(String executable, List<String> args, {String? workingDirectory}) {
        if (executable == 'git' && args.contains('push')) throw const ProcessException('git', ['push'], 'boom');
        return fixture.run(executable, args, workingDirectory: workingDirectory);
      }

      final pipeline = _pipeline(fixture, (role, workspace) => _message(blocked: 'Which storage?'), run: run);

      final result = await pipeline.launch(_task(fixture));

      expect(result.outcome, RunOutcome.failed);
      expect(result.message, contains('Unexpected error'));
      expect(result.keptWorkspace, isNotNull);
      expect(Directory(result.keptWorkspace ?? '').existsSync(), isTrue);
    });

    test('an error while publishing ends as failed and keeps the clone', () async {
      final fixture = _fixture();
      Future<CommandResult> run(String executable, List<String> args, {String? workingDirectory}) {
        if (executable == 'gh') throw const ProcessException('gh', [], 'not installed');
        return fixture.run(executable, args, workingDirectory: workingDirectory);
      }

      final pipeline = _pipeline(
        fixture,
        (role, workspace) {
          switch (role) {
            case Role.implementer:
              _write(workspace, 'lib/x.dart', 'const x = 1;\n');
              return _message();
            case Role.tests:
              return _message(commit: 'test: add x tests');
            case Role.reviewer:
              return _review('[]');
          }
        },
        run: run,
      );

      final result = await pipeline.launch(_task(fixture));

      expect(result.outcome, RunOutcome.failed);
      expect(result.message, contains('Unexpected error'));
      expect(result.keptWorkspace, isNotNull);
      expect(Directory(result.keptWorkspace ?? '').existsSync(), isTrue);
    });
  });
}
