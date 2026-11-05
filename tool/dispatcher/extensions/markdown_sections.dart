/// Reads parts of a Markdown document by its headings.
extension MarkdownSections on String {
  /// The text under `## <title>`, up to the next `## ` heading, trimmed.
  String section(String title) {
    final lines = split('\n');
    final start = lines.indexWhere((line) => line.trimRight() == '## $title');
    if (start < 0) return '';
    final end = lines.indexWhere((line) => line.startsWith('## '), start + 1);
    return lines.sublist(start + 1, end < 0 ? lines.length : end).join('\n').trim();
  }

  /// The text of the first `# ` heading, or an empty string.
  String get firstHeading {
    final match = RegExp(r'^# (.+)$', multiLine: true).firstMatch(this);
    return (match?.group(1) ?? '').trim();
  }
}
