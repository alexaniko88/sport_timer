import 'extensions/markdown_sections.dart';

/// The report an implementer or tests stage ends with. The role files ask for
/// these `##` sections in the final message.
class StageReport {
  final String commit;
  final String summary;
  final String evidence;
  final String openNotes;
  final String blocked;

  const StageReport({
    required this.commit,
    required this.summary,
    required this.evidence,
    required this.openNotes,
    required this.blocked,
  });

  factory StageReport.parse(String message) {
    final commitLine = message
        .section('Commit')
        .split('\n')
        .map((line) => line.trim().replaceAll('`', ''))
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    return StageReport(
      commit: commitLine,
      summary: message.section('Summary'),
      evidence: message.section('Evidence'),
      openNotes: message.section('Open notes'),
      blocked: message.section('Blocked'),
    );
  }

  /// Whether the stage stopped on a question it could not answer.
  bool get isBlocked {
    final text = blocked.trim().toLowerCase();
    return text.isNotEmpty && text != 'none' && text != 'none.';
  }
}
