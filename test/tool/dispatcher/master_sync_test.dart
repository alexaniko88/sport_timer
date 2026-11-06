// Checks that MasterSync deletes only branches whose exact commit was merged
// into master, and keeps everything else. A fake command runner replaces git
// and gh, so no network or real repo is used.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/dispatcher/command_runner.dart';
import '../../../tool/dispatcher/master_sync.dart';

class _FakeRepo {
  final String current;
  final String status;
  final Map<String, String> branches;
  final List<Map<String, String>>? pulls;
  final List<String> worktreeBranches;
  final String? pullFailure;
  final List<String> calls = [];

  _FakeRepo({
    this.current = 'master',
    this.status = '',
    this.branches = const {},
    this.pulls = const [],
    this.worktreeBranches = const ['master'],
    this.pullFailure,
  });

  Future<CommandResult> run(String executable, List<String> args, {String? workingDirectory}) async {
    final command = '$executable ${args.join(' ')}';
    calls.add(command);
    CommandResult ok(String out) => CommandResult(exitCode: 0, stdout: out, stderr: '');
    if (command.startsWith('git status')) return ok(status);
    if (command == 'git branch --show-current') return ok('$current\n');
    if (command.startsWith('git for-each-ref')) {
      return ok([for (final MapEntry(:key, :value) in branches.entries) '$key $value'].join('\n'));
    }
    if (command == 'git worktree list --porcelain') {
      return ok([for (final branch in worktreeBranches) 'worktree /x\nbranch refs/heads/$branch\n'].join('\n'));
    }
    if (command.startsWith('gh pr list')) {
      final data = pulls;
      return data == null ? const CommandResult(exitCode: 1, stdout: '', stderr: 'offline') : ok(jsonEncode(data));
    }
    if (command == 'git pull --ff-only' && pullFailure != null) {
      return CommandResult(exitCode: 1, stdout: '', stderr: pullFailure!);
    }
    return ok('');
  }

  bool get deletedAnything => calls.any((call) => call.startsWith('git branch -D'));
}

Map<String, String> _pull(String branch, String commit, {String state = 'MERGED', String base = 'master'}) => {
      'headRefName': branch,
      'headRefOid': commit,
      'baseRefName': base,
      'state': state,
    };

void main() {
  Future<SyncReport> sync(_FakeRepo repo) => MasterSync(workspace: '/repo', run: repo.run).sync();

  test('deletes a branch whose exact commit was merged into master', () async {
    final repo = _FakeRepo(branches: {'master': 'm1', 'feat/a': 'a1'}, pulls: [_pull('feat/a', 'a1')]);

    final report = await sync(repo);

    expect(report.deleted, ['feat/a']);
    expect(repo.calls, contains('git branch -D feat/a'));
  });

  test('keeps a branch that has new commits after the merged pull request', () async {
    final repo = _FakeRepo(branches: {'feat/a': 'a2'}, pulls: [_pull('feat/a', 'a1')]);

    final report = await sync(repo);

    expect(report.deleted, isEmpty);
    expect(report.kept.keys, ['feat/a']);
    expect(repo.deletedAnything, isFalse);
  });

  test('keeps a new branch that has no pull request, even with no commits of its own', () async {
    final repo = _FakeRepo(branches: {'feat/plan-x': 'm1'});

    final report = await sync(repo);

    expect(report.deleted, isEmpty);
    expect(repo.deletedAnything, isFalse);
  });

  test('keeps a branch with an open pull request or one merged into another branch', () async {
    final repo = _FakeRepo(
      branches: {'feat/open': 'o1', 'feat/stacked': 's1'},
      pulls: [
        _pull('feat/open', 'o1', state: 'OPEN'),
        _pull('feat/open', 'o1'),
        _pull('feat/stacked', 's1', base: 'feat/open'),
      ],
    );

    final report = await sync(repo);

    expect(report.deleted, isEmpty);
    expect(report.kept.keys, unorderedEquals(['feat/open', 'feat/stacked']));
  });

  test('keeps a merged branch that is checked out in another worktree', () async {
    final repo = _FakeRepo(
      branches: {'feat/a': 'a1'},
      pulls: [_pull('feat/a', 'a1')],
      worktreeBranches: ['master', 'feat/a'],
    );

    final report = await sync(repo);

    expect(report.deleted, isEmpty);
    expect(report.kept['feat/a'], contains('worktree'));
  });

  test('never deletes master or main', () async {
    final repo = _FakeRepo(
      branches: {'master': 'm1', 'main': 'm1'},
      pulls: [_pull('master', 'm1'), _pull('main', 'm1')],
    );

    final report = await sync(repo);

    expect(report.deleted, isEmpty);
    expect(report.kept, isEmpty);
  });

  test('deletes nothing when GitHub cannot be read', () async {
    final repo = _FakeRepo(branches: {'feat/a': 'a1'}, pulls: null);

    final report = await sync(repo);

    expect(report.deleted, isEmpty);
    expect(repo.deletedAnything, isFalse);
  });

  test('switches to master first, so the merged branch it came from can be deleted', () async {
    final repo = _FakeRepo(current: 'feat/a', branches: {'feat/a': 'a1'}, pulls: [_pull('feat/a', 'a1')]);

    final report = await sync(repo);

    expect(report.switchedFrom, 'feat/a');
    expect(report.deleted, ['feat/a']);
    expect(repo.calls.indexOf('git switch master'), lessThan(repo.calls.indexOf('git branch -D feat/a')));
  });

  test('stops before any change when there are uncommitted changes', () async {
    final repo = _FakeRepo(current: 'feat/a', status: ' M lib/main.dart\n');

    await expectLater(sync(repo), throwsStateError);

    expect(repo.calls.where((call) => call.startsWith('git switch') || call.startsWith('git fetch')), isEmpty);
  });

  test('stops and deletes nothing when master cannot be fast-forwarded', () async {
    final repo = _FakeRepo(
      branches: {'feat/a': 'a1'},
      pulls: [_pull('feat/a', 'a1')],
      pullFailure: 'not possible to fast-forward',
    );

    await expectLater(sync(repo), throwsStateError);

    expect(repo.deletedAnything, isFalse);
  });
}
