import 'dart:io';

import 'command_runner.dart';
import 'task.dart';

/// Gives the text of every `index.md` under `project-tasks/`, keyed by its path.
typedef ReadIndexFiles = Future<Map<String, String>> Function();

/// Loads the tasks of `project-tasks/`.
class TaskLoader {
  final ReadIndexFiles read;

  const TaskLoader(this.read);

  /// Reads the files of a local folder, for example `project-tasks`.
  factory TaskLoader.fromDisk({String root = 'project-tasks'}) {
    return TaskLoader(() async {
      final files = <String, String>{};
      final folder = Directory(root);
      if (!folder.existsSync()) return files;
      for (final entity in folder.listSync(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('/index.md')) {
          files[entity.path] = entity.readAsStringSync();
        }
      }
      return files;
    });
  }

  /// Reads the files as they are on [ref] (for example `origin/master`), so a
  /// task that is only on another branch is never offered.
  factory TaskLoader.fromGit({
    required String ref,
    required RunCommand run,
    String root = 'project-tasks',
  }) {
    return TaskLoader(() async {
      final files = <String, String>{};
      final listing = await run('git', ['ls-tree', '-r', '--name-only', ref, root]);
      if (!listing.ok) return files;
      for (final path in listing.stdout.split('\n')) {
        if (!path.endsWith('/index.md')) continue;
        final content = await run('git', ['show', '$ref:$path']);
        if (content.ok) files[path] = content.stdout;
      }
      return files;
    });
  }

  /// Every task, sorted by path (epic, story, then task number).
  Future<List<Task>> load() async {
    final files = await read();
    final tasks = <Task>[];
    for (final MapEntry(:key, :value) in files.entries) {
      if (Task.tryParse(path: key, text: value) case final task?) tasks.add(task);
    }
    tasks.sort((a, b) => a.directory.compareTo(b.directory));
    return tasks;
  }
}
