import 'command_runner.dart';
import 'pr_description.dart';

/// The rules of `.agents/rules/git-commits.md` for a commit subject.
class CommitMessage {
  static final _pattern = RegExp(r'^(feat|fix|refactor|chore|docs|style|perf|test|build|wip): [a-z0-9`].*[^.]$');

  /// Why [subject] is not a valid first line, or null when it is.
  static String? problem(String subject) {
    if (subject.isEmpty) return 'The commit message is empty.';
    if (subject.length > 100) return 'The commit message is longer than 100 characters.';
    if (!_pattern.hasMatch(subject)) {
      return 'The commit message "$subject" must be "<type>: <description>", lowercase, with no final period.';
    }
    return null;
  }
}

/// Looks for private data in the lines a branch adds. The patterns are built
/// from parts so this file does not match its own scan.
class DiffScanner {
  static final Map<String, RegExp> _rules = {
    'a local home path': RegExp('/Us' 'ers/[A-Za-z]'),
    'a private key': RegExp('-----BEGIN [A-Z ]*PRIVATE ' 'KEY-----'),
    'a GitHub token': RegExp('gh[pousr]_[A-Za-z0-9]{30,}'),
    'a secret key': RegExp('sk-[A-Za-z0-9]{20,}'),
    'a company email': RegExp('@vent' 'rata\\.com'),
  };

  /// One text per finding: the file and what was found. [diff] is
  /// `git diff --unified=0` output.
  static List<String> scan(String diff) {
    final findings = <String>[];
    var file = '';
    for (final line in diff.split('\n')) {
      if (line.startsWith('+++ ')) {
        file = line.substring(4).replaceFirst(RegExp(r'^b/'), '');
        continue;
      }
      if (!line.startsWith('+')) continue;
      for (final MapEntry(:key, :value) in _rules.entries) {
        if (value.hasMatch(line)) findings.add('$file has $key');
      }
    }
    return findings;
  }
}

/// Every write to git and GitHub of a run. Only the script does them; the AI
/// tools run in a sandbox that cannot write to `.git`.
class GitPublisher {
  final String workspace;
  final RunCommand run;

  const GitPublisher({required this.workspace, required this.run});

  Future<CommandResult> _git(List<String> args) => run('git', args, workingDirectory: workspace);

  /// Stages everything and commits. Returns an error text, or null on success
  /// or when there was nothing to commit.
  Future<String?> commitAll({required String subject, required String trailer}) async {
    final add = await _git(['add', '-A']);
    if (!add.ok) return 'git add failed: ${add.stderr}';
    final status = await _git(['status', '--porcelain']);
    if (status.stdout.trim().isEmpty) return null;
    final commit = await _git(['commit', '-q', '-m', subject, '-m', trailer]);
    return commit.ok ? null : 'git commit failed: ${commit.stderr}';
  }

  Future<String> headSha() async => (await _git(['rev-parse', 'HEAD'])).stdout.trim();

  Future<String> baseSha() async => (await _git(['rev-parse', 'origin/master'])).stdout.trim();

  /// The lines the branch adds compared with `origin/master`.
  Future<String> addedLinesDiff() async => (await _git(['diff', 'origin/master', 'HEAD', '--unified=0'])).stdout;

  /// The golden images that were added or changed.
  Future<List<GoldenChange>> changedGoldens() async {
    final result = await _git(['diff', '--name-status', 'origin/master', 'HEAD', '--', 'test/snapshots/goldens']);
    final changes = <GoldenChange>[];
    for (final line in result.stdout.split('\n')) {
      final parts = line.split('\t');
      if (parts.length < 2 || !parts.last.endsWith('.png')) continue;
      if (parts.first == 'D') continue;
      changes.add(GoldenChange(path: parts.last, existedBefore: parts.first != 'A'));
    }
    return changes;
  }

  /// Pushes HEAD to [branch]. It never pushes to `master` or `main`.
  Future<String?> push(String branch) async {
    if (branch == 'master' || branch == 'main' || branch.isEmpty) return 'Refusing to push to "$branch".';
    final result = await _git(['push', 'origin', 'HEAD:refs/heads/$branch']);
    return result.ok ? null : 'git push failed: ${result.stderr}';
  }

  /// Opens the PR and returns its URL, or an error text starting with `error:`.
  Future<String> openPullRequest({
    required String branch,
    required String title,
    required String bodyFile,
  }) async {
    final result = await run(
      'gh',
      ['pr', 'create', '--base', 'master', '--head', branch, '--title', title, '--body-file', bodyFile],
      workingDirectory: workspace,
    );
    if (!result.ok) return 'error: ${result.stderr}';
    return result.stdout.trim().split('\n').last;
  }
}
