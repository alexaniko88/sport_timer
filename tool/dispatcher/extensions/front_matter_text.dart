/// Reads the `---` front matter block at the top of a Markdown file.
///
/// A scalar becomes a [String]. An inline list (`[a, b]`) or a block list
/// (`- a` lines under the key) becomes a `List<String>`.
extension FrontMatterText on String {
  Map<String, Object> get frontMatter {
    final lines = split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') return {};

    final values = <String, Object>{};
    List<String>? openList;
    for (final line in lines.skip(1)) {
      if (line.trim() == '---') break;
      if (openList != null) {
        if (RegExp(r'^\s*-\s+(.*)$').firstMatch(line) case final item?) {
          openList.add((item.group(1) ?? '')._uncommented._unquoted);
          continue;
        }
      }
      final entry = RegExp(r'^([A-Za-z][\w-]*):(.*)$').firstMatch(line);
      if (entry == null) continue;
      final key = entry.group(1) ?? '';
      final value = (entry.group(2) ?? '')._uncommented;
      openList = null;
      if (value.isEmpty) {
        final list = <String>[];
        values[key] = list;
        openList = list;
      } else if (value.startsWith('[') && value.endsWith(']')) {
        values[key] = value
            .substring(1, value.length - 1)
            .split(',')
            .map((item) => item._unquoted)
            .where((item) => item.isNotEmpty)
            .toList();
      } else {
        values[key] = value._unquoted;
      }
    }
    return values;
  }

  String get _uncommented => trim().replaceFirst(RegExp(r'(^|\s)#.*$'), '').trim();

  String get _unquoted {
    final text = trim();
    final isQuoted =
        text.length >= 2 && (text.startsWith('"') && text.endsWith('"') || text.startsWith("'") && text.endsWith("'"));
    return isQuoted ? text.substring(1, text.length - 1) : text;
  }
}
