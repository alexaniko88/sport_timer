import 'review_gate.dart';
import 'stage_report.dart';
import 'task.dart';

/// A golden image that changed in the branch.
class GoldenChange {
  final String path;

  /// False for a new image: there is nothing to show as "before".
  final bool existedBefore;

  const GoldenChange({required this.path, required this.existedBefore});
}

/// Builds the PR description from the stage reports. It carries no attribution
/// line, as `.agents/rules/git-commits.md` asks.
class PrDescription {
  /// [baseSha] and [headSha] pin the image links, so they never change.
  static String build({
    required Task task,
    required StageReport implementer,
    required StageReport tests,
    required List<ReviewFinding> reviewNotes,
    required List<GoldenChange> goldens,
    required String slug,
    required String baseSha,
    required String headSha,
    required String checkResult,
    required String taskPath,
    List<String> deniedCommands = const [],
  }) {
    final blob = 'https://github.com/$slug/blob';
    final lines = <String>[
      '## Summary',
      '',
      implementer.summary.isEmpty ? task.title : implementer.summary,
      '',
      'Task: [${task.id}]($blob/$headSha/$taskPath)',
      '',
      '## Acceptance',
      '',
      ...task.acceptance.map((line) => line.replaceFirst('- [ ]', '- [x]')),
      if (tests.evidence.isNotEmpty) ...['', tests.evidence],
    ];

    if (goldens.isNotEmpty) {
      lines.addAll([
        '',
        '## Visual changes',
        '',
        '| Screen | Before | After |',
        '| --- | --- | --- |',
        for (final golden in goldens)
          '| ${golden.path.split('/').last} | '
              '${golden.existedBefore ? '![before]($blob/$baseSha/${golden.path}?raw=true)' : 'new'} | '
              '![after]($blob/$headSha/${golden.path}?raw=true) |',
      ]);
    }

    lines.addAll(['', '## Checks', '', checkResult]);

    final notes = [
      for (final finding in reviewNotes) '- ${finding.location}: ${finding.summary}',
      if (implementer.openNotes.isNotEmpty) implementer.openNotes,
      if (tests.openNotes.isNotEmpty) tests.openNotes,
    ];
    if (notes.isNotEmpty) lines.addAll(['', '## Points to review', '', ...notes]);

    if (deniedCommands.isNotEmpty) {
      lines.addAll([
        '',
        '## Commands denied',
        '',
        'The tool was not allowed to run these. Check that nothing important was skipped.',
        '',
        ...deniedCommands.map((command) => '- `$command`'),
      ]);
    }

    return '${lines.join('\n')}\n';
  }
}
