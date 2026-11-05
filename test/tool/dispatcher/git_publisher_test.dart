// Checks the commit rules, the private data scan, the git writes in a real
// temporary repo, and the archiving of a finished task. No network is used.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/dispatcher/command_runner.dart';
import '../../../tool/dispatcher/git_publisher.dart';
import '../../../tool/dispatcher/task.dart';
import '../../../tool/dispatcher/task_archiver.dart';

String _git(String directory, List<String> args) {
  final result = Process.runSync('git', args, workingDirectory: directory);
  if (result.exitCode != 0) fail('git ${args.join(' ')} failed: ${result.stderr}');
  return (result.stdout as String).trim();
}

Directory _repo() {
  final directory = Directory.systemTemp.createTempSync('dispatcher_git_test_');
  addTearDown(() => directory.deleteSync(recursive: true));
  _git(directory.path, ['init', '-q', '-b', 'master']);
  _git(directory.path, ['config', 'user.email', 'test@users.noreply.github.com']);
  _git(directory.path, ['config', 'user.name', 'Test']);
  return directory;
}

void main() {
  group('CommitMessage', () {
    test('accepts a lowercase typed subject', () {
      expect(CommitMessage.problem('feat: add the thing'), isNull);
      expect(CommitMessage.problem('wip: tpl-03-02 stopped'), isNull);
    });

    test('rejects a wrong type, a capital letter, a final period or an empty subject', () {
      expect(CommitMessage.problem('add the thing'), isNotNull);
      expect(CommitMessage.problem('feat: Add the thing'), isNotNull);
      expect(CommitMessage.problem('feat: add the thing.'), isNotNull);
      expect(CommitMessage.problem(''), isNotNull);
    });
  });

  group('DiffScanner', () {
    final home = ['', 'Us' 'ers', 'someone', 'x.txt'].join('/');

    test('finds a local path in an added line, with its file', () {
      final findings = DiffScanner.scan('+++ b/lib/a.dart\n@@ -0,0 +1 @@\n+const p = "$home";\n');

      expect(findings, ['lib/a.dart has a local home path']);
    });

    test('ignores removed lines and clean additions', () {
      expect(DiffScanner.scan('+++ b/a\n-const p = "$home";\n+const ok = 1;\n'), isEmpty);
    });
  });

  group('GitPublisher', () {
    test('commits everything with the trailer, and does nothing when there is no change', () async {
      final directory = _repo();
      final publisher = GitPublisher(workspace: directory.path, run: runSystemCommand);

      expect(await publisher.commitAll(subject: 'chore: nothing', trailer: 'Co-Authored-By: Claude'), isNull);
      expect(Process.runSync('git', ['rev-parse', 'HEAD'], workingDirectory: directory.path).exitCode, isNot(0));

      File('${directory.path}/a.txt').writeAsStringSync('a');
      expect(await publisher.commitAll(subject: 'feat: add a', trailer: 'Co-Authored-By: Claude Sonnet 5.5'), isNull);

      expect(_git(directory.path, ['log', '-1', '--format=%s']), 'feat: add a');
      expect(_git(directory.path, ['log', '-1', '--format=%B']), contains('Co-Authored-By: Claude Sonnet 5.5'));
    });

    test('never pushes to master or main', () async {
      const publisher = GitPublisher(workspace: '.', run: runSystemCommand);

      expect(await publisher.push('master'), contains('Refusing'));
      expect(await publisher.push('main'), contains('Refusing'));
    });
  });

  group('TaskArchiver', () {
    test('moves the task to done/, marks it done and fixes the links', () async {
      final directory = _repo();
      void write(String path, String text) {
        File('${directory.path}/$path')
          ..createSync(recursive: true)
          ..writeAsStringSync(text);
      }

      const task = 'project-tasks/e/stories/01-s/01-a';
      write(
        '$task/index.md',
        '---\nid: E-01-01\nstatus: ready\ntype: feat\n---\n\n# Add a\n\nStory: [S](../index.md)\n\nMockup: [m](mockup.html)\n\n'
            '## Acceptance\n\n- [ ] When x, then y.\n\n## Other\n\n- [ ] keep\n',
      );
      write('$task/mockup.html', '<html></html>');
      write('project-tasks/e/stories/01-s/index.md', '# Story\n\n1. [Add a](01-a/index.md)\n');
      _git(directory.path, ['add', '-A']);
      _git(directory.path, ['commit', '-q', '-m', 'seed']);

      final parsed =
          Task.tryParse(path: '$task/index.md', text: File('${directory.path}/$task/index.md').readAsStringSync());
      if (parsed == null) fail('The sample task did not parse.');
      final newDirectory = await TaskArchiver(workspace: directory.path, run: runSystemCommand).archive(
        parsed,
        notes: '## Summary\n\nDone.',
      );

      expect(newDirectory, 'project-tasks/e/stories/01-s/done/01-a');
      final index = File('${directory.path}/$newDirectory/index.md').readAsStringSync();
      expect(index, contains('status: done'));
      expect(index, contains('- [x] When x, then y.'));
      expect(index, contains('- [ ] keep'));
      expect(index, contains('[S](../../index.md)'));
      expect(index, contains('[m](mockup.html)'));
      expect(File('${directory.path}/$newDirectory/notes.md').readAsStringSync(), contains('Done.'));
      expect(
        File('${directory.path}/project-tasks/e/stories/01-s/index.md').readAsStringSync(),
        contains('(done/01-a/index.md)'),
      );
      expect(Directory('${directory.path}/$task').existsSync(), isFalse);
    });
  });
}
