// Runs only the checks that apply to the files changed against the base branch.
//
//   fvm dart tool/agent_check.dart                  changed files vs master
//   fvm dart tool/agent_check.dart --base=main      another base branch
//   fvm dart tool/agent_check.dart --skip-build     skip the slow debug builds
//   fvm dart tool/agent_check.dart lib/a.dart ...   only these files
//
// The path-to-check rules live in [ChangeSet] and the diff parsing in
// [DiffReader], so both are unit tested without running any command.
import 'dart:io';

typedef FileExists = bool Function(String path);

bool _fileExists(String path) => File(path).existsSync();

/// The home folder marker is built from parts so this file does not match its own scan.
final String homePathMarker = ['', 'Users', ''].join('/');

/// Pieces are joined so this file does not list itself as an open note.
final RegExp openNotePattern = RegExp('\\b(?:TO' 'DO|FIX' 'ME)\\b');

/// One command run through `fvm`.
class CheckCommand {
  final String label;
  final List<String> args;

  const CheckCommand({required this.label, required this.args});

  @override
  String toString() => 'fvm ${args.join(' ')}';
}

/// The changed files and the checks they require.
class ChangeSet {
  final List<String> files;
  final FileExists exists;

  ChangeSet(Iterable<String> files, {this.exists = _fileExists})
      : files = (files
            .map((file) => file.trim().replaceAll('\\', '/').replaceFirst(RegExp(r'^\./'), ''))
            .where((file) => file.isNotEmpty)
            .toSet()
            .toList()
          ..sort());

  /// Dart files that exist and are written by hand (not generated).
  List<String> get dartFiles {
    return files.where((file) {
      if (!file.endsWith('.dart') || !exists(file)) return false;
      if (file.startsWith('lib/l10n/') || file == 'lib/firebase_options.dart') return false;
      return ['lib/', 'test/', 'tool/', 'integration_test/'].any(file.startsWith);
    }).toList();
  }

  bool get arbChanged => files.any((file) => file.endsWith('.arb'));

  bool get needsAndroidBuild => files.any((file) => file.startsWith('android/') || file == 'pubspec.yaml');

  bool get needsIosBuild => files.any((file) => file.startsWith('ios/'));

  /// Test files to run, in sorted order.
  List<String> get testFiles {
    final tests = <String>{};
    final libFiles = dartFiles.where((file) => file.startsWith('lib/')).toList();

    for (final file in dartFiles) {
      if (file.startsWith('test/') && file.endsWith('_test.dart')) {
        tests.add(file);
      } else if (file.startsWith('lib/')) {
        tests.add('test/${file.substring('lib/'.length).replaceFirst(RegExp(r'\.dart$'), '_test.dart')}');
      } else if (file.startsWith('tool/')) {
        tests.add('test/${file.replaceFirst(RegExp(r'\.dart$'), '_test.dart')}');
      }
    }
    if (libFiles.isNotEmpty) tests.add('test/architecture/layer_boundaries_test.dart');
    if (files.any(_changesScreens)) tests.add('test/snapshots/ui_snapshots_test.dart');
    if (files.any(_changesAiSetup)) tests.add('test/architecture/ai_setup_test.dart');

    return tests.where(exists).toList()..sort();
  }

  bool _changesScreens(String file) {
    final isPresentation = file.startsWith('lib/') && file.contains('/presentation/');
    return isPresentation || file == 'lib/navigation.dart' || file.endsWith('.arb');
  }

  bool _changesAiSetup(String file) {
    return file == 'CLAUDE.md' || ['.agents/', '.claude/', '.codex/'].any(file.startsWith);
  }

  /// The commands to run, in order.
  List<CheckCommand> plan({bool skipBuild = false}) {
    final dart = dartFiles;
    final tests = testFiles;
    return [
      if (arbChanged) const CheckCommand(label: 'Generate localizations', args: ['flutter', 'gen-l10n']),
      if (dart.isNotEmpty) ...[
        CheckCommand(
          label: 'Format (check only)',
          args: ['dart', 'format', '--output=none', '--set-exit-if-changed', ...dart],
        ),
        CheckCommand(label: 'Analyze changed files', args: ['flutter', 'analyze', ...dart]),
      ],
      if (tests.isNotEmpty) CheckCommand(label: 'Tests', args: ['flutter', 'test', ...tests]),
      if (!skipBuild && needsAndroidBuild)
        const CheckCommand(label: 'Android debug build', args: ['flutter', 'build', 'apk', '--debug']),
      if (!skipBuild && needsIosBuild)
        const CheckCommand(label: 'iOS debug build', args: ['flutter', 'build', 'ios', '--debug', '--no-codesign']),
    ];
  }
}

/// A line added by the change.
class AddedLine {
  final String file;
  final int line;
  final String text;

  const AddedLine({
    required this.file,
    required this.line,
    required this.text,
  });
}

/// Reads the lines a change adds.
class DiffReader {
  static final RegExp _hunk = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@');

  /// Added lines of a unified diff, with their line numbers in the new file.
  static List<AddedLine> fromDiff(String diff) {
    final added = <AddedLine>[];
    String? file;
    var inHunk = false;
    var line = 0;

    for (final text in diff.split('\n')) {
      if (text.startsWith('diff --git ')) {
        inHunk = false;
        file = null;
      } else if (!inHunk && text.startsWith('+++ ')) {
        // Git adds a tab after a path that contains spaces.
        final path = text.substring(4).split('\t').first;
        file = path.startsWith('b/') ? path.substring(2) : null;
      } else if (_hunk.firstMatch(text) case final match?) {
        inHunk = true;
        line = int.tryParse(match.group(1) ?? '') ?? 0;
      } else if (inHunk && file != null) {
        if (text.startsWith('+')) {
          added.add(
            AddedLine(
              file: file,
              line: line,
              text: text.substring(1),
            ),
          );
          line++;
        } else if (text.startsWith(' ')) {
          line++;
        }
      }
    }
    return added;
  }

  /// Every line of a new file counts as added.
  static List<AddedLine> fromNewFile(String file, String content) {
    final lines = content.split('\n');
    return [
      for (var index = 0; index < lines.length; index++)
        AddedLine(
          file: file,
          line: index + 1,
          text: lines[index],
        ),
    ];
  }

  /// Reads a file from disk. A file that is not readable text (an image, a
  /// font, a link to a folder) has no lines to scan, so it gives an empty list.
  static List<AddedLine> fromPath(String file) {
    try {
      return fromNewFile(file, File(file).readAsStringSync());
    } on FileSystemException {
      return [];
    } on FormatException {
      return [];
    }
  }
}

/// Runs git and returns its output.
class Git {
  /// Runs git with `core.quotepath=false`, so paths with non-ASCII characters
  /// come back as plain text instead of quoted octal escapes.
  static Future<String> run(List<String> args) async {
    final result = await Process.run('git', ['-c', 'core.quotepath=false', ...args]);
    if (result.exitCode != 0) {
      throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
    }
    return result.stdout as String;
  }

  static Future<List<String>> lines(List<String> args) async {
    return (await run(args)).split('\n').where((line) => line.isNotEmpty).toList();
  }
}

Future<void> main(List<String> args) async {
  var base = 'master';
  var skipBuild = false;
  final explicit = <String>[];
  for (final arg in args) {
    if (arg == '--skip-build') {
      skipBuild = true;
    } else if (arg.startsWith('--base=')) {
      base = arg.substring('--base='.length);
    } else {
      explicit.add(arg);
    }
  }

  final List<String> changed;
  final List<AddedLine> added;
  if (explicit.isNotEmpty) {
    changed = explicit;
    added = [
      for (final file in explicit) ...DiffReader.fromPath(file),
    ];
  } else {
    try {
      // Git prints some paths relative to the folder it runs in, so work from the repo root.
      Directory.current = (await Git.run(['rev-parse', '--show-toplevel'])).trim();
      final mergeBase = (await Git.run(['merge-base', 'HEAD', base])).trim();
      final untracked = await Git.lines(['ls-files', '--others', '--exclude-standard']);
      changed = [
        ...await Git.lines(['diff', '--name-only', mergeBase]),
        ...untracked,
      ];
      added = [
        ...DiffReader.fromDiff(await Git.run(['diff', '--unified=0', mergeBase])),
        for (final file in untracked) ...DiffReader.fromPath(file),
      ];
    } on StateError catch (error) {
      stderr.writeln('Cannot compare with "$base": ${error.message}');
      exit(2);
    }
  }

  final changeSet = ChangeSet(changed);
  if (changeSet.files.isEmpty) {
    stdout.writeln('No changed files. Nothing to check.');
    return;
  }

  final failures = <String>[];
  for (final command in changeSet.plan(skipBuild: skipBuild)) {
    stdout.writeln('\n▶ ${command.label}: $command');
    final process = await Process.start(
      'fvm',
      command.args,
      mode: ProcessStartMode.inheritStdio,
    );
    if (await process.exitCode != 0) failures.add(command.label);
  }

  stdout.writeln('\n▶ Added lines');
  final homePaths = added.where((line) => line.text.contains(homePathMarker)).toList();
  for (final line in homePaths) {
    stdout.writeln('  local path (or a URL path that contains it): ${line.file}:${line.line}');
  }
  if (homePaths.isNotEmpty) failures.add('Local absolute path in the diff');

  final openNotes = added.where((line) => openNotePattern.hasMatch(line.text));
  for (final line in openNotes) {
    stdout.writeln('  open note: ${line.file}:${line.line}  ${line.text.trim()}');
  }
  if (homePaths.isEmpty && openNotes.isEmpty) stdout.writeln('  none');

  if (failures.isEmpty) {
    stdout.writeln('\nAll checks passed.');
  } else {
    stdout.writeln('\nFailed: ${failures.join(', ')}');
    exitCode = 1;
  }
}
