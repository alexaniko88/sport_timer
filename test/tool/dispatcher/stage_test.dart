// Checks the tool commands, the stage reports, the review gate and the PR text.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/dispatcher/pr_description.dart';
import '../../../tool/dispatcher/review_gate.dart';
import '../../../tool/dispatcher/role_models.dart';
import '../../../tool/dispatcher/stage_report.dart';
import '../../../tool/dispatcher/stage_runner.dart';
import '../../../tool/dispatcher/task.dart';
import '../../../tool/dispatcher/tool_command.dart';

const _model = RoleModel(model: 'm', effort: 'medium', displayName: 'M');

ToolInvocation _build(Tool tool, Role role) {
  return ToolCommand.build(tool: tool, role: role, model: _model, prompt: 'go', lastMessageFile: '/tmp/last.txt');
}

void main() {
  group('ToolCommand', () {
    test('Claude ignores user settings, never asks and edits only for work roles', () {
      final work = _build(Tool.claude, Role.implementer).args;
      final review = _build(Tool.claude, Role.reviewer).args;

      expect(work, containsAllInOrder(['--setting-sources', 'project', '--permission-prompts', 'none']));
      expect(work, containsAllInOrder(['--permission-mode', 'acceptEdits']));
      expect(work, contains('Bash(fvm:*)'));
      expect(review, containsAllInOrder(['--permission-mode', 'plan']));
      expect(review, isNot(contains('Bash(fvm:*)')));
    });

    test('Codex uses a clean config and a read-only sandbox for the reviewer', () {
      final work = _build(Tool.codex, Role.tests);
      final review = _build(Tool.codex, Role.reviewer);

      expect(work.args, containsAll(['--ignore-user-config', '--ephemeral']));
      expect(work.args, containsAllInOrder(['-s', 'workspace-write']));
      expect(review.args, containsAllInOrder(['-s', 'read-only']));
      expect(work.lastMessageFile, '/tmp/last.txt');
    });

    test('Antigravity always runs in its sandbox', () {
      final work = _build(Tool.antigravity, Role.implementer).args;
      final review = _build(Tool.antigravity, Role.reviewer).args;

      expect(work, containsAllInOrder(['--sandbox', '--mode', 'accept-edits']));
      expect(review, containsAllInOrder(['--sandbox', '--mode', 'plan']));
      expect(work.last, '-p=go');
    });

    test('extra allowed commands are added for Claude only', () {
      final invocation = ToolCommand.build(
        tool: Tool.claude,
        role: Role.implementer,
        model: _model,
        prompt: 'go',
        lastMessageFile: 'x',
        extraAllowed: ['Bash(curl:*)'],
      );

      expect(invocation.args, contains('Bash(curl:*)'));
    });
  });

  group('StageRunner', () {
    test('Claude: reads the result and the denied commands from its JSON', () async {
      final runner = StageRunner(
        run: (invocation, {required workingDirectory, required timeout}) async => ProcessOutcome(
          exitCode: 0,
          stdout: jsonEncode({
            'result': 'done',
            'permission_denials': [
              {
                'tool_name': 'Bash',
                'tool_input': {'command': 'git commit -m x'},
              },
            ],
          }),
          stderr: '',
        ),
      );

      final result = await runner.runStage(
        tool: Tool.claude,
        role: Role.implementer,
        model: _model,
        workspace: '.',
        prompt: 'go',
        lastMessageFile: 'x',
      );

      expect(result.message, 'done');
      expect(result.deniedCommands, ['git commit -m x']);
    });

    test('a non-zero exit is not ok and keeps the output tail', () async {
      final runner = StageRunner(
        run: (invocation, {required workingDirectory, required timeout}) async =>
            const ProcessOutcome(exitCode: 1, stdout: 'a\nb', stderr: 'boom'),
      );

      final result = await runner.runStage(
        tool: Tool.antigravity,
        role: Role.tests,
        model: _model,
        workspace: '.',
        prompt: 'go',
        lastMessageFile: 'x',
      );

      expect(result.ok, isFalse);
      expect(result.tail, contains('boom'));
    });

    test('the prompt names the role file and the task', () {
      final prompt = StageRunner.prompt(role: Role.tests, taskPath: 'project-tasks/x/index.md');

      expect(prompt, contains('.agents/skills/skill-dispatcher/roles/tests.md'));
      expect(prompt, contains('project-tasks/x/index.md'));
    });
  });

  group('StageReport', () {
    test('reads the sections and the commit line', () {
      final report = StageReport.parse(
        '## Commit\n\n`feat: add the thing`\n\n## Summary\n\n- one\n\n## Evidence\n\n- ok\n\n## Open notes\n\nNone\n\n## Blocked\n\nNone\n',
      );

      expect(report.commit, 'feat: add the thing');
      expect(report.summary, '- one');
      expect(report.isBlocked, isFalse);
    });

    test('a Blocked section with a question blocks the stage', () {
      final report = StageReport.parse('## Blocked\n\nWhich storage should I use?\n');

      expect(report.isBlocked, isTrue);
    });
  });

  group('ReviewGate', () {
    String message(String findings) => 'Done.\n\n```json\n{"findings": $findings}\n```\n';

    test('reads findings from the last json block', () {
      final findings = ReviewGate.parse(
        message('[{"severity": "Critical", "file": "lib/a.dart", "line": 3, "summary": "Bug", "fix": "Fix it"}]'),
      );

      expect(findings?.single.severity, Severity.critical);
      expect(findings?.single.location, 'lib/a.dart:3');
    });

    test('no json block means the review did not happen', () {
      expect(ReviewGate.parse('looks fine'), isNull);
    });

    test('minor findings pass; critical or general ones are fixed once, then block', () {
      const minor = ReviewFinding(severity: Severity.minor, file: '', line: null, summary: '', fix: '');
      const general = ReviewFinding(severity: Severity.general, file: '', line: null, summary: '', fix: '');

      expect(ReviewGate.decide(round: 1, findings: [minor]), ReviewDecision.pass);
      expect(ReviewGate.decide(round: 1, findings: [general]), ReviewDecision.fix);
      expect(ReviewGate.decide(round: 2, findings: [general]), ReviewDecision.blocked);
      expect(ReviewGate.notes([minor, general]), [minor]);
    });
  });

  group('PrDescription', () {
    final task = Task.tryParse(
          path: 'project-tasks/e/stories/01-s/01-a/index.md',
          text:
              '---\nid: E-01-01\nstatus: ready\ntype: feat\n---\n\n# Add it\n\n## Acceptance\n\n- [ ] When x, then y. Check: test.\n',
        ) ??
        (throw StateError('The sample task did not parse.'));
    final report =
        StageReport.parse('## Summary\n\n- Adds it.\n\n## Evidence\n\n- y: passed\n\n## Open notes\n\nNone\n');

    test('lists the summary, criteria, checks and golden links, with no attribution line', () {
      final text = PrDescription.build(
        task: task,
        implementer: report,
        tests: report,
        reviewNotes: const [],
        goldens: const [
          GoldenChange(path: 'test/snapshots/goldens/a.png', existedBefore: true),
          GoldenChange(path: 'test/snapshots/goldens/b.png', existedBefore: false),
        ],
        slug: 'o/r',
        baseSha: 'base',
        headSha: 'head',
        checkResult: 'All checks passed.',
      );

      expect(text, contains('- Adds it.'));
      expect(text, contains('- [x] When x, then y.'));
      expect(text, contains('![before](https://github.com/o/r/blob/base/test/snapshots/goldens/a.png?raw=true)'));
      expect(text, contains('| b.png | new |'));
      expect(text, contains('All checks passed.'));
      expect(text.toLowerCase(), isNot(contains('generated with')));
    });
  });
}
