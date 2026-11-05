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
}) {
  return '---\nid: $id\nstatus: $status\ntype: feat\ndepends-on: $dependsOn\ntouches: $touches\n---\n\n# $title\n';
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

    test('a skipped task is not offered', () async {
      final tasks = await _load({
        '$root/01-a/index.md': _task(id: 'E-01-01'),
        '$root/02-b/index.md': _task(id: 'E-01-02', touches: '[lib/b/**]'),
      });

      expect(TaskSelector(tasks: tasks).next(skipped: {'E-01-01'})?.id, 'E-01-02');
    });
  });
}
