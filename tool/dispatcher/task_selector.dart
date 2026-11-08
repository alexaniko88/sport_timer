import 'extensions/touch_paths.dart';
import 'task.dart';

/// Chooses which task can start next, from the rules in
/// `.agents/rules/project-tasks-format.md` ("State is deduced").
class TaskSelector {
  final List<Task> tasks;
  final Set<String> busyIds;

  const TaskSelector({required this.tasks, this.busyIds = const {}});

  /// The ids of tasks that already have a branch on the remote or an open PR.
  static Set<String> busyIdsFromBranches({
    required List<Task> tasks,
    required Iterable<String> branches,
  }) {
    return {
      for (final task in tasks)
        if (branches.any((branch) => branch.startsWith('${task.type}/${task.id.toLowerCase()}-'))) task.id,
    };
  }

  Set<String> get _doneIds => {
        for (final task in tasks)
          if (task.isDone) task.id,
      };

  /// Why `launch` must refuse [task] because of its executor, or null.
  static String? launchRefusal(Task task) {
    if (task.executorBlockReason case final reason?) return '${task.id}: $reason';
    return null;
  }

  /// Why [task] cannot start now, or null when it can.
  String? blockReason(Task task, {Set<String> skipped = const {}}) {
    if (task.isDone) return 'already done';
    if (task.status != 'ready') return 'status is ${task.status}';
    if (task.executorBlockReason case final reason?) return reason;
    if (skipped.contains(task.id)) return 'skipped';
    if (busyIds.contains(task.id)) return 'already has a branch or an open PR';

    final known = {for (final other in tasks) other.id};
    final missing = task.dependsOn.where((id) => !known.contains(id)).toList();
    if (missing.isNotEmpty) return 'depends on unknown ${missing.join(', ')}';

    final waiting = task.dependsOn.where((id) => !_doneIds.contains(id)).toList();
    if (waiting.isNotEmpty) return 'waits for ${waiting.join(', ')}';

    for (final other in tasks) {
      if (other.id != task.id && busyIds.contains(other.id) && task.touches.overlaps(other.touches)) {
        return 'overlaps with running ${other.id}';
      }
    }
    return null;
  }

  /// Tasks that can start now, in path order.
  List<Task> candidates({Set<String> skipped = const {}}) {
    return tasks.where((task) => blockReason(task, skipped: skipped) == null).toList();
  }

  /// The first task that can start now, or null.
  Task? next({Set<String> skipped = const {}}) {
    final all = candidates(skipped: skipped);
    return all.isEmpty ? null : all.first;
  }
}
