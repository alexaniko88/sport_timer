import 'dart:io';

import 'command_runner.dart';
import 'extensions/posix_path.dart';
import 'task.dart';

/// Closes a task in its own branch: marks it done, writes its notes and moves
/// its folder into the `done/` folder of its parent, fixing every link.
class TaskArchiver {
  final String workspace;
  final RunCommand run;

  const TaskArchiver({required this.workspace, required this.run});

  static final _link = RegExp(r'\]\(([^)\s]+)\)');

  /// Returns the new folder of the task, relative to the workspace.
  Future<String> archive(Task task, {required String notes}) async {
    final oldDirectory = task.directory;
    final parent = oldDirectory.substring(0, oldDirectory.lastIndexOf('/'));
    final newDirectory = '$parent/done/${oldDirectory.split('/').last}';
    if (Directory('$workspace/$newDirectory').existsSync()) {
      throw StateError('$newDirectory already exists.');
    }
    Directory('$workspace/$parent/done').createSync(recursive: true);
    final moved = await run('git', ['mv', oldDirectory, newDirectory], workingDirectory: workspace);
    if (!moved.ok) throw StateError('git mv failed: ${moved.stderr}');

    final index = File('$workspace/$newDirectory/index.md');
    final text = _markDone(index.readAsStringSync());
    index.writeAsStringSync(
      _rewriteLinks(
        text,
        oldBase: oldDirectory,
        newBase: newDirectory,
        oldDirectory: oldDirectory,
        newDirectory: newDirectory,
      ),
    );

    final notesFile = File('$workspace/$newDirectory/notes.md');
    final existing = notesFile.existsSync() ? '${notesFile.readAsStringSync().trimRight()}\n\n' : '# Notes\n\n';
    notesFile.writeAsStringSync('$existing${notes.trim()}\n');

    _fixLinksInOtherFiles(oldDirectory: oldDirectory, newDirectory: newDirectory);
    return newDirectory;
  }

  String _markDone(String text) {
    final withStatus = text.replaceFirst(RegExp(r'^status:.*$', multiLine: true), 'status: done');
    final start = withStatus.indexOf('\n## Acceptance');
    if (start < 0) return withStatus;
    final end = withStatus.indexOf('\n## ', start + 1);
    final section = withStatus.substring(start, end < 0 ? withStatus.length : end);
    final checked = section.replaceAll(RegExp(r'^- \[ \]', multiLine: true), '- [x]');
    return withStatus.replaceRange(start, start + section.length, checked);
  }

  void _fixLinksInOtherFiles({required String oldDirectory, required String newDirectory}) {
    final root = Directory('$workspace/project-tasks');
    if (!root.existsSync()) return;
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      final relative = entity.path.substring(workspace.length + 1);
      if (relative.startsWith('$newDirectory/')) continue;
      final base = relative.substring(0, relative.lastIndexOf('/'));
      final before = entity.readAsStringSync();
      final after =
          _rewriteLinks(before, oldBase: base, newBase: base, oldDirectory: oldDirectory, newDirectory: newDirectory);
      if (after != before) entity.writeAsStringSync(after);
    }
  }

  /// Rewrites each relative link of [text]. A link into [oldDirectory] now
  /// points into [newDirectory]; every link is written relative to [newBase].
  String _rewriteLinks(
    String text, {
    required String oldBase,
    required String newBase,
    required String oldDirectory,
    required String newDirectory,
  }) {
    return text.replaceAllMapped(_link, (match) {
      final target = match.group(1) ?? '';
      if (RegExp(r'^[a-z][a-z0-9+.-]*:').hasMatch(target) || target.startsWith('#') || target.startsWith('/')) {
        return match.group(0) ?? '';
      }
      final anchorAt = target.indexOf('#');
      final path = anchorAt < 0 ? target : target.substring(0, anchorAt);
      final anchor = anchorAt < 0 ? '' : target.substring(anchorAt);
      if (path.isEmpty) return match.group(0) ?? '';
      final resolved = path.resolveFrom(oldBase);
      final mapped = resolved == oldDirectory || resolved.startsWith('$oldDirectory/')
          ? newDirectory + resolved.substring(oldDirectory.length)
          : resolved;
      return '](${mapped.relativeTo(newBase)}$anchor)';
    });
  }
}
