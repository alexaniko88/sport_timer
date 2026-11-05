/// Reads command line arguments like `launch TPL-03-02 --tool=codex`.
extension CommandOptions on List<String> {
  /// The `--name=value` options. A flag without a value (`--name`) is `true`.
  Map<String, String> get options {
    final values = <String, String>{};
    for (final argument in this) {
      if (!argument.startsWith('--')) continue;
      final text = argument.substring(2);
      final at = text.indexOf('=');
      if (at < 0) {
        values[text] = 'true';
      } else {
        values[text.substring(0, at)] = text.substring(at + 1);
      }
    }
    return values;
  }

  /// The arguments that are not options.
  List<String> get positional => where((argument) => !argument.startsWith('--')).toList();
}
