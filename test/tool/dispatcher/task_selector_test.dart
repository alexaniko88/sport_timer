// Checks how tasks are read and which one can start next.
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/dispatcher/task.dart';
import '../../../tool/dispatcher/task_loader.dart';
import '../../../tool/dispatcher/task_selector.dart';

String _task({
  required String id,
  String status = 'ready',
  String dependsOn = '[]',
  String touches = '[lib/a/**]',
  String title = 'Do it',
  String type = 'feat',
  String? executor,
}) {
  final executorLine = executor == null ? '' : 'executor: $executor\n';
  return '---\nid: $id\nstatus: $status\ntype: $type\ndepends-on: $dependsOn\ntouches: $touches\n$executorLine---\n\n# $title\n';
}

Future<List<Task>> _load(Map<String, String> files) => TaskLoader(() async => files).load();

void main() {
  group('Task', () {
    test('reads the front matter and builds the branch name', () {
      final task = Task.tryParse(
        path: 'project-tasks/templates/stories/03-own/02-store-custom/index.md',
        text: _task(id: 'TPL-03-02', dependsOn: '[TPL-03-01]'),
      );

      expect(task?.id, 'TPL-03-02');
      expect(task?.dependsOn, ['TPL-03-01']);
      expect(task?.branch, 'feat/tpl-03-02-store-custom');
      expect(task?.isDone, isFalse);
    });

    test('a scalar depends-on is a one-item list, and unindented block items are read', () {
      final task = Task.tryParse(
        path: 'project-tasks/x/stories/01-s/01-t/index.md',
        text: '---\nid: X-01-01\ndepends-on: TPL-01-01\ntouches:\n- lib/a.dart\n---\n\n# T\n',
      );

      expect(task?.dependsOn, ['TPL-01-01']);
      expect(task?.touches, ['lib/a.dart']);
    });

    test('an epic or story index without an id is not a task', () {
      expect(Task.tryParse(path: 'project-tasks/x/index.md', text: '---\nabbr: X\n---\n# Epic\n'), isNull);
    });

    test('a task under done/ is done', () {
      final task = Task.tryParse(path: 'project-tasks/x/stories/01-s/done/01-t/index.md', text: _task(id: 'X-01-01'));

      expect(task?.isDone, isTrue);
    });
  });

  group('TaskLoader', () {
    test('keeps only tasks and sorts them by path', () async {
      final tasks = await _load({
        'project-tasks/b/stories/01-s/01-t/index.md': _task(id: 'B-01-01'),
        'project-tasks/a/index.md': '---\nabbr: A\n---\n# Epic\n',
        'project-tasks/a/stories/01-s/01-t/index.md': _task(id: 'A-01-01'),
      });

      expect(tasks.map((task) => task.id), ['A-01-01', 'B-01-01']);
    });
  });

  group('TaskSelector', () {
    const root = 'project-tasks/e/stories/01-s';

    test('a draft task is never offered', () async {
      final tasks = await _load({'$root/01-a/index.md': _task(id: 'E-01-01', status: 'draft')});

      expect(TaskSelector(tasks: tasks).next(), isNull);
    });

    test('waits for a dependency until it is in done/', () async {
      final files = {
        '$root/01-a/index.md': _task(id: 'E-01-01'),
        '$root/02-b/index.md': _task(id: 'E-01-02', dependsOn: '[E-01-01]', touches: '[lib/b/**]'),
      };
      var selector = TaskSelector(tasks: await _load(files));

      expect(selector.candidates().map((task) => task.id), ['E-01-01']);
      expect(selector.blockReason(selector.tasks[1]), 'waits for E-01-01');

      files['$root/done/01-a/index.md'] = _task(id: 'E-01-01', status: 'done');
      files.remove('$root/01-a/index.md');
      selector = TaskSelector(tasks: await _load(files));

      expect(selector.next()?.id, 'E-01-02');
    });

    test('a task that overlaps a running task waits', () async {
      final tasks = await _load({
        '$root/01-a/index.md': _task(id: 'E-01-01', touches: '[lib/a/**]'),
        '$root/02-b/index.md': _task(id: 'E-01-02', touches: '[lib/a/x.dart]'),
        '$root/03-c/index.md': _task(id: 'E-01-03', touches: '[lib/c/**]'),
      });
      final selector = TaskSelector(tasks: tasks, busyIds: {'E-01-01'});

      expect(selector.candidates().map((task) => task.id), ['E-01-03']);
      expect(selector.blockReason(tasks[1]), 'overlaps with running E-01-01');
    });

    test('a task with a branch or an open PR is busy', () async {
      final tasks = await _load({'$root/01-a/index.md': _task(id: 'E-01-01')});
      final busy = TaskSelector.busyIdsFromBranches(tasks: tasks, branches: ['feat/e-01-01-a', 'fix/other']);

      expect(busy, {'E-01-01'});
      expect(TaskSelector(tasks: tasks, busyIds: busy).next(), isNull);
    });

    test('a task without an executor is legacy and can start', () async {
      final tasks = await _load({'$root/01-a/index.md': _task(id: 'E-01-01')});

      expect(tasks.single.executor, 'legacy');
      expect(tasks.single.executorBlockReason, isNull);
      expect(TaskSelector(tasks: tasks).candidates().map((task) => task.id), ['E-01-01']);
    });

    test('an explicit legacy executor can start', () async {
      final tasks = await _load({'$root/01-a/index.md': _task(id: 'E-01-01', executor: 'legacy')});

      expect(TaskSelector(tasks: tasks).candidates().map((task) => task.id), ['E-01-01']);
    });

    final unsupported = {
      'orchestrator': 'orchestrator',
      'plan-dispatcher-v1': 'plan-dispatcher-v1',
      'handoff': 'handoff',
      'Legacy': 'Legacy',
      'foo': 'foo',
      '': '(empty)',
      '""': '(empty)',
      '[a]': '(empty)',
    };
    for (final entry in unsupported.entries) {
      test('executor "${entry.key}" is refused as ${entry.value}', () async {
        final tasks = await _load({'$root/01-a/index.md': _task(id: 'E-01-01', executor: entry.key)});
        final selector = TaskSelector(tasks: tasks);

        expect(selector.blockReason(tasks.single), 'executor ${entry.value} is not supported by the legacy dispatcher');
        expect(selector.candidates(), isEmpty);
      });
    }

    test('a draft task reports its status before its executor', () async {
      final tasks = await _load({
        '$root/01-a/index.md': _task(id: 'E-01-01', status: 'draft', executor: 'orchestrator'),
      });

      expect(TaskSelector(tasks: tasks).blockReason(tasks.single), 'status is draft');
    });

    test('launchRefusal is null for legacy and explains a non-legacy executor', () async {
      final tasks = await _load({
        '$root/01-a/index.md': _task(id: 'PLD-01-01'),
        '$root/02-b/index.md': _task(id: 'PLD-01-02', executor: 'orchestrator'),
      });

      expect(TaskSelector.launchRefusal(tasks[0]), isNull);
      expect(
        TaskSelector.launchRefusal(tasks[1]),
        'PLD-01-02: executor orchestrator is not supported by the legacy dispatcher',
      );
    });

    test('canonical task branches mark epic and standalone tasks busy', () async {
      final tasks = await _load({
        'project-tasks/e/stories/01-s/02-bootstrap-python-package/index.md': _task(
          id: 'PLD-01-02',
          executor: 'orchestrator',
        ),
        'project-tasks/bugs/01-crash/index.md': _task(id: 'BUG-01', type: 'fix'),
      });
      final epicTask = tasks.firstWhere((task) => task.id == 'PLD-01-02');
      final bug = tasks.firstWhere((task) => task.id == 'BUG-01');

      expect(epicTask.branch, 'feat/pld-01-02-bootstrap-python-package');
      expect(bug.branch, 'fix/bug-01-crash');
      expect(TaskSelector.busyIdsFromBranches(tasks: tasks, branches: [epicTask.branch, bug.branch]), {
        'PLD-01-02',
        'BUG-01',
      });
    });

    test('a skipped task is not offered', () async {
      final tasks = await _load({
        '$root/01-a/index.md': _task(id: 'E-01-01'),
        '$root/02-b/index.md': _task(id: 'E-01-02', touches: '[lib/b/**]'),
      });

      expect(TaskSelector(tasks: tasks).next(skipped: {'E-01-01'})?.id, 'E-01-02');
    });
  });
}
