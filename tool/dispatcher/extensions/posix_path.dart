/// Slash-separated path maths for repository paths.
extension PosixPath on String {
  /// The path without `.` and `..` segments and without empty segments.
  String get normalized {
    final stack = <String>[];
    for (final segment in split('/')) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment == '..') {
        if (stack.isNotEmpty) stack.removeLast();
        continue;
      }
      stack.add(segment);
    }
    return stack.join('/');
  }

  /// This relative path, resolved from [directory].
  String resolveFrom(String directory) => '$directory/$this'.normalized;

  /// This path written relative to [directory].
  String relativeTo(String directory) {
    final target = normalized.split('/').where((segment) => segment.isNotEmpty).toList();
    final base = directory.normalized.split('/').where((segment) => segment.isNotEmpty).toList();
    var common = 0;
    while (common < target.length && common < base.length && target[common] == base[common]) {
      common++;
    }
    final parts = [
      for (var index = common; index < base.length; index++) '..',
      ...target.skip(common),
    ];
    return parts.isEmpty ? '.' : parts.join('/');
  }
}
