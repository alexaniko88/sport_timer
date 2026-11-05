/// Compares the `touches` lists of two tasks.
extension TouchPaths on List<String> {
  /// Whether this list and [other] can change the same file.
  ///
  /// The check is on purpose cautious: a glob counts as everything under the
  /// folder before its first wildcard. An empty list means "unknown", so it
  /// overlaps with every other list.
  bool overlaps(List<String> other) {
    if (isEmpty || other.isEmpty) return true;
    for (final mine in this) {
      for (final theirs in other) {
        if (_related(mine, theirs)) return true;
      }
    }
    return false;
  }

  static bool _related(String a, String b) {
    final first = _base(a);
    final second = _base(b);
    final shorter = first.length <= second.length ? first : second;
    final longer = identical(shorter, first) ? second : first;
    for (var index = 0; index < shorter.length; index++) {
      if (shorter[index] != longer[index]) return false;
    }
    return true;
  }

  static List<String> _base(String pattern) {
    final base = <String>[];
    for (final segment in pattern.split('/').where((segment) => segment.isNotEmpty)) {
      if (segment.contains('*')) break;
      base.add(segment);
    }
    return base;
  }
}
