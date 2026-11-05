import 'dart:convert';

/// How serious a review finding is.
enum Severity {
  critical,
  general,
  minor,
}

/// One finding of the reviewer.
class ReviewFinding {
  final Severity severity;
  final String file;
  final int? line;
  final String summary;
  final String fix;

  const ReviewFinding({
    required this.severity,
    required this.file,
    required this.line,
    required this.summary,
    required this.fix,
  });

  String get location => line == null ? file : '$file:$line';
}

/// What to do after a review.
enum ReviewDecision {
  pass,
  fix,
  blocked,
}

/// Reads the reviewer's report and decides the next step. The reviewer ends its
/// message with a fenced `json` block: `{"findings": [{"severity", "file",
/// "line", "summary", "fix"}]}`.
class ReviewGate {
  static const maxRounds = 2;

  /// Null when the message has no readable JSON block: the review did not
  /// happen and must not count as passed.
  static List<ReviewFinding>? parse(String message) {
    // A `fix` text may hold its own code fence, and prose may follow the block,
    // so try each closing fence from the last one back until the JSON decodes.
    final start = message.lastIndexOf('```json');
    if (start < 0) return null;
    final from = start + '```json'.length;
    for (var end = message.lastIndexOf('```'); end >= from; end = message.lastIndexOf('```', end - 1)) {
      if (_decode(message.substring(from, end)) case final findings?) return findings;
    }
    return null;
  }

  static List<ReviewFinding>? _decode(String text) {
    try {
      if (jsonDecode(text) case {'findings': final List<Object?> entries}) {
        return [
          for (final entry in entries)
            if (entry case {'severity': final String severity, 'summary': final String summary})
              ReviewFinding(
                severity: Severity.values.asNameMap()[severity.toLowerCase()] ?? Severity.general,
                file: entry['file'] is String ? entry['file'] as String : '',
                line: entry['line'] is int ? entry['line'] as int : null,
                summary: summary,
                fix: entry['fix'] is String ? entry['fix'] as String : '',
              ),
        ];
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  /// [round] is 1 for the first review. Critical and general findings are
  /// fixed; after [maxRounds] reviews they block the task.
  static ReviewDecision decide({required int round, required List<ReviewFinding> findings}) {
    final mustFix = findings.any((finding) => finding.severity != Severity.minor);
    if (!mustFix) return ReviewDecision.pass;
    return round < maxRounds ? ReviewDecision.fix : ReviewDecision.blocked;
  }

  /// The findings that go to the PR as notes, not fixes.
  static List<ReviewFinding> notes(List<ReviewFinding> findings) {
    return findings.where((finding) => finding.severity == Severity.minor).toList();
  }
}
