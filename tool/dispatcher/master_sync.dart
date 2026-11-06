import 'dart:convert';

import 'command_runner.dart';

/// What [MasterSync.sync] did.
class SyncReport {
  final String? switchedFrom;
  final List<String> deleted;
  final Map<String, String> kept;

  const SyncReport({required this.switchedFrom, required this.deleted, required this.kept});
}

/// Puts the local repo on an up to date `master` and deletes the local
/// branches whose work is already merged.
///
/// A branch is deleted only when GitHub reports a merged pull request into
/// `master` with the same branch name and the same last commit as the local
/// branch. This also covers squash merges. A branch with no pull request, with
/// new commits after the merge, with an open pull request, or checked out in
/// another worktree is always kept. If GitHub cannot be read, nothing is
/// deleted. Remote branches are never touched.
class MasterSync {
  static const _trunk = 'master';
  static const _protected = {'master', 'main'};

  final String workspace;
  final RunCommand run;

  const MasterSync({required this.workspace, required this.run});

  /// Throws a [StateError] when the repo cannot be moved to `master` safely.
  /// Nothing is deleted in that case.
  Future<SyncReport> sync() async {
    await _requireClean();
    await _git(['fetch', '--prune', 'origin']);
    final current = (await _git(['branch', '--show-current'])).trim();
    if (current != _trunk) await _git(['switch', _trunk]);
    await _git(['pull', '--ff-only']);

    final deleted = <String>[];
    final kept = <String, String>{};
    final pulls = await _pullRequests();
    final worktreeBranches = await _worktreeBranches();
    for (final MapEntry(key: branch, value: tip) in (await _localBranches()).entries) {
      if (_protected.contains(branch)) continue;
      final reason = _keepReason(
        branch: branch,
        tip: tip,
        pulls: pulls,
        worktreeBranches: worktreeBranches,
      );
      if (reason != null) {
        kept[branch] = reason;
        continue;
      }
      final result = await run('git', ['branch', '-D', branch], workingDirectory: workspace);
      if (result.ok) {
        deleted.add(branch);
      } else {
        kept[branch] = 'git could not delete it: ${result.stderr.trim()}';
      }
    }
    return SyncReport(
      switchedFrom: current == _trunk || current.isEmpty ? null : current,
      deleted: deleted,
      kept: kept,
    );
  }

  /// Why this branch must stay, or `null` when it is safe to delete.
  String? _keepReason({
    required String branch,
    required String tip,
    required List<_PullRequest>? pulls,
    required Set<String> worktreeBranches,
  }) {
    if (pulls == null) return 'GitHub could not be read, so merged work cannot be confirmed';
    if (worktreeBranches.contains(branch)) return 'checked out in another worktree';
    final own = pulls.where((pull) => pull.branch == branch).toList();
    if (own.any((pull) => pull.state == 'OPEN')) return 'has an open pull request';
    final merged = own.any(
      (pull) => pull.state == 'MERGED' && pull.base == _trunk && pull.headCommit == tip,
    );
    return merged ? null : 'no merged pull request for this exact commit';
  }

  Future<void> _requireClean() async {
    final status = await _git(['status', '--porcelain', '--untracked-files=no']);
    if (status.trim().isNotEmpty) {
      throw StateError('There are uncommitted changes. Commit or stash them first:\n$status');
    }
  }

  Future<String> _git(List<String> args) async {
    final result = await run('git', args, workingDirectory: workspace);
    if (!result.ok) throw StateError('git ${args.join(' ')} failed: ${result.stderr.trim()}');
    return result.stdout;
  }

  /// Local branch name to its last commit.
  Future<Map<String, String>> _localBranches() async {
    final output = await _git(['for-each-ref', '--format=%(refname:short) %(objectname)', 'refs/heads']);
    return {
      for (final line in output.split('\n'))
        if (line.trim().split(' ') case [final name, final commit]) name: commit,
    };
  }

  /// Branches checked out in a worktree (the main one included).
  Future<Set<String>> _worktreeBranches() async {
    final output = await _git(['worktree', 'list', '--porcelain']);
    const prefix = 'branch refs/heads/';
    return {
      for (final line in output.split('\n'))
        if (line.startsWith(prefix)) line.substring(prefix.length).trim(),
    };
  }

  /// Every pull request of the repo, or `null` when GitHub cannot be read.
  Future<List<_PullRequest>?> _pullRequests() async {
    final result = await run(
      'gh',
      ['pr', 'list', '--state', 'all', '--limit', '1000', '--json', 'headRefName,headRefOid,baseRefName,state'],
      workingDirectory: workspace,
    );
    if (!result.ok) return null;
    try {
      if (jsonDecode(result.stdout) case final List<Object?> items) {
        return [
          for (final item in items)
            if (item
                case {
                  'headRefName': final String branch,
                  'headRefOid': final String headCommit,
                  'baseRefName': final String base,
                  'state': final String state,
                })
              _PullRequest(branch: branch, headCommit: headCommit, base: base, state: state),
        ];
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}

class _PullRequest {
  final String branch;
  final String headCommit;
  final String base;
  final String state;

  const _PullRequest({
    required this.branch,
    required this.headCommit,
    required this.base,
    required this.state,
  });
}
